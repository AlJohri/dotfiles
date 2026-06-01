#!/usr/bin/env bash
set -euo pipefail

# Setup script for Command & Conquer: Red Alert 3 online play (C&C:Online / "Tacitus")
# on Linux via Steam + Proton. Run standalone; NOT wired into setup-omarchy.sh because
# it depends on you having bought + installed RA3 in Steam first (account-bound).
#
# Usage: ./setup-ra3-online.sh
#
# What this automates (all idempotent, safe to re-run):
#   1.  Drops the Tacitus dsound.dll into the RA3 Data/ dir.
#   1b. Enables Tacitus VerboseLog (game-side network logging for desync hunting).
#   1c. Installs native MSVC 2005/2008 runtimes via protontricks -- THE online desync fix
#       (Wine's post-5.15 musl libm diverges from Windows' CRT and breaks lockstep sync).
#   2.  Forces GE-Proton for the RA3 appid (config.vdf CompatToolMapping).
#   3.  Sets the dsound launch override for the RA3 appid (localconfig.vdf LaunchOptions).
#
# Optional extras (separate tool): the Community Patch v1.12.8 (extra maps + balance) is
# installed/toggled by the standalone `ra3-community-patch` script -- not done here.
#
# Why no wine / registry / symlink / installer (cf. the usual cnc-online.net guide):
#   "Tacitus" is not really an installed program -- for RA3 it is a single dsound.dll
#   that Wine/Proton loads from the game's exe directory; it hijacks the game's GameSpy
#   network calls and redirects them to the community server. The official NSIS installer
#   only does a Windows-registry lookup to find the game dir and then copies that one DLL.
#   So we extract the DLL straight from the installer payload and place it ourselves --
#   no `wine`, no `.reg` import, no ~/.wine symlink, no "launch once to build the prefix".
#
# What you STILL must do by hand (cannot be automated):
#   - Own + install "Command & Conquer Red Alert 3" in Steam.
#   - Have a C&C:Online account, and log in with it in-game under Multiplayer -> Online.

APPID=17480
# Internal compat-tool name Steam matches on in CompatToolMapping. This is the KEY inside
# the tool's compatibilitytool.vdf (compat_tools."<name>"), NOT the directory name under
# compatibilitytools.d nor the display name. The AUR `proton-ge-custom-bin` that omarchy's
# gaming install pulls in ships dir "proton-ge-custom" but registers the name "Proton-GE"
# (also what ProtonUp-Qt's GE builds use). Existence is asserted below.
COMPAT_TOOL="Proton-GE"
LAUNCH_OPTS='WINEDLLOVERRIDES="dsound=n,b" %command%'
TACITUS_URL="https://server.cnc-online.net/cnconline/Tacitus/CCO_TacitusInstaller_v1.exe"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ra3-online"

note() { printf '==> %s\n' "$*"; }
warn() { printf '    %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

for a in "$@"; do
    case "$a" in
        -h|--help) sed -n '4,28p' "$0"; exit 0 ;;
        *) die "unknown argument: $a (this script takes no options)" ;;
    esac
done

# --- locate the Steam root and the RA3 install -------------------------------------------

# Steam stores config under one root, but games can live in additional library folders.
STEAM_ROOT=""
for r in "$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root"; do
    if [ -f "$r/config/config.vdf" ]; then STEAM_ROOT="$r"; break; fi
done
[ -n "$STEAM_ROOT" ] || die "Steam not found (no config/config.vdf). Install + launch Steam once first."
note "Steam root: $STEAM_ROOT"

# Assert GE-Proton is actually registered before we map RA3 to it -- Steam silently
# ignores a CompatToolMapping pointing at a name it can't find (RA3 would fall back to
# default Proton). The name must appear in some compatibilitytool.vdf under one of the
# dirs Steam scans. Collect the dirs that exist (the per-root one often doesn't), then grep.
ct_dirs=()
for d in /usr/share/steam/compatibilitytools.d "$STEAM_ROOT/compatibilitytools.d"; do
    [ -d "$d" ] && ct_dirs+=("$d")
done
if ! grep -rqlF "\"$COMPAT_TOOL\"" "${ct_dirs[@]}" 2>/dev/null; then
    die "$COMPAT_TOOL not found in any compatibilitytools.d. Install GE-Proton (omarchy: it's the proton-ge-custom AUR package) and re-run."
fi

