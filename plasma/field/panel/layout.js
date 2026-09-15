// SwirlDesk FIELD // Plasma rail layout
// Plasma 6 desktop scripting API

var currentPanels = panels();
for (var i = 0; i < currentPanels.length; ++i) {
    currentPanels[i].remove();
}

var panel = new Panel;
panel.location = "top";
panel.height = 30;
panel.lengthMode = "fill";
panel.hiding = "none";
panel.alignment = "center";

// FIELD identity first, then native Plasma launcher and compact FIELD pager.
if (knownWidgetTypes.includes("org.swirldesk.fieldlabel")) {
    panel.addWidget("org.swirldesk.fieldlabel");
}

var launcher = panel.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "swirldesk-field-launcher");
launcher.reloadConfig();
// FIELD parity: this is the actual application menu, not KRunner.
launcher.globalShortcut = ""; // Meta+Ctrl+Return belongs to FIELD // Quick Launch

panel.addWidget("org.swirldesk.fieldpager");

// Compact native task manager; current-desktop only keeps the rail calm.
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("showOnlyCurrentDesktop", "true");
tasks.writeConfig("showOnlyCurrentScreen", "false");
tasks.reloadConfig();

panel.addWidget("org.kde.plasma.panelspacer");
panel.addWidget("org.kde.plasma.systemtray");

var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "false");
clock.writeConfig("showSeconds", "false");
clock.writeConfig("use24hFormat", "2");
clock.reloadConfig();
