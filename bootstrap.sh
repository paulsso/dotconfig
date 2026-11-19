#!/usr/bin/env bash
# One-shot KDE Plasma desktop setup for a fresh Arch install.
#
# Run as root at the "Post-installation" step of the Arch installation guide,
# either inside `arch-chroot /mnt` or after the first reboot:
#
#   pacman -S --needed git
#   git clone https://github.com/paulsso/dotconfig /root/dotconfig
#   /root/dotconfig/bootstrap.sh <username> [--extras] [--hyprland]
#
#   <username>   created (wheel, zsh) if missing, otherwise reused
#   --extras     gaming/apps: steam, lutris, wine, docker, tailscale, zen ...
#   --hyprland   also install the Hyprland session these dotfiles configure
#
# Env overrides: XKB_LAYOUT (default "se,us"), DOTCONFIG_REPO.
#
# Safe to re-run: packages use --needed and existing files are backed up.
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTCONFIG_REPO="${DOTCONFIG_REPO:-https://github.com/paulsso/dotconfig.git}"
XKB_LAYOUT="${XKB_LAYOUT:-se,us}"

USER_NAME=""
EXTRAS=0
HYPRLAND=0
for arg in "$@"; do
    case "$arg" in
        --extras)   EXTRAS=1 ;;
        --hyprland) HYPRLAND=1 ;;
        -h|--help)  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*)         echo "unknown option: $arg" >&2; exit 1 ;;
        *)          USER_NAME="$arg" ;;
    esac
done

msg() { printf '\n\033[1;34m::\033[0m %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || { echo "Run as root." >&2; exit 1; }
[ -n "$USER_NAME" ] || read -rp "Username to set up: " USER_NAME
[[ "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "Invalid username: $USER_NAME" >&2; exit 1; }

# --------------------------------------------------------------------------
# Packages
# --------------------------------------------------------------------------
PKGS=(
    # base tooling
    base-devel git sudo zsh man-db man-pages unzip curl
    networkmanager
    # KDE Plasma (Wayland) + login manager
    plasma-desktop sddm sddm-kcm kscreen powerdevil breeze breeze-gtk
    kde-gtk-config plasma-nm plasma-pa bluedevil xdg-desktop-portal-kde
    dolphin spectacle discover qt6-tools   # qt6-tools = qdbus6 (plasma-wm)
    # audio / bluetooth
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
    pavucontrol bluez bluez-utils
    # terminal & dev
    kitty tmux neovim btop htop fzf github-cli pyenv rustup fnm ninja
    # fonts
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji
)
AUR_PKGS=(neofetch)
SERVICES=(NetworkManager sddm bluetooth)

if [ "$HYPRLAND" -eq 1 ]; then
    PKGS+=(hyprland hypridle hyprlock hyprpaper hyprlauncher waybar
           xdg-desktop-portal-hyprland feh)
fi

if [ "$EXTRAS" -eq 1 ]; then
    PKGS+=(steam lutris wine flatpak docker tailscale ufw audacious helvum)
    AUR_PKGS+=(zen-browser-bin)
    SERVICES+=(docker tailscaled ufw)
fi

# GPU drivers (lspci comes from pciutils, which isn't in base)
pacman -S --needed --noconfirm pciutils >/dev/null
GPU="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' || true)"
if grep -qi nvidia <<<"$GPU"; then
    PKGS+=(nvidia-open nvidia-utils lib32-nvidia-utils)
elif grep -qE 'AMD|ATI|Radeon' <<<"$GPU"; then
    PKGS+=(mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon)
elif grep -qi intel <<<"$GPU"; then
    PKGS+=(mesa vulkan-intel lib32-mesa lib32-vulkan-intel)
fi

msg "Enabling multilib"
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
fi
# Some pacman.conf variants (e.g. container images) lack the block entirely.
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf
fi

msg "Installing packages"
pacman -Syu --needed --noconfirm "${PKGS[@]}"

# --------------------------------------------------------------------------
# User
# --------------------------------------------------------------------------
msg "Setting up user '$USER_NAME'"
if ! id "$USER_NAME" &>/dev/null; then
    useradd -m -G wheel -s /usr/bin/zsh "$USER_NAME"
    echo "Set a password for $USER_NAME:"
    until passwd "$USER_NAME"; do :; done
else
    usermod -aG wheel -s /usr/bin/zsh "$USER_NAME"
fi
if [ "$EXTRAS" -eq 1 ]; then usermod -aG docker "$USER_NAME"; fi

echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel

# Passwordless sudo just for the AUR steps below; removed on exit.
TMP_SUDO=/etc/sudoers.d/99-bootstrap-tmp
echo "$USER_NAME ALL=(ALL:ALL) NOPASSWD: ALL" > "$TMP_SUDO"
chmod 440 "$TMP_SUDO"
trap 'rm -f "$TMP_SUDO"' EXIT

HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
as_user() { sudo -u "$USER_NAME" -H bash -c "$1"; }

# --------------------------------------------------------------------------
# AUR
# --------------------------------------------------------------------------
if ! command -v yay &>/dev/null; then
    msg "Installing yay"
    as_user 'set -e; t=$(mktemp -d); git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$t/yay-bin"
             cd "$t/yay-bin" && makepkg -si --noconfirm; rm -rf "$t"'
fi
msg "Installing AUR packages: ${AUR_PKGS[*]}"
as_user "yay -S --needed --noconfirm --answerdiff None --answerclean None ${AUR_PKGS[*]}"

# --------------------------------------------------------------------------
# Dotfiles
# --------------------------------------------------------------------------
TARGET="$HOME_DIR/dotconfig"
msg "Putting dotconfig at $TARGET"
if [ ! -d "$TARGET/.git" ]; then
    if [ -d "$DOT/.git" ]; then
        # Clone the copy we're running from (keeps its branch, works offline),
        # then point origin at the real remote.
        git clone "$DOT" "$TARGET"
        git -C "$TARGET" remote set-url origin \
            "$(git -C "$DOT" remote get-url origin 2>/dev/null || echo "$DOTCONFIG_REPO")"
    else
        git clone "$DOTCONFIG_REPO" "$TARGET"
    fi
    chown -R "$USER_NAME:$USER_NAME" "$TARGET"
fi

if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
    msg "Installing oh-my-zsh"
    as_user "git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh"
fi

msg "Linking configs"
as_user "~/dotconfig/install.sh"

msg "Applying KDE Plasma configs"
as_user "~/dotconfig/plasma/sync.sh apply"

# plasma-wm registers shortcuts over D-Bus, which needs a running Plasma
# session, so run its installer once on first login.
msg "Scheduling plasma-wm install for first login"
as_user "mkdir -p ~/.config/autostart && cat > ~/.config/autostart/plasma-wm-firstrun.desktop <<EOF
[Desktop Entry]
Type=Application
Name=plasma-wm first-run install
Exec=$TARGET/plasma/firstrun.sh
X-KDE-autostart-phase=2
NoDisplay=true
EOF"

as_user "rustup default stable >/dev/null 2>&1 || true"

# --------------------------------------------------------------------------
# System config
# --------------------------------------------------------------------------
msg "Keyboard layout for SDDM/X11: $XKB_LAYOUT"
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "$XKB_LAYOUT"
EndSection
EOF

msg "SDDM: Breeze theme"
mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=breeze\n' > /etc/sddm.conf.d/10-theme.conf

msg "Enabling services: ${SERVICES[*]}"
systemctl enable "${SERVICES[@]}"
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service

msg "Done. Reboot and log in to the 'Plasma (Wayland)' session as $USER_NAME."