# Collect every library's steamapps/common dir: the root itself plus any extra libraries
# listed in libraryfolders.vdf (grep the "path" lines -- robust enough without a vdf parser).
mapfile -t LIB_PATHS < <(
    printf '%s\n' "$STEAM_ROOT"
    lf="$STEAM_ROOT/steamapps/libraryfolders.vdf"
    [ -f "$lf" ] && grep -oP '"path"\s*"\K[^"]+' "$lf"
)

RA3_DIR=""
for lib in "${LIB_PATHS[@]}"; do
    cand="$lib/steamapps/common/Command and Conquer Red Alert 3"
    if [ -d "$cand" ]; then RA3_DIR="$cand"; break; fi
done
[ -n "$RA3_DIR" ] || die "RA3 not installed. Buy + install 'Command & Conquer Red Alert 3' in Steam, then re-run."
note "RA3 install: $RA3_DIR"

# --- 1. extract + place the Tacitus dsound.dll -------------------------------------------

command -v 7z >/dev/null 2>&1 || die "7z not found. Install it: sudo pacman -S --needed 7zip"

mkdir -p "$CACHE_DIR"
installer="$CACHE_DIR/CCO_TacitusInstaller_v1.exe"
dll="$CACHE_DIR/dsound.dll"

if [ ! -f "$dll" ]; then
    if [ ! -f "$installer" ]; then
        note "Downloading Tacitus installer..."
        curl -fL --retry 3 -o "$installer" "$TACITUS_URL" \
            || die "download failed: $TACITUS_URL"
    fi
    note "Extracting RA3 dsound.dll from installer payload..."
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    # The installer is a flat NSIS archive. The DLL for each supported game sits at a
    # fixed path inside it; for RA3 the one and only target is "Red Alert 3/Data/dsound.dll"
    # (the other paths in the archive are for Kane's Wrath / Tiberium Wars).
    7z e -y -o"$tmp" "$installer" '$0/Red Alert 3/Data/dsound.dll' >/dev/null \
        || die "could not extract RA3 dsound.dll from installer (payload layout changed?)"
    [ -f "$tmp/dsound.dll" ] || die "dsound.dll not found in payload (payload layout changed?)"
    cp "$tmp/dsound.dll" "$dll"
    rm -rf "$tmp"; trap - EXIT
fi

# The installer places exactly one file for RA3: <game>/Data/dsound.dll, and that is the
# only correct location. RA3.exe at the game root is just a launcher; the real game
# binaries (ra3_1.12.exe retail, ra3ep1.exe Uprising) live in Data/, and Proton loads
# dsound.dll from the directory of the running executable -- so Data/ is where it must go.
# (The Windows installer's other payload paths are for Kane's Wrath / Tiberium Wars.)
dest="$RA3_DIR/Data/dsound.dll"
if [ -f "$dest" ] && cmp -s "$dll" "$dest"; then
    note "dsound.dll already current in Data/."
else
    cp "$dll" "$dest"
    note "Placed dsound.dll in: Data/"
fi

# --- 1b. enable Tacitus VerboseLog --------------------------------------------------------
# Tacitus only logs its GameSpy/P2P networking (peer punch, connection state, relay
# decisions) to Data/Tacitus.log when [DEBUG] VerboseLog = true; otherwise the log holds
# just the startup banner. We default it on so the NEXT failure (desync, dropped peer) has
# a useful log to read -- it's the best game-side network instrumentation we have. The edit
# is idempotent and line-wise so any other Tacitus settings (and comments) are preserved.
TACITUS_INI="$RA3_DIR/Data/Tacitus.ini"
PYTHON="$(command -v python3 || command -v python || true)"
[ -n "$PYTHON" ] || die "python not found (needed to edit Tacitus.ini)."
verbose_was="$(TACITUS_INI="$TACITUS_INI" "$PYTHON" - <<'PY'
import os, re
p = os.environ["TACITUS_INI"]
lines = open(p, encoding="utf-8", errors="replace").read().splitlines() if os.path.isfile(p) else []

def cur():
    for l in lines:
        if re.match(r"(?i)^\s*VerboseLog\s*=", l):
            return "true" if re.search(r"(?i)=\s*true\s*$", l) else "false"
    return "missing"

before = cur()
if before == "true":
    print("true"); raise SystemExit  # already on, leave file untouched

# set existing key to true, else inject under (or create) a [DEBUG] section
out, replaced, in_debug, injected = [], False, False, False
for l in lines:
    if re.match(r"(?i)^\s*VerboseLog\s*=", l):
        out.append("VerboseLog = true"); replaced = True; continue
    if re.match(r"^\s*\[", l):
        if in_debug and not injected:
            out.append("VerboseLog = true"); injected = True
        in_debug = bool(re.match(r"(?i)^\s*\[DEBUG\]\s*$", l))
    out.append(l)
