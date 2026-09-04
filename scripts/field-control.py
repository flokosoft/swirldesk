#!/usr/bin/env python3
"""SwirlDesk FIELD // compact local control panel.

The panel intentionally exposes only real local state and existing SwirlDesk
commands. It has no network backend and no privileged helper of its own.
"""
from __future__ import annotations

import json
import os
import re
import signal
import subprocess
import sys
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk  # type: ignore

ROOT = Path.home() / ".config" / "swirldesk"
SCRIPTS = ROOT / "scripts"
STATE = ROOT / "state"
TITLE = "FIELD CONTROL"

C = {
    "base": "#0b0d0a",
    "surface": "#11140f",
    "surface2": "#181b15",
    "line": "#35372f",
    "coyote": "#a68a5b",
    "khaki": "#b3a06d",
    "olive": "#84956b",
    "text": "#d9d3c3",
    "muted": "#908a7c",
    "warning": "#c49a52",
    "critical": "#92534a",
}

CSS = f"""
* {{
  font-family: "JetBrains Mono", "DejaVu Sans Mono", monospace;
  font-size: 11px;
  color: {C['text']};
}}
window.field-control {{
  background: {C['base']};
  border: 1px solid {C['coyote']};
}}
.header {{
  background: {C['surface2']};
  border-bottom: 1px solid {C['coyote']};
  padding: 9px 11px;
}}
.header-title {{ color: {C['khaki']}; font-weight: 700; font-size: 13px; }}
.header-meta {{ color: {C['muted']}; font-size: 9px; }}
.section {{
  background: {C['surface']};
  border: 1px solid {C['line']};
  padding: 9px;
}}
.section-title {{ color: {C['coyote']}; font-weight: 700; font-size: 10px; }}
.data-label {{ color: {C['muted']}; font-size: 9px; }}
.data-value {{ color: {C['text']}; font-weight: 600; }}
.good {{ color: {C['olive']}; font-weight: 700; }}
.warn {{ color: {C['warning']}; font-weight: 700; }}
.bad {{ color: {C['critical']}; font-weight: 700; }}
button {{
  background: {C['surface2']};
  border: 1px solid {C['line']};
  border-radius: 1px;
  padding: 6px 8px;
  box-shadow: none;
  text-shadow: none;
  color: {C['text']};
}}
button:hover {{ border-color: {C['coyote']}; background: #1d2019; }}
button:active {{ background: {C['coyote']}; color: {C['base']}; }}
button.profile-active {{
  border-color: {C['khaki']};
  color: {C['khaki']};
  background: #1d1c15;
}}
button.danger:hover {{ border-color: {C['critical']}; color: #d5b5ae; }}
.separator {{ background: {C['line']}; min-height: 1px; }}
.footer {{ color: {C['muted']}; font-size: 9px; padding: 1px 2px; }}
progressbar trough {{
  min-height: 4px;
  background: #20221d;
  border: none;
  border-radius: 0;
}}
progressbar progress {{
  min-height: 4px;
  background: {C['olive']};
  border: none;
  border-radius: 0;
}}
"""


def run(cmd: str, timeout: float = 1.0) -> str:
    try:
        p = subprocess.run(
            ["bash", "-lc", cmd], text=True, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, timeout=timeout, check=False
        )
        return p.stdout.strip()
    except Exception:
        return ""


