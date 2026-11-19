/*
 * i3 Terminal — a small KWin script for Plasma 6 (Wayland & X11).
 *
 *  - Alt+Shift+Q closes the focused window (like i3's `kill`).
 *  - Windows whose class matches "TiledClasses" (default: kitty) are tiled
 *    automatically per screen + virtual desktop. Opening one splits the
 *    space, closing one lets the others reflow — like i3.
 *
 * Launching kitty with Alt+Return is a regular Plasma global shortcut on
 * kitty.desktop (KWin scripts cannot start processes); install.sh sets it.
 */

var LAYOUT_COLUMNS = 0;
var LAYOUT_ROWS = 1;
var LAYOUT_SPIRAL = 2;

var config = {};

function loadConfig() {
    config.enabled = readConfig("TilingEnabled", true);
    config.layout = readConfig("Layout", LAYOUT_COLUMNS);
    config.gap = Math.max(0, readConfig("Gap", 0));
    config.classes = String(readConfig("TiledClasses", "kitty"))
        .split(",")
        .map(function (s) { return s.trim().toLowerCase(); })
        .filter(function (s) { return s.length > 0; });
}

// Ordered list of managed windows; order = tiling order (insertion order,
// new windows go right after the focused one, like i3).
var managed = [];
// Windows the user toggled to floating.
var floating = [];

function indexOf(list, w) {
    for (var i = 0; i < list.length; i++) {
        if (list[i] === w) return i;
    }
    return -1;
}

function removeFrom(list, w) {
    var i = indexOf(list, w);
    if (i >= 0) list.splice(i, 1);
}

function matchesClass(w) {
    if (config.classes.indexOf("*") >= 0) return true;
    var cls = String(w.resourceClass || "").toLowerCase();
    var name = String(w.resourceName || "").toLowerCase();
    return config.classes.indexOf(cls) >= 0 || config.classes.indexOf(name) >= 0;
}

function isTileable(w) {
    return w && w.normalWindow && !w.transient && !w.specialWindow &&
        !w.dialog && !w.skipTaskbar && w.moveable && w.resizeable &&
        matchesClass(w);
}

// A managed window takes part in the current layout.
function isActiveTile(w) {
    return config.enabled && indexOf(floating, w) < 0 &&
        !w.minimized && !w.fullScreen && w.desktops.length === 1 &&
        w.output !== null && w.output !== undefined;
}

function groupKey(w) {
    return w.output.name + "|" + w.desktops[0].id;
}

function splitArea(area, n, layout) {
    var rects = [];
    var i;
    if (n <= 0) return rects;
    if (layout === LAYOUT_SPIRAL) {
        var r = { x: area.x, y: area.y, width: area.width, height: area.height };
        for (i = 0; i < n; i++) {
            if (i === n - 1) {
                rects.push(r);
                break;
            }
            if (i % 2 === 0) {
                var w = Math.floor(r.width / 2);
                rects.push({ x: r.x, y: r.y, width: w, height: r.height });
                r = { x: r.x + w, y: r.y, width: r.width - w, height: r.height };
            } else {
                var h = Math.floor(r.height / 2);
                rects.push({ x: r.x, y: r.y, width: r.width, height: h });
                r = { x: r.x, y: r.y + h, width: r.width, height: r.height - h };
            }
        }
        return rects;
    }
    var horizontal = layout !== LAYOUT_ROWS;
    var total = horizontal ? area.width : area.height;
    var pos = 0;
    for (i = 0; i < n; i++) {
        var size = Math.round(total * (i + 1) / n) - pos;
        if (horizontal) {
            rects.push({ x: area.x + pos, y: area.y, width: size, height: area.height });
        } else {
            rects.push({ x: area.x, y: area.y + pos, width: area.width, height: size });
        }
        pos += size;
    }
    return rects;
}

function applyGap(r, gap) {
    if (gap <= 0) return r;
    var half = gap / 2;
    return {
        x: Math.round(r.x + half),
        y: Math.round(r.y + half),
        width: Math.round(r.width - gap),
        height: Math.round(r.height - gap)
    };
}

