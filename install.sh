#!/usr/bin/env bash
# Install the i3-terminal KWin script and bind Alt+Return to launch kitty.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$HERE/i3-terminal"
ID="i3-terminal"
DESKTOP="kitty.desktop"

# Qt key codes: Alt = 0x08000000, Return = 0x01000004
ALT_RETURN=$(( 0x08000000 | 0x01000004 ))

echo ":: Installing KWin script '$ID'"
if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/$ID" ]; then
    kpackagetool6 --type=KWin/Script --upgrade "$PKG"
else
    kpackagetool6 --type=KWin/Script --install "$PKG"
fi

echo ":: Enabling script"
kwriteconfig6 --file kwinrc --group Plugins --key "${ID}Enabled" true

echo ":: Reloading KWin scripts"
# Unload first so an upgraded script is picked up without logging out.
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$ID" >/dev/null || true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.start >/dev/null

echo ":: Binding Alt+Return -> $DESKTOP"
ACTION="['$DESKTOP', '_launch', 'kitty', 'Launch kitty']"
gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.doRegister "$ACTION" >/dev/null
gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.setForeignShortcutKeys "$ACTION" \
    "[([$ALT_RETURN, 0, 0, 0],)]" >/dev/null

echo
echo "Done:"
echo "  Alt+Return       open a new kitty terminal"
echo "  Alt+Shift+Q      close the focused window"
echo "  Alt+Shift+Space  toggle floating for a tiled window"
echo
echo "Change any of these in System Settings > Keyboard > Shortcuts;"
echo "tiling options are in System Settings > Window Management > KWin Scripts > i3 Terminal."
