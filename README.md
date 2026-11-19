# dotconfig

Arch Linux configs. Clone to `~/dotconfig` and run `./install.sh`.

| Path                | Goes to                                  | How     |
|---------------------|------------------------------------------|---------|
| `hypr/`             | `~/.config/hypr` (Hyprland, idle, lock, paper) | symlink |
| `waybar/`           | `~/.config/waybar`                       | symlink |
| `kitty/`            | `~/.config/kitty`                        | symlink |
| `nvim/`             | `~/.config/nvim` (LazyVim)               | symlink |
| `btop/`             | `~/.config/btop`                         | symlink |
| `neofetch/`         | `~/.config/neofetch`                     | symlink |
| `sunpaper/`         | `~/.config/sunpaper`                     | symlink |
| `tmux/tmux.conf`    | `~/.config/tmux.conf`                    | symlink |
| `.zshrc`            | `~/.zshrc` (oh-my-zsh)                   | symlink |
| `flexoki.zsh-theme` | `~/.oh-my-zsh/custom/themes/`            | symlink |
| `git/gitconfig`     | `~/.gitconfig`                           | symlink |
| `dev-env`           | `~/.local/bin/dev-env` (tmux + nvim session) | symlink |
| `plasma/`           | KDE Plasma rc files in `~/.config`       | copy, see below |
| `plasma-wm/`        | i3-style kitty tiling KWin script        | `plasma-wm/install.sh` |

## KDE Plasma

KDE replaces symlinked rc files with plain files when it saves, so the
Plasma configs (`kwinrc`, `kxkbrc`, `kdeglobals`, `kglobalshortcutsrc`,
`powerdevilrc`) are copied:

```sh
plasma/sync.sh capture   # live ~/.config -> repo (then commit)
plasma/sync.sh apply     # repo -> ~/.config
./install.sh --plasma    # links everything, applies plasma/, installs plasma-wm
```

## plasma-wm

`plasma-wm/` is the [i3-terminal](plasma-wm/README.md) KWin script, pulled
in with `git subtree` (history kept). To pull new commits from the
standalone repo:

```sh
git subtree pull --prefix=plasma-wm ~/Projects/plasma-wm main
```
