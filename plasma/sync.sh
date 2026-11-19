#!/usr/bin/env bash
# KDE rewrites its rc files atomically, which replaces symlinks with plain
# files, so these are copied instead of linked.
#
#   ./sync.sh capture   copy the live files from ~/.config into this repo
#   ./sync.sh apply     copy the repo files into ~/.config (old ones -> .backup)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
FILES=(kwinrc kxkbrc kdeglobals kglobalshortcutsrc powerdevilrc)

case "${1:-}" in
    capture)
        for f in "${FILES[@]}"; do cp -v "$CFG/$f" "$HERE/$f"; done
        ;;
    apply)
        for f in "${FILES[@]}"; do
            [ -e "$CFG/$f" ] && cp "$CFG/$f" "$CFG/$f.backup"
            cp -v "$HERE/$f" "$CFG/$f"
        done
        # Ask running KWin/Plasma to pick up the changes.
        qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
        echo "Log out and back in for shortcuts and colors to fully apply."
        ;;
    *)
        echo "usage: $0 capture|apply" >&2
        exit 1
        ;;
esac