if in_debug and not injected and not replaced:
    out.append("VerboseLog = true"); injected = True
if not replaced and not injected:
    if out and out[-1].strip():
        out.append("")
    out += ["[DEBUG]", "VerboseLog = true"]
open(p, "w", encoding="utf-8").write("\n".join(out) + "\n")
print(before)
PY
)"
case "$verbose_was" in
    true)    note "Tacitus VerboseLog already enabled." ;;
    missing) note "Tacitus VerboseLog enabled (created Tacitus.ini)." ;;
    *)       note "Tacitus VerboseLog enabled (was: $verbose_was)." ;;
esac

# --- 1c. install native MSVC 2005/2008 runtimes (fixes cross-platform desync) -------------
# THE desync fix. RA3 (a 2008, MSVC-2005-built game) calls its CRT's math functions
# (sin/cos/atan2/sqrt/pow) every simulation frame. Since Wine 5.15, Wine's builtin msvcr80/
# msvcr90 use a musl-based libm whose last-bit results differ from Microsoft's CRT. RA3 runs
# a deterministic lockstep sim: every client must compute byte-identical state from identical
# inputs, so those last-bit deltas accumulate until a state-checksum mismatch -> "out of sync"
# vs Windows opponents (typically within ~15 min). Installing the NATIVE Microsoft VC80/VC90
# runtimes (and overriding to native,builtin) makes the game's math match Windows again.
# VERIFIED here (2026-06-01): after this fix, two clean online games incl. a rematch vs the
# exact opponent that desynced every prior game. Full evidence chain + sources in the gist:
#   https://gist.github.com/AlJohri/e05190ffe6e0bc495a39cf2ab0df04b3
#
# protontricks resolves the prefix + Proton from Steam's config; it does NOT need Steam
# closed, so we do this before the config-edit section (which does). Idempotent: skip if
# winetricks.log already records both verbs. Non-fatal if protontricks is absent -- the rest
# of the setup is still useful; we just print the manual command.
COMPATDATA="${RA3_DIR%/common/*}/compatdata/$APPID"
WINETRICKS_LOG="$COMPATDATA/pfx/winetricks.log"
VCRUN_VERBS=(vcrun2005 vcrun2008)

vcrun_installed() {
    [ -f "$WINETRICKS_LOG" ] || return 1
    local v
    for v in "${VCRUN_VERBS[@]}"; do
        grep -qxF "$v" "$WINETRICKS_LOG" || return 1
    done
    return 0
}

if vcrun_installed; then
    note "Native MSVC 2005/2008 runtimes already installed (desync fix in place)."
elif ! command -v protontricks >/dev/null 2>&1; then
    warn "protontricks not found -- skipping the MSVC runtime (desync) fix."
    warn "Install it (omarchy: 'yay -S protontricks'), then run:  protontricks $APPID ${VCRUN_VERBS[*]}"
elif [ ! -d "$COMPATDATA/pfx" ]; then
    warn "No Proton prefix yet for appid $APPID (launch RA3 from Steam once to create it),"
    warn "then re-run this script -- it will install the MSVC runtime (desync) fix."
else
    note "Installing native MSVC 2005/2008 runtimes (desync fix) via protontricks..."
    # --no-bwrap: GE-Proton's new-wow64 prefix trips protontricks' bubblewrap sandbox; the
    # bare wine call works. Native MS DLLs land as side-by-side assemblies in the prefix's
    # winsxs/ (that's where the game's VC80.CRT manifest resolves them), with native,builtin
    # overrides for any direct loads.
    if protontricks --no-bwrap "$APPID" "${VCRUN_VERBS[@]}" >/dev/null 2>&1 && vcrun_installed; then
        note "MSVC 2005/2008 runtimes installed."
    else
        warn "protontricks run did not record both verbs; re-run manually if desyncs persist:"
        warn "    protontricks $APPID ${VCRUN_VERBS[*]}"
    fi
fi

# --- 2 + 3. Steam config edits (compat tool + launch options) ----------------------------
# These edit config.vdf / localconfig.vdf, which Steam rewrites from memory on exit -- so
# Steam MUST be closed or the changes get clobbered. We shut it down (gracefully) first.