var retiling = false;

function retile() {
    if (retiling) return;
    retiling = true;
    try {
        var groups = {};
        var order = [];
        for (var i = 0; i < managed.length; i++) {
            var w = managed[i];
            if (!isActiveTile(w)) continue;
            var key = groupKey(w);
            if (!groups[key]) {
                groups[key] = [];
                order.push(key);
            }
            groups[key].push(w);
        }
        for (var k = 0; k < order.length; k++) {
            var wins = groups[order[k]];
            var first = wins[0];
            var area = workspace.clientArea(KWin.MaximizeArea, first.output, first.desktops[0]);
            var g = config.gap;
            var inner = { x: area.x + g / 2, y: area.y + g / 2, width: area.width - g, height: area.height - g };
            var rects = splitArea(inner, wins.length, config.layout);
            for (var j = 0; j < wins.length; j++) {
                var win = wins[j];
                if (win.maximizeMode !== undefined && win.maximizeMode !== 0 && win.setMaximize) {
                    win.setMaximize(false, false);
                }
                win.frameGeometry = applyGap(rects[j], g);
            }
        }
    } finally {
        retiling = false;
    }
}

function onChanged() {
    retile();
}

function manage(w) {
    if (indexOf(managed, w) >= 0 || !isTileable(w)) return;

    // i3 semantics: new window goes right after the focused tile.
    var active = workspace.activeWindow;
    var pos = active && active !== w ? indexOf(managed, active) : -1;
    if (pos >= 0) {
        managed.splice(pos + 1, 0, w);
    } else {
        managed.push(w);
    }

    w.minimizedChanged.connect(onChanged);
    w.fullScreenChanged.connect(onChanged);
    w.desktopsChanged.connect(onChanged);
    w.outputChanged.connect(onChanged);
    // Snap a dragged/resized tile back into the layout.
    w.interactiveMoveResizeFinished.connect(onChanged);

    retile();
}

function unmanage(w) {
    if (indexOf(managed, w) < 0) return;
    removeFrom(managed, w);
    removeFrom(floating, w);
    retile();
}

function closeActive() {
    var w = workspace.activeWindow;
    if (w && w.closeable) {
        w.closeWindow();
    }
}

function toggleFloating() {
    var w = workspace.activeWindow;
    if (!w || indexOf(managed, w) < 0) return;
    if (indexOf(floating, w) >= 0) {
        removeFrom(floating, w);
    } else {
        floating.push(w);
        // Give it a sensible floating size centred on its screen.
        var area = workspace.clientArea(KWin.MaximizeArea, w.output, w.desktops[0] || workspace.currentDesktop);
        var fw = Math.round(area.width * 0.5), fh = Math.round(area.height * 0.6);
        w.frameGeometry = {
            x: Math.round(area.x + (area.width - fw) / 2),
            y: Math.round(area.y + (area.height - fh) / 2),
            width: fw,
            height: fh
        };
        w.keepAbove = false;
    }
    retile();
}

function init() {
    loadConfig();

    registerShortcut("i3TerminalClose", "i3 Terminal: Close focused window",
        "Alt+Shift+Q", closeActive);
    registerShortcut("i3TerminalToggleFloating", "i3 Terminal: Toggle floating",
        "Alt+Shift+Space", toggleFloating);

    workspace.windowAdded.connect(manage);
    workspace.windowRemoved.connect(unmanage);
    workspace.currentDesktopChanged.connect(onChanged);
    workspace.screensChanged.connect(onChanged);
    if (workspace.virtualScreenGeometryChanged) {
        workspace.virtualScreenGeometryChanged.connect(onChanged);
    }

    options.configChanged.connect(function () {
        loadConfig();
        retile();
    });

    var existing = workspace.windowList();
    for (var i = 0; i < existing.length; i++) {
        manage(existing[i]);
    }
}

init();
