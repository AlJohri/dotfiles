#!/usr/bin/env bash
set -euo pipefail

# Setup script for Bloons TD 6 modding on Linux via Steam + Proton.
# Run standalone; NOT wired into setup-omarchy.sh because it depends on you having
# bought + installed BTD6 in Steam first (account-bound).
#
# Usage: ./setup-btd6-mods.sh
#
# What this automates (all idempotent, safe to re-run):
#   1. Installs MelonLoader (the IL2CPP mod loader) into the BTD6 game dir.
#   2. Installs the .NET 6 desktop runtime into BTD6's Proton prefix via protontricks --
#      MelonLoader's IL2CPP support module is a .NET 6 app and will not start without it.
#   3. Downloads the mod DLLs (BTD Mod Helper, FasterForward, RetryAnywhere) into <game>/Mods/.
#   4. Sets the version.dll launch override for the BTD6 appid (localconfig.vdf
#      LaunchOptions) so Proton actually loads MelonLoader.
#
# Why the Windows MelonLoader build and not MelonLoader.Linux.x64.zip: BTD6 has no native
# Linux build -- it is the Windows binary running under Proton, so it needs the Windows
# loader. The .Linux build is for Unity games with real Linux binaries.
#
# Why the launch override: MelonLoader ships as version.dll, a proxy DLL that the game
# loads instead of the system one at startup. Wine resolves version.dll to its own builtin
# unless told otherwise, so without WINEDLLOVERRIDES the game just launches unmodded --
# no error, no Mods button. This is the single most common "mods don't work" cause on Linux.
#
# What you STILL must do by hand (cannot be automated):
#   - Own + install "Bloons TD 6" in Steam, and launch it once so Proton creates the prefix.
#   - Close the game + Steam before running this (the script stops Steam itself, since Steam
#     rewrites its config from memory on exit and would clobber the launch-options edit).
#
# Related (already in this repo, no action needed): hypr/.config/hypr/hyprland.conf carries
# a `render_unfocused` window rule for steam_app_960090. Without it Hyprland stops sending
# frame callbacks to the window on a hidden workspace and Unity's game loop stalls mid-round.

APPID=960090
GAME_DIR_NAME="BloonsTD6"

# Pinned to what BTD Mod Helper's install guide currently recommends, NOT to MelonLoader
# "latest" -- Mod Helper tracks a specific loader version and newer ones have broken it
# before. Check https://gurrenm3.github.io/BTD-Mod-Helper/wiki/Install-Guide before bumping.
MELON_VERSION="v0.7.2"
MELON_URL="https://github.com/LavaGang/MelonLoader/releases/download/$MELON_VERSION/MelonLoader.x64.zip"

# Mods, as "filename<TAB>url". These use GitHub's /releases/latest/download/ redirect rather
# than a pinned tag: BTD6 mods are compiled against a specific game version and go stale the
# moment Ninja Kiwi ships an update, so "whatever the author released last" is the correct
# target. Re-run this script after a BTD6 update to pull the rebuilt mods.
MODS=(
    $'Btd6ModHelper.dll\thttps://github.com/gurrenm3/BTD-Mod-Helper/releases/latest/download/Btd6ModHelper.dll'
    $'FasterForward.dll\thttps://github.com/doombubbles/FasterForward/releases/latest/download/FasterForward.dll'
    $'RetryAnywhere.dll\thttps://github.com/doombubbles/RetryAnywhere/releases/latest/download/RetryAnywhere.dll'
)

# Args after %command% are forwarded to the game exe, where MelonLoader parses them.
# --melonloader.hideconsole suppresses the loader console window that otherwise pops up
# alongside the game on every launch. It only hides the window -- everything still gets
# written to MelonLoader/Latest.log, so nothing is lost for debugging. (Equivalent to
# hide_console = true under [console] in <game>/UserData/Loader.cfg, but that file is only
# generated on first modded launch, so the launch option is the one that works on a fresh
# install too.)
LAUNCH_OPTS='WINEDLLOVERRIDES="version=n,b" %command% --melonloader.hideconsole'
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/btd6-mods"

note() { printf '==> %s\n' "$*"; }
warn() { printf '    %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

for a in "$@"; do
    case "$a" in
        -h|--help) sed -n '4,30p' "$0"; exit 0 ;;
        *) die "unknown argument: $a (this script takes no options)" ;;
    esac
done

