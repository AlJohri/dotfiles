#!/bin/sh

# Claude Code status line.
# Reads the session JSON blob from stdin and renders a single dim line:
#   model: X | effort: Y | ctx: N% | 5h: N% (1h23m) | 7d: N% | dir: foo | git: main ~3 | myrepo#42 ◌
#
# Based on Roberto Trani's original, with:
#   - effort read from the live stdin field (.effort.level), not settings.json
#   - git state cached per-session (5s TTL) so we don't run git diff every render
#   - "active context" resolution: when the session cwd is a non-repo parent dir
#     (e.g. working from a projects root across many repos/worktrees), the most
#     recently active worktree is recovered from the transcript so git + PR still
#     show. See resolve-active-context below.
#   - a PR segment (clickable via OSC 8): Claude Code's own .pr field when cwd is
#     a repo, else a gh-backed lookup for the derived worktree (cached 120s).

# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------
input=$(cat)

# Persist the last input JSON for offline field discovery/debugging.
printf '%s\n' "$input" > "${TMPDIR:-/tmp}/claude-statusline-input.json" 2>/dev/null

model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
folder=$(echo "$current_dir" | awk -F'/' '{print $NF}')
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')

ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
rate_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rate_pct_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate_reset_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Claude Code's own PR fields (populated only when cwd is a git repo).
pr_number=$(echo "$input" | jq -r '.pr.number // empty')
pr_url=$(echo "$input" | jq -r '.pr.url // empty')
pr_state=$(echo "$input" | jq -r '.pr.review_state // empty')

# ---------------------------------------------------------------------------
# Color variables
# ---------------------------------------------------------------------------
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1;97m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET_DIM='\033[0;2m'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Print a human-readable countdown to a unix epoch timestamp.
# Prints nothing if the timestamp is missing or already past.
# Output format: "2d3h", "1h23m", or "45m".
countdown() {
  ts=$1
  [ -z "$ts" ] && return
  now=$(date +%s)
  delta=$(( ts - now ))
  [ "$delta" -le 0 ] && return
  days=$(( delta / 86400 ))
  hours=$(( (delta % 86400) / 3600 ))
  minutes=$(( (delta % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf '%dd%dh' "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%dm' "$hours" "$minutes"
  else
    printf '%dm' "$minutes"
  fi
}

# Print an ANSI-colored percentage value followed by "%" and a return to dim.
# Thresholds: 0–49 → green, 50–79 → yellow, 80+ → red.
color_pct() {
  val=$1
  if [ "$val" -ge 80 ]; then
    printf "${RED}%s%%${RESET_DIM}" "$val"
  elif [ "$val" -ge 50 ]; then
    printf "${YELLOW}%s%%${RESET_DIM}" "$val"
  else
    printf "${GREEN}%s%%${RESET_DIM}" "$val"
  fi
}

# Print a colored review-state glyph for a normalized token:
#   draft → ◌, approved → ✓, changes → ✗, anything else (pending) → ●
pr_glyph() {
  case "$1" in
    draft)    printf "${RESET_DIM}◌" ;;
    approved) printf "${GREEN}✓${RESET_DIM}" ;;
    changes)  printf "${RED}✗${RESET_DIM}" ;;
    "")       ;;
    *)        printf "${YELLOW}●${RESET_DIM}" ;;
  esac
}

# ---------------------------------------------------------------------------
# Resolve active git context
# ---------------------------------------------------------------------------
# ctx_dir  = worktree we're effectively working in
# ctx_repo = its repo folder name (for a repo#num PR label)
# derived  = 1 when recovered from the transcript (cwd is a non-repo parent)
ctx_dir=""
ctx_repo="$repo_name"
derived=0
if [ -n "$current_dir" ] && ( cd "$current_dir" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1 ); then
  ctx_dir="$current_dir"
elif [ -n "$current_dir" ] && [ -n "$transcript" ] && [ -f "$transcript" ]; then
  # Non-repo parent dir: find the most recent "<current_dir>/<repo>/<worktree>"
  # path from a Bash cwd or a file_path in the transcript tail.
  p=$(tail -n 400 "$transcript" 2>/dev/null \
      | grep -oE '"(cwd|file_path)":"'"$current_dir"'/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+' \
      | grep -oE "$current_dir/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+" \
      | tail -1)
  if [ -n "$p" ] && ( cd "$p" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1 ); then
    ctx_dir="$p"
    ctx_repo=$(basename "$(dirname "$p")")
    derived=1
  fi
fi