if pgrep -x steam >/dev/null 2>&1; then
    note "Steam is running -- shutting it down so the config edits aren't clobbered..."
    # `steam -shutdown` is Valve's own graceful-exit command: it tells the running client
    # to flush its config and quit cleanly. Targeted -- it only signals Steam, nothing else.
    steam -shutdown >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
        pgrep -x steam >/dev/null 2>&1 || break
        sleep 1
    done
    # Fall back to a process-exact kill only if the graceful shutdown didn't take. `-x`
    # matches the literal process name "steam" -- it will not touch steamwebhelper, the
    # game, or anything else.
    if pgrep -x steam >/dev/null 2>&1; then
        warn "Graceful shutdown timed out; sending SIGTERM to the steam process..."
        pkill -x steam || true
        sleep 3
    fi
    pgrep -x steam >/dev/null 2>&1 && die "could not stop Steam; close it manually and re-run."
    note "Steam stopped."
fi

# Robust KeyValues editing needs a real parser (sed on .vdf is how you corrupt your library).
# Use python's `vdf` package in a throwaway venv so we add nothing to the system env.
PYTHON="$(command -v python3 || command -v python || true)"
[ -n "$PYTHON" ] || die "python not found (needed to edit Steam .vdf safely)."
VENV="$CACHE_DIR/venv"
if [ ! -x "$VENV/bin/python" ]; then
    note "Creating venv with the vdf parser..."
    "$PYTHON" -m venv "$VENV"
    "$VENV/bin/pip" install --quiet --upgrade pip vdf
fi

note "Setting GE-Proton + launch options for appid $APPID (backups written alongside)..."
STEAM_ROOT="$STEAM_ROOT" APPID="$APPID" COMPAT_TOOL="$COMPAT_TOOL" LAUNCH_OPTS="$LAUNCH_OPTS" \
"$VENV/bin/python" - <<'PY'
import os, glob, shutil, sys
import vdf

steam = os.environ["STEAM_ROOT"]
appid = os.environ["APPID"]
tool  = os.environ["COMPAT_TOOL"]
opts  = os.environ["LAUNCH_OPTS"]

def ci_get(d, key):
    """Case-insensitive child lookup; Steam varies 'Valve'/'valve' etc."""
    for k in d:
        if k.lower() == key.lower():
            return k, d[k]
    return None, None

def descend(d, path, create=True):
    cur = d
    for part in path:
        k, child = ci_get(cur, part)
        if child is None:
            if not create:
                return None
            cur[part] = {}
            cur = cur[part]
        else:
            cur = child
    return cur

def backup(path):
    bak = path + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)

# --- config.vdf: CompatToolMapping[appid] = GE-Proton ---
cfg = os.path.join(steam, "config", "config.vdf")
backup(cfg)
with open(cfg, encoding="utf-8") as f:
    data = vdf.load(f)
mapping = descend(data, ["InstallConfigStore", "Software", "Valve", "Steam", "CompatToolMapping"])
mapping[appid] = {"name": tool, "config": "", "Priority": "250"}
with open(cfg, "w", encoding="utf-8") as f:
    vdf.dump(data, f, pretty=True)
print(f"    config.vdf: CompatToolMapping[{appid}] = {tool}")

# --- localconfig.vdf (per Steam account): apps[appid].LaunchOptions ---
found = False
for lc in glob.glob(os.path.join(steam, "userdata", "*", "config", "localconfig.vdf")):
    backup(lc)
    with open(lc, encoding="utf-8") as f:
        data = vdf.load(f)
    apps = descend(data, ["UserLocalConfigStore", "Software", "Valve", "Steam", "apps"])
    k, app = ci_get(apps, appid)
    if app is None:
        apps[appid] = {}
        app = apps[appid]
    app["LaunchOptions"] = opts
    with open(lc, "w", encoding="utf-8") as f:
        vdf.dump(data, f, pretty=True)
    print(f"    {os.path.relpath(lc, steam)}: LaunchOptions set")
    found = True

if not found:
    print("    warning: no userdata/*/localconfig.vdf found -- launch options NOT set.", file=sys.stderr)
    print("    Set it by hand: RA3 -> Properties -> Launch Options ->", opts, file=sys.stderr)
PY

cat <<EOF

==> Done. Launch RA3 from Steam, go to Multiplayer -> Online, and log in with your
    C&C:Online account.

    Re-run this script after any RA3 update (Steam updates can overwrite dsound.dll).

    Optional: add the Community Patch v1.12.8 (extra maps + balance) with the standalone
    tool:  ra3-community-patch install   (~650MB download, ~4.5GB on disk; wine-free).
    Toggle it later with:  ra3-community-patch disable | enable
EOF