# --- locate the Steam root and the BTD6 install ------------------------------------------

# Steam stores config under one root, but games can live in additional library folders.
STEAM_ROOT=""
for r in "$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root"; do
    if [ -f "$r/config/config.vdf" ]; then STEAM_ROOT="$r"; break; fi
done
[ -n "$STEAM_ROOT" ] || die "Steam not found (no config/config.vdf). Install + launch Steam once first."
note "Steam root: $STEAM_ROOT"

mapfile -t LIB_PATHS < <(
    printf '%s\n' "$STEAM_ROOT"
    lf="$STEAM_ROOT/steamapps/libraryfolders.vdf"
    [ -f "$lf" ] && grep -oP '"path"\s*"\K[^"]+' "$lf"
)

GAME_DIR="" LIB_ROOT=""
for lib in "${LIB_PATHS[@]}"; do
    cand="$lib/steamapps/common/$GAME_DIR_NAME"
    if [ -d "$cand" ]; then GAME_DIR="$cand"; LIB_ROOT="$lib"; break; fi
done
[ -n "$GAME_DIR" ] || die "BTD6 not installed. Buy + install 'Bloons TD 6' in Steam, then re-run."
note "BTD6 install: $GAME_DIR"

mkdir -p "$CACHE_DIR"

# --- 1. install MelonLoader ---------------------------------------------------------------
# The zip is flat: MelonLoader/ + version.dll + dobby.dll, all extracted over the game root.
# We stamp the installed version so re-runs are cheap and a MELON_VERSION bump reinstalls.

STAMP="$GAME_DIR/MelonLoader/.installed-version"
if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$MELON_VERSION" ] && [ -f "$GAME_DIR/version.dll" ]; then
    note "MelonLoader $MELON_VERSION already installed."
else
    command -v unzip >/dev/null 2>&1 || die "unzip not found. Install it: sudo pacman -S --needed unzip"
    zip="$CACHE_DIR/MelonLoader.x64.$MELON_VERSION.zip"
    if [ ! -f "$zip" ]; then
        note "Downloading MelonLoader $MELON_VERSION..."
        curl -fL --retry 3 -o "$zip.part" "$MELON_URL" || die "download failed: $MELON_URL"
        mv "$zip.part" "$zip"
    fi
    note "Extracting MelonLoader into the game dir..."
    unzip -qo "$zip" -d "$GAME_DIR" || die "extraction failed (corrupt download? rm $zip and retry)"
    [ -f "$GAME_DIR/version.dll" ] || die "version.dll missing after extract (zip layout changed?)"
    printf '%s\n' "$MELON_VERSION" > "$STAMP"
    note "MelonLoader $MELON_VERSION installed."
fi

# --- 2. install the .NET 6 desktop runtime into the Proton prefix -------------------------
# MelonLoader's IL2CPP path runs on .NET 6; the prefix has no runtime by default, so the
# loader silently no-ops (or the game hangs on a black window) without this. dotnetdesktop6
# is the winetricks verb for the Desktop Runtime, which is the superset MelonLoader wants.
# Idempotent via winetricks.log. Non-fatal if protontricks is missing -- everything else is
# still worth doing; we just print the manual command.
COMPATDATA="$LIB_ROOT/steamapps/compatdata/$APPID"
WINETRICKS_LOG="$COMPATDATA/pfx/winetricks.log"
DOTNET_VERB="dotnetdesktop6"

if [ -f "$WINETRICKS_LOG" ] && grep -qxF "$DOTNET_VERB" "$WINETRICKS_LOG"; then
    note ".NET 6 desktop runtime already installed in the BTD6 prefix."
elif ! command -v protontricks >/dev/null 2>&1; then
    warn "protontricks not found -- skipping the .NET 6 runtime install (mods will NOT load)."
    warn "Install it (omarchy: 'yay -S protontricks'), then run:  protontricks $APPID $DOTNET_VERB"
elif [ ! -d "$COMPATDATA/pfx" ]; then
    warn "No Proton prefix yet for appid $APPID (launch BTD6 from Steam once to create it),"
    warn "then re-run this script -- it will install the .NET 6 runtime."
