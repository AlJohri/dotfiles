#!/usr/bin/env bash
set -euo pipefail

# Setup script for Command & Conquer: Red Alert 3 online play (C&C:Online / "Tacitus")
# on Linux via Steam + Proton. Run standalone; NOT wired into setup-omarchy.sh because
# it depends on you having bought + installed RA3 in Steam first (account-bound).
#
# Usage: ./setup-ra3-online.sh
#
# What this automates (all idempotent, safe to re-run):
#   1. Drops the Tacitus dsound.dll next to every RA3 executable.
#   2. Forces GE-Proton for the RA3 appid (config.vdf CompatToolMapping).
#   3. Sets the dsound launch override for the RA3 appid (localconfig.vdf LaunchOptions).
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

# ─────────────────────────────────────────────────────────────────────────────
# FUTURE AUTOMATION NOTES — Community Patch (so a later session can resume cleanly)
# ─────────────────────────────────────────────────────────────────────────────
# The Community Patch install is currently MANUAL (instructions printed at the end).
# Everything learned while trying to automate it, so we can pick up where we left off:
#
# 1. WHY IT RESISTS SCRIPTING:
#    - Installer RA3CommunityPatchSetup_v1.12.8.exe (~680MB, moddb id 306433) uses the
#      Nsis7z runtime plugin. The ~4.5GB of .big map data is compressed inside and only
#      unpacks when the installer RUNS -- it can't be statically extracted (unlike the
#      Tacitus dsound.dll, a plain file we pull with `7z e`).
#    - Plain `/S` (NSIS silent) deploys NOTHING: the file copy sits behind the custom
#      "Choose Install Location" wizard page, which /S skips.
#    - GE-Proton's bundled wine CRASHES on this installer (null-ptr fault). Only SYSTEM
#      wine (pacman `wine` + `wine-mono`) runs it successfully.
#
# 2. HEADLESS ATTEMPT — INCONCLUSIVE, RESUME HERE:
#    `wine RA3CommunityPatchSetup_v1.12.8.exe /S /D=<native_gamedir>` — NSIS's /D sets
#    the install dir explicitly and MIGHT bypass the wizard-page gate that makes bare /S
#    a no-op. Was being tested but interrupted before confirming files deploy. Rules:
#    /D must be the LAST arg, unquoted, and a NATIVE path (not Z:\...). Verify success by
#    checking <gamedir>/CommunityPatch/*.big exists afterward. If it works, the whole
#    patch install becomes scriptable (download + this one command).
#
# 3. WHAT A SUCCESSFUL INSTALL PRODUCES (to replicate by caching the payload once):
#    - <gamedir>/CommunityPatch/ : 9x Patch1.12.8_*.big maps, ManageCommunityPatch.exe
#      (the on/off toggle), RA3_.SkuDef (lists the .big via add-big lines), Patch Notes PDF.
#    - Backs up RA3_english_1.13.SkuDef -> BACKUP_RA3_english_1.13.SkuDef.
#    - Rewrites RA3_english_1.13.SkuDef to:
#          set-exe Data\RA3_1.12.game
#          add-config CommunityPatch\RA3_.SkuDef
#          add-config RA3_english_1.12.SkuDef
#
# 4. ENABLE / DISABLE = a SkuDef file swap (no need to run ManageCommunityPatch.exe):
#      enable : cp <patched RA3_english_1.13.SkuDef> RA3_english_1.13.SkuDef
#      disable: cp BACKUP_RA3_english_1.13.SkuDef    RA3_english_1.13.SkuDef
#    The .big files staying on disk while disabled is harmless.
#
# 5. GOTCHA — STALE WINESERVERS BREAK THE GAME LAUNCH:
#    After running SYSTEM wine (e.g. the patch installer), leftover wineserver processes
#    make GE-Proton fail to launch RA3 with:
#       err:fsync:fsync_init Failed to open fsync shared memory file; make sure no stale
#       wineserver instances are running without WINEFSYNC
#    Symptom: Steam shows STOP but no game window; it dies instantly. FIX: kill the stale
#    wineservers by PID (`pgrep wineserver`, then `kill -9 <pid>` -- do NOT `pkill -f
#    wineserver`, it self-matches the shell), then the game launches normally.
# ─────────────────────────────────────────────────────────────────────────────

# Windows-style path for the wine install dialog (Z: maps to /, backslash separators).
RA3_WINPATH="Z:${RA3_DIR//\//\\}"

cat <<EOF

==> Done. Launch RA3 from Steam, go to Multiplayer -> Online, and log in with your
    C&C:Online account.

    Re-run this script after any RA3 update (Steam updates can overwrite dsound.dll).

--------------------------------------------------------------------------------
OPTIONAL: Red Alert 3 Community Patch v1.12.8 (extra maps + balance changes)
--------------------------------------------------------------------------------
Not automated -- its GUI installer crashes under Proton/GE-Proton's wine, and the
~4.5GB of map data only unpacks when the installer's wizard runs (it's compressed
inside the .exe via an NSIS runtime plugin, so it can't be extracted headlessly).
Install it by hand once with SYSTEM wine:

  1. sudo pacman -S --needed wine wine-mono       # wine-mono: installer's config tool needs .NET
  2. Download "RA3CommunityPatchSetup_v1.12.8.exe" from:
       https://www.moddb.com/mods/red-alert-3-community-patch/downloads
  3. wine ~/Downloads/RA3CommunityPatchSetup_v1.12.8.exe
       - If a wine-mono prompt still appears, Cancel it (step 1 covers it).
       - On "Choose Install Location", point it at your RA3 game dir:
           $RA3_WINPATH
       - Pick components, Install, Finish.
  4. IMPORTANT after install: running system wine leaves stale wineserver processes
     that make RA3 fail to launch under Proton (it dies instantly, no window). Clear
     them before playing:
           for p in \$(pgrep wineserver); do kill -9 "\$p"; done
     (Use PIDs like this -- 'pkill -f wineserver' would kill your own shell.)

  What it does (FYI): creates CommunityPatch/ in the game dir (9 *.big map files +
  ManageCommunityPatch.exe + RA3_.SkuDef), backs up RA3_english_1.13.SkuDef to
  BACKUP_RA3_english_1.13.SkuDef, and rewrites RA3_english_1.13.SkuDef to chain in
  the patch maps. Toggle on/off by swapping that SkuDef (see FUTURE AUTOMATION NOTES
  in this script's source) or by running ManageCommunityPatch.exe via wine.

  Note: the patch is incompatible with Steam's v1.13 Workshop. A Steam update that
  rewrites RA3_english_1.13.SkuDef will silently disable the patch -- re-enable by
  swapping the SkuDef back (or re-run ManageCommunityPatch.exe).
EOF
