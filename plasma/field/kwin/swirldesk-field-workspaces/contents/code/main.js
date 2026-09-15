// SwirlDesk FIELD // Plasma 0.8.5
// Native KWin 6 move+follow shortcuts.

function moveAndFollow(index) {
    const desktops = workspace.desktops;
    if (!desktops || index < 0 || index >= desktops.length) {
        return;
    }

    const win = workspace.activeWindow;
    const target = desktops[index];
    if (!win || !target) {
        return;
    }

    // KWin 6 exposes Window.desktops as a writable property and
    // Workspace.currentDesktop as the currently active VirtualDesktop.
    win.desktops = [target];
    workspace.currentDesktop = target;
}

for (let i = 0; i < 6; ++i) {
    const n = i + 1;
    registerShortcut(
        "FIELD Move+Follow Desktop " + n,
        "FIELD // Move active window to desktop " + n + " and follow",
        "Meta+Shift+" + n,
        function() { moveAndFollow(i); }
    );
}
