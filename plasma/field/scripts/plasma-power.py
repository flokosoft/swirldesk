#!/usr/bin/env python3
from __future__ import annotations
import os
import shutil
import subprocess
import time
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk  # type: ignore

C = {
    "base": "#0b0d0a", "surface": "#11140f", "surface2": "#181b15",
    "line": "#35372f", "coyote": "#a68a5b", "khaki": "#b3a06d",
    "olive": "#66705b", "text": "#d9d3c3", "muted": "#908a7c",
    "warning": "#c49a52", "critical": "#92534a"
}
CSS = f"""
* {{ font-family: 'JetBrains Mono','DejaVu Sans Mono',monospace; font-size: 11px; color: {C['text']}; }}
window.field-power {{ background: {C['base']}; border: 1px solid {C['coyote']}; }}
.header {{ background: {C['surface2']}; border-bottom: 1px solid {C['coyote']}; padding: 9px 11px; }}
.header-title {{ color: {C['khaki']}; font-weight: 700; font-size: 13px; }}
.meta,.footer {{ color: {C['muted']}; font-size: 9px; }}
.status {{ background: {C['surface']}; border: 1px solid {C['line']}; padding: 8px 10px; }}
.status-value {{ color: {C['olive']}; font-weight: 700; }}
button {{ background: {C['surface2']}; border: 1px solid {C['line']}; border-radius: 1px; padding: 9px 10px; box-shadow:none; text-shadow:none; }}
button:hover {{ border-color: {C['coyote']}; background: #1d2019; }}
button:active {{ background: {C['coyote']}; color: {C['base']}; }}
button.danger:hover {{ border-color: {C['critical']}; color: #d5b5ae; }}
.confirm {{ background:#17130f; border:1px solid {C['warning']}; padding:9px; }}
.confirm-title {{ color:{C['warning']}; font-weight:700; }}
"""

def qdbus_bin() -> str | None:
    for name in ("qdbus6", "qdbus-qt6", "qdbus"):
        p = shutil.which(name)
        if p:
            return p
    return None

