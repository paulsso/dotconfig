#!/usr/bin/env bash
# Remove the i3-terminal KWin script and the Alt+Shift+Return kitty binding.
set -uo pipefail

ID="i3-terminal"
DESKTOP="kitty.desktop"

qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$ID" >/dev/null
kwriteconfig6 --file kwinrc --group Plugins --key "${ID}Enabled" --delete
kpackagetool6 --type=KWin/Script --remove "$ID"
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null

ACTION="['$DESKTOP', '_launch', 'kitty', 'Launch kitty']"
gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.setForeignShortcutKeys "$ACTION" "@a(ai) []" >/dev/null

# Drop the script's own shortcuts from the kwin component.
for name in i3TerminalClose i3TerminalToggleFloating; do
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method org.kde.KGlobalAccel.unregister kwin "$name" >/dev/null || true
done

echo "Uninstalled i3-terminal."
