// SwirlDesk FIELD // Plasma 0.8.8
// German-layout Move+Follow shortcuts.
//
// KDE/KWin resolves Shift+number through the active keyboard layout. On a
// German layout the physical chords Meta+Shift+1..6 arrive as Meta+!, Meta+",
// Meta+§, Meta+$, Meta+%, Meta+&. These exact bindings were verified live.

const bindings = [
    ['Meta+!', 0, '1'],
    ['Meta+"', 1, '2'],
    ['Meta+§', 2, '3'],
    ['Meta+$', 3, '4'],
    ['Meta+%', 4, '5'],
    ['Meta+&', 5, '6'],
];

function moveAndFollow(index) {
    const win = workspace.activeWindow;
    const desktops = workspace.desktops;

    if (!win || !desktops || desktops.length <= index) {
        return;
    }

    const target = desktops[index];
    win.desktops = [target];
    workspace.currentDesktop = target;
}

for (const [shortcut, index, label] of bindings) {
    registerShortcut(
        `FIELD DE MoveFollow Desktop ${label}`,
        `FIELD // Move active window to desktop ${label} and follow`,
        shortcut,
        () => moveAndFollow(index)
    );
}
