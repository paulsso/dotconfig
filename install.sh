#!/usr/bin/env bash
# Link dotconfig into place. Existing files that aren't already links into
# this repo are moved to <name>.backup first.
#
#   ./install.sh            link shell/terminal/editor/Hyprland configs
#   ./install.sh --plasma   also apply KDE Plasma rc files and install plasma-wm
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {
    local src="$DOT/$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        echo "   ok    $dst"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "$dst.backup"
        echo "   moved $dst -> $dst.backup"
    fi
    ln -s "$src" "$dst"
    echo "   link  $dst -> $src"
}

echo ":: Linking configs"
for d in hypr kitty nvim waybar btop neofetch sunpaper; do
    link "$d" "$CFG/$d"
done
link tmux/tmux.conf     "$CFG/tmux.conf"
link .zshrc             "$HOME/.zshrc"
link git/gitconfig      "$HOME/.gitconfig"
link dev-env            "$HOME/.local/bin/dev-env"
link flexoki.zsh-theme  "${ZSH:-$HOME/.oh-my-zsh}/custom/themes/flexoki.zsh-theme"

if [ "${1:-}" = "--plasma" ]; then
    echo ":: Applying KDE Plasma configs"
    "$DOT/plasma/sync.sh" apply
    echo ":: Installing plasma-wm"
    "$DOT/plasma-wm/install.sh"
fi

echo "Done."