def spawn(cmd: str) -> None:
    subprocess.Popen(["bash", "-lc", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def read_text(path: Path, default: str = "--") -> str:
    try:
        return path.read_text().strip()
    except Exception:
        return default


class DataRow(Gtk.Box):
    def __init__(self, label: str):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.label = Gtk.Label(label=label, xalign=0)
        self.label.get_style_context().add_class("data-label")
        self.value = Gtk.Label(label="--", xalign=1)
        self.value.get_style_context().add_class("data-value")
        head.pack_start(self.label, True, True, 0)
        head.pack_end(self.value, False, False, 0)
        self.pack_start(head, False, False, 0)
        self.bar = Gtk.ProgressBar()
        self.bar.set_show_text(False)
        self.pack_start(self.bar, False, False, 0)

    def set(self, text: str, fraction: float | None = None, state: str | None = None) -> None:
        self.value.set_text(text)
        ctx = self.value.get_style_context()
        for cls in ("good", "warn", "bad"):
            ctx.remove_class(cls)
        if state:
            ctx.add_class(state)
        if fraction is None:
            self.bar.hide()
        else:
            self.bar.show()
            self.bar.set_fraction(max(0.0, min(1.0, fraction)))


class FieldControl(Gtk.Window):
    def __init__(self):
        super().__init__(title=TITLE)
        GLib.set_prgname("swirldesk-field-control")
        self.set_name("field-control")
        self.get_style_context().add_class("field-control")
        self.set_default_size(590, 760)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.connect("key-press-event", self.on_key)
        self.connect("destroy", Gtk.main_quit)
        self._cpu_prev = self.cpu_counters()
        self.profile_buttons: dict[str, Gtk.Button] = {}

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS.encode())
        screen = Gdk.Screen.get_default()
        if screen:
            Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        outer.set_border_width(9)
        self.add(outer)
        outer.pack_start(self.header(), False, False, 0)

        status_grid = Gtk.Grid(column_spacing=8, row_spacing=8)
        status_grid.set_column_homogeneous(True)
        self.sys_box = self.section("[01] SYSTEM")
        self.comms_box = self.section("[02] COMMS")
        status_grid.attach(self.sys_box, 0, 0, 1, 1)
        status_grid.attach(self.comms_box, 1, 0, 1, 1)
        outer.pack_start(status_grid, False, False, 0)

        self.cpu = DataRow("CPU")
        self.mem = DataRow("MEMORY")
        self.temp = DataRow("THERMAL")
        for row in (self.cpu, self.mem, self.temp): self.sys_box.pack_start(row, False, False, 0)

        self.link = DataRow("LINK")
        self.wg = DataRow("WIREGUARD")
        self.ntf = DataRow("NOTIFY")
        for row in (self.link, self.wg, self.ntf): self.comms_box.pack_start(row, False, False, 0)

        io_grid = Gtk.Grid(column_spacing=8, row_spacing=8)
        io_grid.set_column_homogeneous(True)
        self.audio_box = self.section("[03] I/O")
        self.power_box = self.section("[04] POWER")
        io_grid.attach(self.audio_box, 0, 0, 1, 1)
        io_grid.attach(self.power_box, 1, 0, 1, 1)
        outer.pack_start(io_grid, False, False, 0)

        self.audio = DataRow("AUDIO")
        self.display = DataRow("DISPLAY")
        self.audio_box.pack_start(self.audio, False, False, 0)
        self.audio_box.pack_start(self.display, False, False, 0)
        self.battery = DataRow("BATTERY")
        self.power_box.pack_start(self.battery, False, False, 0)
        self.localclock = DataRow("LOCAL / ZULU")
        self.power_box.pack_start(self.localclock, False, False, 0)

        actions = self.section("[05] CONTROL")
        outer.pack_start(actions, False, False, 0)
        actions.pack_start(self.button_row([
            ("SYS MON", self.open_btop), ("NETWORK", self.open_network),
            ("WG TOGGLE", self.toggle_wg), ("BLUETOOTH", self.open_bt),
        ]), False, False, 0)
        actions.pack_start(self.button_row([
            ("VOL -", lambda *_: self.audio_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")),
            ("MUTE", lambda *_: self.audio_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")),
            ("VOL +", lambda *_: self.audio_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")),
            ("MIXER", lambda *_: spawn("pavucontrol")),
        ]), False, False, 0)
        actions.pack_start(self.button_row([
            ("DISPLAY", self.open_display), ("STATUS", self.open_status),
            ("RUN", lambda *_: spawn("fuzzel")), ("WALLPAPER", self.open_wallpaper),
        ]), False, False, 0)

        visual = self.section("[06] VISUAL PROFILE")
        outer.pack_start(visual, False, False, 0)
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        for profile, title in (("clean", "CLEAN // TOPO"), ("aor1", "AOR1 // GHOST"), ("multicam", "MULTICAM // GHOST")):
            b = Gtk.Button(label=title)
            b.set_hexpand(True)
            b.connect("clicked", self.set_profile, profile)
            self.profile_buttons[profile] = b
            row.pack_start(b, True, True, 0)
        visual.pack_start(row, False, False, 0)

        session = self.section("[07] SESSION")
        outer.pack_start(session, False, False, 0)
        session.pack_start(self.button_row([
            ("LOCK", lambda *_: spawn("hyprlock")),
            ("RESTART UI", lambda *_: spawn(str(SCRIPTS / "restart-ui.sh"))),
            ("THEME", lambda *_: spawn(str(SCRIPTS / "theme-switcher.sh"))),
            ("PWR CONTROL", lambda *_: spawn(str(SCRIPTS / "power-menu.sh")), "danger"),
        ]), False, False, 0)

        footer = Gtk.Label(label="ESC CLOSE  //  REFRESH 2S  //  LOCAL NODE DATA", xalign=0)
        footer.get_style_context().add_class("footer")
        outer.pack_end(footer, False, False, 0)

        self.show_all()
        self.refresh()
        GLib.timeout_add_seconds(2, self.refresh)

    def section(self, title: str) -> Gtk.Box:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.get_style_context().add_class("section")
        lab = Gtk.Label(label=title, xalign=0)
        lab.get_style_context().add_class("section-title")
        box.pack_start(lab, False, False, 0)
        return box

    def header(self) -> Gtk.Box:
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        box.get_style_context().add_class("header")
        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        title = Gtk.Label(label="FIELD // CONTROL", xalign=0)
        title.get_style_context().add_class("header-title")
        self.header_meta = Gtk.Label(label="LOCAL NODE", xalign=0)
        self.header_meta.get_style_context().add_class("header-meta")
        left.pack_start(title, False, False, 0)
        left.pack_start(self.header_meta, False, False, 0)
        close = Gtk.Button(label="X")
        close.set_size_request(34, 32)
        close.connect("clicked", lambda *_: self.destroy())
        box.pack_start(left, True, True, 0)
        box.pack_end(close, False, False, 0)
        return box

    def button_row(self, items):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        for item in items:
            label, callback, *classes = item
            b = Gtk.Button(label=label)
            b.set_hexpand(True)
            for cls in classes: b.get_style_context().add_class(cls)
            b.connect("clicked", callback)
            row.pack_start(b, True, True, 0)
        return row

    def on_key(self, _widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            return True
        return False

    def cpu_counters(self):
        try:
            vals = [int(x) for x in Path("/proc/stat").read_text().splitlines()[0].split()[1:9]]
            idle = vals[3] + vals[4]
            total = sum(vals)
            return total, idle
        except Exception:
            return 0, 0

    def cpu_pct(self) -> int:
        current = self.cpu_counters()
        dt = current[0] - self._cpu_prev[0]
        di = current[1] - self._cpu_prev[1]
        self._cpu_prev = current
        return int(100 * (dt - di) / dt) if dt > 0 else 0

    def mem_pct(self):
        vals = {}
        try:
            for line in Path("/proc/meminfo").read_text().splitlines():
                key, rest = line.split(":", 1)
                vals[key] = int(rest.split()[0])
            total = vals["MemTotal"]
            used = total - vals["MemAvailable"]
            return int(100 * used / total), used / 1048576, total / 1048576
        except Exception:
            return 0, 0.0, 0.0

    def thermal(self):
        temps = []
        for p in Path("/sys/class/thermal").glob("thermal_zone*/temp"):
            try:
                v = int(p.read_text().strip())
                if 0 < v < 120000: temps.append(v / 1000)
            except Exception:
                pass
        return max(temps) if temps else None

    def battery_state(self):
        bats = list(Path("/sys/class/power_supply").glob("BAT*"))
        if not bats: return None, "N/A"
        b = bats[0]
        try: cap = int((b / "capacity").read_text().strip())
        except Exception: cap = None
        return cap, read_text(b / "status", "N/A")

    def network_state(self):
        out = run("nmcli -t -f DEVICE,TYPE,STATE device status", 0.8)
        for line in out.splitlines():
            parts = line.split(":")
            if len(parts) >= 3 and parts[2] == "connected" and parts[1] in ("wifi", "ethernet"):
                dev, typ = parts[0], parts[1]
                name = run(f"nmcli -g GENERAL.CONNECTION device show {dev} | head -n1", 0.8) or typ
                return True, f"{name[:16]} // {dev}"
        return False, "OFFLINE"

    def wg_state(self):
        active = run("nmcli -t -f NAME,TYPE connection show --active", 0.8)
        return any(":wireguard" in l or l.startswith("mikrotik:") for l in active.splitlines())

    def notify_state(self):
        raw = run(str(SCRIPTS / "notification-status.sh"), 0.7)
        try:
            obj = json.loads(raw)
            return obj.get("text", "NTF ?").replace("NTF ", "")
        except Exception:
            return "?"

    def audio_state(self):
        raw = run("wpctl get-volume @DEFAULT_AUDIO_SINK@", 0.7)
        m = re.search(r"Volume:\s+([0-9.]+)", raw)
        pct = int(float(m.group(1)) * 100) if m else 0
        muted = "MUTED" in raw.upper()
        return pct, muted

    def display_state(self):
        raw = run("hyprctl monitors -j", 0.8)
        try:
            mons = json.loads(raw)
            m = next((x for x in mons if x.get("focused")), mons[0] if mons else {})
            return f"{m.get('name','--')} // {m.get('width','--')}x{m.get('height','--')}"
        except Exception:
            return "--"

    def profile(self):
        p = read_text(STATE / "field_wallpaper_profile", "clean")
        return p if p in ("clean", "aor1", "multicam") else "clean"

    def refresh(self):
        cpu = self.cpu_pct()
        mem, used, total = self.mem_pct()
        temp = self.thermal()
        online, link = self.network_state()
        wg = self.wg_state()
        ntf = self.notify_state()
        volume, muted = self.audio_state()
        bat, bstate = self.battery_state()
        display = self.display_state()
        profile = self.profile()
        host = run("hostname", 0.3) or "node"
        local = run("date '+%H:%M L'", 0.3)
        zulu = run("TZ=UTC date '+%H:%MZ'", 0.3)

        self.header_meta.set_text(f"NODE {host.upper()}  //  PROFILE {profile.upper()}  //  {local} / {zulu}")
        self.cpu.set(f"{cpu:02d}%", cpu / 100, "warn" if cpu >= 80 else "good")
        self.mem.set(f"{mem:02d}% // {used:.1f}/{total:.1f}G", mem / 100, "warn" if mem >= 85 else None)
        self.temp.set(f"{temp:.0f}°C" if temp is not None else "--", None, "warn" if temp is not None and temp >= 80 else None)
        self.link.set(link, None, "good" if online else "bad")
        self.wg.set("ACTIVE" if wg else "OFF", None, "good" if wg else None)
        self.ntf.set(ntf, None, "good" if ntf == "ON" else "warn" if ntf == "HOLD" else None)
        self.audio.set("MUTED" if muted else f"{volume:02d}%", volume / 100, "warn" if muted else None)
        self.display.set(display)
        if bat is None:
            self.battery.set("N/A")
        else:
            self.battery.set(f"{bat:02d}% // {bstate}", bat / 100, "warn" if bat <= 20 else "good")
        self.localclock.set(f"{local} // {zulu}")

        for p, btn in self.profile_buttons.items():
            ctx = btn.get_style_context()
            if p == profile: ctx.add_class("profile-active")
            else: ctx.remove_class("profile-active")
        return True

    def schedule_refresh(self, delay_ms=500):
        def once():
            self.refresh()
            return False
        GLib.timeout_add(delay_ms, once)

    def open_btop(self, *_): spawn("kitty --class btop-floating -e btop")
    def open_network(self, *_): spawn("nm-connection-editor")
    def toggle_wg(self, *_): spawn(str(SCRIPTS / "wireguard-toggle.sh")); self.schedule_refresh(700)
    def open_bt(self, *_): spawn("command -v blueman-manager >/dev/null && blueman-manager || notify-send 'FIELD // BT' 'blueman-manager not installed'")
    def audio_cmd(self, cmd): spawn(cmd); self.schedule_refresh(250)
    def open_display(self, *_): spawn("command -v swirl-monitors >/dev/null && swirl-monitors || nwg-displays -m ~/.config/hypr/monitors-nwg.conf")
    def open_status(self, *_): spawn(str(SCRIPTS / "field-status-toggle.sh"))
    def open_wallpaper(self, *_): spawn(str(SCRIPTS / "wallpaper-select.sh"))

    def set_profile(self, _button, profile):
        spawn(f"{SCRIPTS / 'field-wallpaper-profile.sh'} --quiet --apply {profile}")
        self.schedule_refresh(500)


def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    win = FieldControl()
    win.present()
    Gtk.main()


if __name__ == "__main__":
    main()
