# i3-terminal for KDE Plasma (Wayland)

i3-style terminal handling inside a normal Plasma 6 session.

| Shortcut           | Action                                   |
|--------------------|------------------------------------------|
| `Alt+Shift+Return` | Open a new kitty terminal                |
| `Alt+Shift+Q`      | Close the focused window                 |
| `Alt+Shift+Space`  | Toggle floating for a tiled window       |
| `Alt+Shift+H/J/K/L`| Move the focused terminal left/down/up/right |

kitty windows are tiled automatically per screen and virtual desktop.
A new terminal opens to the right of the focused one, and closing one
lets the others reflow, like i3's default `splith` layout. Other
applications are not touched.

Gaps shrink as a screen fills up: 1 terminal gets 48 px, 2 get 24 px,
3 get 12 px, and 4 or more get no gaps.

Moving a terminal swaps it with its neighbour in that direction; if there
is none, it moves to the next monitor in that direction.

## Install / uninstall

```sh
./install.sh     # also used to upgrade after editing the script
./uninstall.sh
```

No logout needed.

## How it works

- `i3-terminal/` is a KWin script (JavaScript). It registers
  `Alt+Shift+Q` / `Alt+Shift+Space` as KWin global shortcuts and does the tiling.
- KWin scripts can't start processes, so `Alt+Shift+Return` is a standard Plasma
  launch shortcut on `kitty.desktop`, registered via kglobalaccel over D-Bus
  (the same thing *System Settings → Shortcuts → Add Application* does).

## Configuration

*System Settings → Window Management → KWin Scripts → i3 Terminal → ⚙*

- **Window classes to tile**: comma-separated, default `kitty`; `*` tiles every normal window
- **Layout**: columns (default), rows, or spiral
- **Gaps** for 1, 2 and 3 terminals (4+ terminals always have none)
- Tiling on/off (the shortcuts still work when tiling is off)

Rebind any shortcut in *System Settings → Keyboard → Shortcuts*
(search for "i3 Terminal" or "kitty").

Fullscreen, minimized and "on all desktops" windows are left out of the
layout. Dragging a tiled window snaps it back into place when you let go.
