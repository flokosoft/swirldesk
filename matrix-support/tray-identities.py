#!/usr/bin/env python3
"""Read-only SNI diagnostic. No messages, tooltip contents or pixmap bytes printed."""
import sys
try:
    import gi
    from gi.repository import Gio, GLib
except ImportError:
    print('INFO     PyGObject unavailable; tray identity diagnostic skipped')
    sys.exit(0)
try:
    bus=Gio.bus_get_sync(Gio.BusType.SESSION,None)
except GLib.Error as e:
    print('INFO     no session bus'); sys.exit(0)
def get(service,path,interface,key):
    v=bus.call_sync(service,path,'org.freedesktop.DBus.Properties','Get',GLib.Variant('(ss)',(interface,key)),GLib.VariantType.new('(v)'),Gio.DBusCallFlags.NONE,1000,None)
    return v.get_child_value(0).get_variant().unpack()
try:
    entries=get('org.kde.StatusNotifierWatcher','/StatusNotifierWatcher','org.kde.StatusNotifierWatcher','RegisteredStatusNotifierItems')
except GLib.Error:
    print('INFO     no running StatusNotifierWatcher'); sys.exit(0)
if not entries: print('INFO     no registered tray items')
for entry in entries[:40]:
    service,sep,tail=entry.partition('/')
    path='/'+tail if sep else '/StatusNotifierItem'
    values={}
    for key in ('Id','IconName','Status'):
        try: values[key]=get(service,path,'org.kde.StatusNotifierItem',key)
        except GLib.Error: values[key]='unavailable'
    # repr keeps embedded control characters escaped; no title or tooltip content.
    print('INFO     SNI '+ ' '.join(f'{k}={str(v)[:180]!r}' for k,v in values.items()))