def spawn(argv: list[str]) -> None:
    subprocess.Popen(argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def plasma_call(service: str, path: str, method: str) -> bool:
    q = qdbus_bin()
    if not q:
        return False
    try:
        subprocess.Popen([q, service, path, method], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception:
        return False

def read(path: Path, default="--") -> str:
    try: return path.read_text().strip()
    except Exception: return default

class FieldPower(Gtk.Window):
    def __init__(self):
        super().__init__(title="FIELD POWER")
        GLib.set_prgname("swirldesk-field-plasma-power")
        self.get_style_context().add_class("field-power")
        self.set_default_size(450, 500)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER_ALWAYS)
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)
        self.connect("key-press-event", self.on_key)
        self.connect("destroy", Gtk.main_quit)

        provider = Gtk.CssProvider(); provider.load_from_data(CSS.encode())
        screen = Gdk.Screen.get_default()
        if screen: Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self.outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8); self.outer.set_border_width(9); self.add(self.outer)
        self.outer.pack_start(self.header(), False, False, 0)
        self.outer.pack_start(self.status_box(), False, False, 0)
        actions = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6); self.outer.pack_start(actions, False, False, 0)
        self.actions = actions
        self.add_action("01 // LOCK", "secure Plasma session", "lock")
        self.add_action("02 // SUSPEND", "sleep / retain session", "suspend")
        self.add_action("03 // LOGOUT", "end Plasma session", "logout", True)
        self.add_action("04 // REBOOT", "restart local node", "reboot", True)
        self.add_action("05 // SHUTDOWN", "power off local node", "shutdown", True)

        self.confirm_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=7); self.confirm_box.get_style_context().add_class("confirm")
        self.confirm_label = Gtk.Label(label="", xalign=0); self.confirm_label.get_style_context().add_class("confirm-title")
        self.confirm_box.pack_start(self.confirm_label, False, False, 0)
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.confirm_btn = Gtk.Button(label="CONFIRM"); self.confirm_btn.get_style_context().add_class("danger"); self.confirm_btn.connect("clicked", self.confirm_action)
        cancel = Gtk.Button(label="CANCEL"); cancel.connect("clicked", self.cancel_confirm)
        row.pack_start(self.confirm_btn, True, True, 0); row.pack_start(cancel, True, True, 0); self.confirm_box.pack_start(row, False, False, 0)
        self.outer.pack_start(self.confirm_box, False, False, 0)
        footer = Gtk.Label(label="ESC CLOSE // PLASMA SESSION CONTROL", xalign=0); footer.get_style_context().add_class("footer"); self.outer.pack_end(footer, False, False, 0)
        self.pending = None
        self.show_all(); self.confirm_box.hide()
        GLib.idle_add(self.force_center)
        GLib.timeout_add(180, self.force_center)
        GLib.timeout_add_seconds(5, self.refresh_status)

    def force_center(self):
        try:
            display = Gdk.Display.get_default()
            monitor = display.get_primary_monitor() if display else None
            if monitor is None and display and display.get_n_monitors() > 0:
                monitor = display.get_monitor(0)
            if monitor is not None:
                geo = monitor.get_geometry()
                w, h = self.get_size()
                self.move(geo.x + max(0, (geo.width - w)//2), geo.y + max(0, (geo.height - h)//2))
        except Exception:
            pass
        return False

    def header(self):
        box=Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8); box.get_style_context().add_class("header")
        left=Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        title=Gtk.Label(label="FIELD // PWR", xalign=0); title.get_style_context().add_class("header-title")
        host=subprocess.run(["hostname"], text=True, capture_output=True).stdout.strip().upper() or "NODE"
        meta=Gtk.Label(label=f"NODE {host} // PLASMA SESSION", xalign=0); meta.get_style_context().add_class("meta")
        left.pack_start(title,False,False,0); left.pack_start(meta,False,False,0)
        close=Gtk.Button(label="X"); close.set_size_request(34,32); close.connect("clicked", lambda *_: self.destroy())
        box.pack_start(left,True,True,0); box.pack_end(close,False,False,0); return box

    def status_box(self):
        box=Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL,spacing=12); box.get_style_context().add_class("status")
        self.battery=Gtk.Label(label="BAT --",xalign=0); self.battery.get_style_context().add_class("status-value")
        self.power=Gtk.Label(label="PWR --",xalign=0); self.power.get_style_context().add_class("status-value")
        self.clock=Gtk.Label(label=time.strftime("%H:%M L"),xalign=1); self.clock.get_style_context().add_class("meta")
        box.pack_start(self.battery,False,False,0); box.pack_start(self.power,False,False,0); box.pack_end(self.clock,True,True,0); self.refresh_status(); return box

    def refresh_status(self):
        bats=list(Path("/sys/class/power_supply").glob("BAT*"))
        if bats:
            self.battery.set_text(f"BAT {read(bats[0]/'capacity')}%")
            self.power.set_text(f"PWR {read(bats[0]/'status').upper()[:12]}")
        else:
            self.battery.set_text("BAT N/A"); self.power.set_text("PWR AC/NODE")
        self.clock.set_text(time.strftime("%H:%M L")); return True

    def add_action(self,title,subtitle,action,danger=False):
        b=Gtk.Button();
        if danger: b.get_style_context().add_class("danger")
        inner=Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=1)
        a=Gtk.Label(label=title,xalign=0); a.set_markup(f"<b>{title}</b>")
        s=Gtk.Label(label=subtitle,xalign=0); s.get_style_context().add_class("meta")
        inner.pack_start(a,False,False,0); inner.pack_start(s,False,False,0); b.add(inner); b.connect("clicked",self.action_clicked,action); self.actions.pack_start(b,False,False,0)

    def action_clicked(self,_button,action):
        if action == "lock":
            self.destroy()
            if not plasma_call("org.kde.screensaver","/ScreenSaver","Lock"): spawn(["loginctl","lock-session"])
        elif action == "suspend": self.destroy(); spawn(["systemctl","suspend"])
        else:
            self.pending=action; self.confirm_label.set_text(f"PWR CHECK // CONFIRM {action.upper()}"); self.confirm_btn.set_label(f"CONFIRM // {action.upper()}"); self.confirm_box.show_all()

    def cancel_confirm(self,*_): self.pending=None; self.confirm_box.hide()
    def confirm_action(self,*_):
        action=self.pending; self.pending=None
        if not action: self.confirm_box.hide(); return
        self.destroy()
        if action == "logout":
            if not plasma_call("org.kde.Shutdown","/Shutdown","org.kde.Shutdown.logout"): spawn(["loginctl","terminate-session",os.environ.get("XDG_SESSION_ID","")])
        elif action == "reboot":
            if not plasma_call("org.kde.Shutdown","/Shutdown","org.kde.Shutdown.logoutAndReboot"): spawn(["systemctl","reboot"])
        elif action == "shutdown":
            if not plasma_call("org.kde.Shutdown","/Shutdown","org.kde.Shutdown.logoutAndShutdown"): spawn(["systemctl","poweroff"])

    def on_key(self,_w,event):
        if event.keyval == Gdk.KEY_Escape:
            if self.pending: self.cancel_confirm()
            else: self.destroy()
            return True
        return False

if __name__ == "__main__":
    FieldPower(); Gtk.main()
