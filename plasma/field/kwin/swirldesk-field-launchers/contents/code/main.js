function fieldLaunch(target) {
    callDBus(
        "org.swirldesk.FieldLauncher",
        "/org/swirldesk/FieldLauncher",
        "org.swirldesk.FieldLauncher",
        "Launch",
        target,
        function(ok) {
            if (!ok) {
                print("SwirlDesk FIELD: launcher failed for " + target);
            }
        }
    );
}

registerShortcut(
    "FIELD // Terminal",
    "Open Konsole",
    "Meta+Return",
    function() { fieldLaunch("terminal"); }
);

registerShortcut(
    "FIELD // Files",
    "Open Dolphin",
    "Meta+E",
    function() { fieldLaunch("files"); }
);

registerShortcut(
    "FIELD // Browser",
    "Open Firefox",
    "Meta+B",
    function() { fieldLaunch("browser"); }
);
