#!/usr/bin/env python3
import os
import subprocess
import sys

try:
    import gi
    from gi.repository import Gio, GLib
except Exception as exc:
    print(f"FIELD launcher: PyGObject unavailable: {exc}", file=sys.stderr)
    raise

BUS_NAME = "org.swirldesk.FieldLauncher"
OBJECT_PATH = "/org/swirldesk/FieldLauncher"
INTERFACE = "org.swirldesk.FieldLauncher"
VERSION = "0.5.2"

APPS = {
    "terminal": ["konsole"],
    "files": ["dolphin"],
    "browser": ["firefox"],
}

XML = """
<node>
  <interface name="org.swirldesk.FieldLauncher">
    <method name="Launch">
      <arg type="s" name="app" direction="in"/>
      <arg type="b" name="ok" direction="out"/>
    </method>
    <method name="Ping">
      <arg type="s" name="version" direction="out"/>
    </method>
  </interface>
</node>
"""

node_info = Gio.DBusNodeInfo.new_for_xml(XML)
iface_info = node_info.interfaces[0]
loop = GLib.MainLoop()
_registration_id = 0


def _launch(app: str) -> bool:
    command = APPS.get(app)
    if not command:
        return False
    try:
        subprocess.Popen(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            cwd=os.path.expanduser("~"),
            env=os.environ.copy(),
            start_new_session=True,
        )
        return True
    except (OSError, subprocess.SubprocessError):
        return False


def on_method_call(connection, sender, object_path, interface_name, method_name, parameters, invocation):
    if method_name == "Launch":
        app = parameters.unpack()[0]
        invocation.return_value(GLib.Variant("(b)", (_launch(app),)))
        return
    if method_name == "Ping":
        invocation.return_value(GLib.Variant("(s)", (VERSION,)))
        return
    invocation.return_dbus_error("org.swirldesk.FieldLauncher.Error.UnknownMethod", method_name)


def on_bus_acquired(connection, name):
    global _registration_id
    _registration_id = connection.register_object(OBJECT_PATH, iface_info, on_method_call, None, None)


def on_name_lost(connection, name):
    print("FIELD launcher: could not own D-Bus name", file=sys.stderr)
    loop.quit()


owner_id = Gio.bus_own_name(
    Gio.BusType.SESSION,
    BUS_NAME,
    Gio.BusNameOwnerFlags.NONE,
    on_bus_acquired,
    None,
    on_name_lost,
)

try:
    loop.run()
finally:
    Gio.bus_unown_name(owner_id)