# ---------------------------------------------------------------------------
# Git state (cached per session+context, 5s TTL)
# ---------------------------------------------------------------------------
# git diff on a large repo is slow and the status line runs after every message,
# so cache branch|staged|modified. Keyed on session_id + a hash of ctx_dir so
# switching worktrees doesn't read a stale sibling's state.
GIT_BRANCH=""
GIT_STAGED=0
GIT_MODIFIED=0
if [ -n "$ctx_dir" ]; then
  dir_slug=$(printf '%s' "$ctx_dir" | cksum | cut -d' ' -f1)
  cache_file="${TMPDIR:-/tmp}/claude-statusline-git-${session_id:-x}-${dir_slug}"
  cache_stale=1
  if [ -f "$cache_file" ]; then
    mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    [ $(( $(date +%s) - mtime )) -le 5 ] && cache_stale=0
  fi
  if [ "$cache_stale" -eq 1 ]; then
    b=$(cd "$ctx_dir" && git branch --show-current 2>/dev/null)
    s=$(cd "$ctx_dir" && git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    m=$(cd "$ctx_dir" && git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    printf '%s|%s|%s\n' "$b" "$s" "$m" > "$cache_file"
  fi
  IFS='|' read -r GIT_BRANCH GIT_STAGED GIT_MODIFIED < "$cache_file"
  : "${GIT_STAGED:=0}" "${GIT_MODIFIED:=0}"
fi

# ---------------------------------------------------------------------------
# PR state
# ---------------------------------------------------------------------------
# In-repo session: Claude Code already gave us .pr — use it, no network.
# Derived (parent-dir) session: ask gh for the worktree's branch, cached 120s
# and timeout-guarded so a slow network never stalls the status line.
PR_NUM=""
PR_URL=""
PR_GLYPH_TOK=""
if [ -n "$pr_number" ]; then
  PR_NUM="$pr_number"
  PR_URL="$pr_url"
  PR_GLYPH_TOK=$(echo "$pr_state" | sed 's/changes_requested/changes/')
elif [ "$derived" -eq 1 ] && [ -n "$GIT_BRANCH" ]; then
  slug=$(printf '%s' "${ctx_repo}_${GIT_BRANCH}" | tr '/ .' '___')
  pr_cache="${TMPDIR:-/tmp}/claude-statusline-pr-${session_id:-x}-${slug}"
  pr_stale=1
  if [ -f "$pr_cache" ]; then
    mtime=$(stat -c %Y "$pr_cache" 2>/dev/null || echo 0)
    [ $(( $(date +%s) - mtime )) -le 120 ] && pr_stale=0
  fi
  if [ "$pr_stale" -eq 1 ]; then
    j=$(cd "$ctx_dir" && timeout 3 gh pr view "$GIT_BRANCH" \
          --json number,url,state,isDraft,reviewDecision 2>/dev/null)
    if [ -n "$j" ] && [ "$(printf '%s' "$j" | jq -r '.state')" = "OPEN" ]; then
      n=$(printf '%s' "$j" | jq -r '.number')
      u=$(printf '%s' "$j" | jq -r '.url')
      if [ "$(printf '%s' "$j" | jq -r '.isDraft')" = "true" ]; then
        g=draft
      else
        case "$(printf '%s' "$j" | jq -r '.reviewDecision')" in
          APPROVED)          g=approved ;;
          CHANGES_REQUESTED) g=changes ;;
          *)                 g=pending ;;
        esac
      fi
      printf '%s|%s|%s\n' "$n" "$u" "$g" > "$pr_cache"
    else
      printf '||\n' > "$pr_cache"   # negative-cache: no open PR
    fi
  fi
  IFS='|' read -r PR_NUM PR_URL PR_GLYPH_TOK < "$pr_cache"
fi

# ---------------------------------------------------------------------------
# Output composition
# ---------------------------------------------------------------------------

# Open with dim; everything is dim unless explicitly colored.
printf "${DIM}"

# Model name segment.
printf "${BOLD}model${RESET}${DIM}: %s" "$model"

# Effort segment (only when set).
if [ -n "$effort" ]; then
  printf " | ${BOLD}effort${RESET}${DIM}: %s" "$effort"
fi

# Context-window usage: ctx: XX%
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf '%.0f' "$ctx_pct")
  printf " | ${BOLD}ctx${RESET}${DIM}: "
  color_pct "$ctx_int"
fi

# 5-hour rate-limit usage: 5h: XX% (1h23m)
if [ -n "$rate_pct" ]; then
  rate_int=$(printf '%.0f' "$rate_pct")
  printf " | ${BOLD}5h${RESET}${DIM}: "
  color_pct "$rate_int"
  reset=$(countdown "$rate_reset")
  [ -n "$reset" ] && printf ' (%s)' "$reset"
fi

# 7-day rate-limit usage: 7d: XX% (2d3h)
if [ -n "$rate_pct_7d" ]; then
  rate_int_7d=$(printf '%.0f' "$rate_pct_7d")
  printf " | ${BOLD}7d${RESET}${DIM}: "
  color_pct "$rate_int_7d"
  reset_7d=$(countdown "$rate_reset_7d")
  [ -n "$reset_7d" ] && printf ' (%s)' "$reset_7d"
fi

# Directory: label bold, value cyan.
printf " | ${BOLD}dir${RESET}${DIM}: ${CYAN}%s${RESET}${DIM}" "$folder"

# Git segment: only when we resolved a branch (from cwd or the transcript).
if [ -n "$GIT_BRANCH" ]; then
  GIT_STATUS=""
  [ "$GIT_STAGED" -gt 0 ]   && GIT_STATUS="${GREEN}+${GIT_STAGED}${RESET}${DIM}"
  [ "$GIT_MODIFIED" -gt 0 ] && GIT_STATUS="${GIT_STATUS}${YELLOW}~${GIT_MODIFIED}${RESET}${DIM}"
  printf " | ${BOLD}git${RESET}${DIM}: ${CYAN}%s${RESET}${DIM}" "$GIT_BRANCH"
  [ -n "$GIT_STATUS" ] && printf ' %b' "$GIT_STATUS"
fi

# PR segment: "<repo>#<num>" (clickable), then a review-state glyph.
if [ -n "$PR_NUM" ]; then
  label="${ctx_repo:-PR}#${PR_NUM}"
  printf " | ${BOLD}"
  if [ -n "$PR_URL" ]; then
    # OSC 8 hyperlink: ESC ]8;;URL ST  TEXT  ESC ]8;; ST
    printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$PR_URL" "$label"
  else
    printf '%s' "$label"
  fi
  printf "${RESET}${DIM}"
  g=$(pr_glyph "$PR_GLYPH_TOK")
  [ -n "$g" ] && printf ' %b' "$g"
fi

printf "${RESET}"
