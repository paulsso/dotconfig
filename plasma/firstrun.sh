#!/bin/sh
# Run once from autostart on the first Plasma login (bootstrap.sh sets it up):
# installs plasma-wm, whose shortcut registration needs a live session.
sleep 5
log="$HOME/.cache/plasma-wm-install.log"
mkdir -p "$HOME/.cache"
if "$HOME/dotconfig/plasma-wm/install.sh" >"$log" 2>&1; then
    rm -f "$HOME/.config/autostart/plasma-wm-firstrun.desktop"
fi