else
    note "Installing $DOTNET_VERB via protontricks (slow: downloads + runs MS installers)..."
    # --no-bwrap: newer Proton's wow64 prefixes trip protontricks' bubblewrap sandbox; the
    # bare wine call works. Same workaround as setup-ra3-online.sh.
    if protontricks --no-bwrap "$APPID" "$DOTNET_VERB" >/dev/null 2>&1 \
       && grep -qxF "$DOTNET_VERB" "$WINETRICKS_LOG" 2>/dev/null; then
        note ".NET 6 desktop runtime installed."
    else
        warn "protontricks did not record $DOTNET_VERB; run it manually and watch the output:"
        warn "    protontricks --no-bwrap $APPID $DOTNET_VERB"
    fi
fi

# --- 3. download the mod DLLs -------------------------------------------------------------
# MelonLoader creates Mods/ on first modded launch, but it is happy to find one already
# there. curl -z makes each re-run a conditional GET, so unchanged mods aren't re-downloaded.

MODS_DIR="$GAME_DIR/Mods"
mkdir -p "$MODS_DIR"
for entry in "${MODS[@]}"; do
    name="${entry%%$'\t'*}"
    url="${entry#*$'\t'}"
    dest="$MODS_DIR/$name"
    if [ -f "$dest" ]; then
        if curl -fsSL --retry 3 -z "$dest" -o "$dest.part" "$url" && [ -s "$dest.part" ]; then
            mv "$dest.part" "$dest"; note "$name updated."
        else
            rm -f "$dest.part"; note "$name already current."
        fi
    else
        note "Downloading $name..."
        curl -fL --retry 3 -o "$dest.part" "$url" || die "download failed: $url"
        mv "$dest.part" "$dest"
    fi
done

# --- 4. Steam config edit (launch options) ------------------------------------------------
# localconfig.vdf is rewritten by Steam from memory on exit, so Steam MUST be closed or the
# change gets clobbered. We shut it down (gracefully) first.

if pgrep -x steam >/dev/null 2>&1; then
    note "Steam is running -- shutting it down so the config edit isn't clobbered..."
    # `steam -shutdown` is Valve's own graceful-exit command: it tells the running client
    # to flush its config and quit cleanly. Targeted -- it only signals Steam.
    steam -shutdown >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
        pgrep -x steam >/dev/null 2>&1 || break
        sleep 1
    done
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

note "Setting launch options for appid $APPID (backups written alongside)..."
STEAM_ROOT="$STEAM_ROOT" APPID="$APPID" LAUNCH_OPTS="$LAUNCH_OPTS" \
"$VENV/bin/python" - <<'PY'
import os, glob, shutil, sys
import vdf

steam = os.environ["STEAM_ROOT"]
appid = os.environ["APPID"]
opts  = os.environ["LAUNCH_OPTS"]

def ci_get(d, key):
    """Case-insensitive child lookup; Steam varies 'Valve'/'valve' etc."""
    for k in d:
        if k.lower() == key.lower():
            return k, d[k]
    return None, None

def descend(d, path):
    cur = d
    for part in path:
        _, child = ci_get(cur, part)
        if child is None:
            cur[part] = {}
            cur = cur[part]
        else:
            cur = child
    return cur

found = False
for lc in glob.glob(os.path.join(steam, "userdata", "*", "config", "localconfig.vdf")):
    bak = lc + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(lc, bak)
    with open(lc, encoding="utf-8") as f:
        data = vdf.load(f)
    apps = descend(data, ["UserLocalConfigStore", "Software", "Valve", "Steam", "apps"])
    _, app = ci_get(apps, appid)
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
    print("    Set it by hand: BTD6 -> Properties -> Launch Options ->", opts, file=sys.stderr)
PY

cat <<EOF

==> Done. Launch BTD6 from Steam. A "Mods" button in the bottom-right of the main menu
    means Mod Helper loaded. First launch after a game update is slow (a few minutes):
    MelonLoader regenerates the Il2Cpp assemblies before mods load.

    Faster Forward: fast-forward is now 5x/10x/25x -- click the fast-forward button
    repeatedly to cycle rates.
    Retry Anywhere: the retry button now works in modes that normally hide it.

    The MelonLoader console window is suppressed (--melonloader.hideconsole); everything
    it printed still goes to MelonLoader/Latest.log.

    If the Mods button never appears, read the loader log -- it names the failing mod:
        $GAME_DIR/MelonLoader/Latest.log

    Re-run this script after a BTD6 update: Steam updates can wipe version.dll, and mods
    need rebuilding against the new game version (this pulls the authors' latest).
EOF
