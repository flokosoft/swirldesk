#!/usr/bin/env python3
"""SwirlDesk FIELD // live local status panel without terminal redraw flicker."""
from __future__ import annotations

import os
import subprocess
import threading
import time
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk  # type: ignore

ROOT = Path.home() / ".config" / "swirldesk"
STATE = ROOT / "state"
TITLE = "FIELD STATUS"

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
  font-size: 10px;
  color: {C['text']};
}}
window.field-status {{
  background: {C['base']};
  border: 1px solid {C['coyote']};
}}
.header {{
  background: {C['surface2']};
  border-bottom: 1px solid {C['coyote']};
  padding: 9px 11px;
}}
.header-title {{ color: {C['khaki']}; font-weight: 700; font-size: 12px; }}
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


def sh(cmd: str, timeout: float = 1.3) -> str:
    try:
        p = subprocess.run(
            ["bash", "-lc", cmd], text=True,
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            timeout=timeout, check=False,
        )
        return p.stdout.strip()
    except Exception:
        return ""


def read(path: str, default: str = "--") -> str:
    try:
        return Path(path).read_text().strip()
    except Exception:
        return default


def clamp(v: int | float) -> float:
    return max(0.0, min(1.0, float(v) / 100.0))


class DataRow(Gtk.Box):
    def __init__(self, label: str, bar: bool = False):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        l = Gtk.Label(label=label, xalign=0)
        l.get_style_context().add_class("data-label")
        self.value = Gtk.Label(label="--", xalign=1)
        self.value.get_style_context().add_class("data-value")
        head.pack_start(l, True, True, 0)
        head.pack_end(self.value, False, False, 0)
        self.pack_start(head, False, False, 0)
        self.bar = Gtk.ProgressBar()
        self.bar.set_show_text(False)
        self.has_bar = bar
        if bar:
            self.pack_start(self.bar, False, False, 0)

    def set(self, text: str, pct: int | None = None, state: str | None = None) -> None:
        if self.value.get_text() != text:
            self.value.set_text(text)
        ctx = self.value.get_style_context()
        for cls in ("good", "warn", "bad"):
            ctx.remove_class(cls)
        if state:
            ctx.add_class(state)
        if self.has_bar and pct is not None:
            self.bar.set_fraction(clamp(pct))


class FieldStatus(Gtk.Window):
    def __init__(self):
        super().__init__(title=TITLE)
        GLib.set_prgname("swirldesk-field-status")
        self.set_name("field-status")
        self.get_style_context().add_class("field-status")
        self.set_default_size(550, 700)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.connect("key-press-event", self.on_key)
        self.connect("destroy", Gtk.main_quit)
        self._stop = threading.Event()
        self._cpu_prev = self.cpu_counters()

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS.encode())
        screen = Gdk.Screen.get_default()
        if screen:
            Gtk.StyleContext.add_provider_for_screen(
                screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        outer.set_border_width(9)
        self.add(outer)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        header.get_style_context().add_class("header")
        ht = Gtk.Label(label="FIELD // STATUS", xalign=0)
        ht.get_style_context().add_class("header-title")
        self.header_meta = Gtk.Label(label="LOCAL NODE", xalign=1)
        self.header_meta.get_style_context().add_class("header-meta")
        header.pack_start(ht, True, True, 0)
        header.pack_end(self.header_meta, False, False, 0)
        outer.pack_start(header, False, False, 0)

        platform = self.section("NODE")
        self.platform = DataRow("PLATFORM")
        self.profile = DataRow("PROFILE")
        self.clock = DataRow("LOCAL / ZULU")
        platform.pack_start(self.platform, False, False, 0)
        platform.pack_start(self.profile, False, False, 0)
        platform.pack_start(self.clock, False, False, 0)
        outer.pack_start(platform, False, False, 0)

        sysbox = self.section("[01] SYSTEM")
        self.cpu = DataRow("CPU / THERMAL", True)
        self.mem = DataRow("MEMORY", True)
        self.load = DataRow("LOAD")
        self.uptime = DataRow("UPTIME")
        for row in (self.cpu, self.mem, self.load, self.uptime):
            sysbox.pack_start(row, False, False, 0)
        outer.pack_start(sysbox, False, False, 0)

        comms = self.section("[02] COMMS")
        self.link = DataRow("LINK")
        self.addr = DataRow("ADDRESS")
        self.signal = DataRow("SIGNAL", True)
        self.wg = DataRow("WIREGUARD")
        for row in (self.link, self.addr, self.signal, self.wg):
            comms.pack_start(row, False, False, 0)
        outer.pack_start(comms, False, False, 0)

        bottom = Gtk.Grid(column_spacing=8, row_spacing=8)
        bottom.set_column_homogeneous(True)
        pwr = self.section("[03] POWER")
        storage = self.section("[04] STORAGE")
        self.battery = DataRow("BATTERY", True)
        self.eta = DataRow("EST")
        self.root = DataRow("ROOT", True)
        pwr.pack_start(self.battery, False, False, 0)
        pwr.pack_start(self.eta, False, False, 0)
        storage.pack_start(self.root, False, False, 0)
        bottom.attach(pwr, 0, 0, 1, 1)
        bottom.attach(storage, 1, 0, 1, 1)
        outer.pack_start(bottom, False, False, 0)

        footer = Gtk.Label(
            label="LIVE  //  SELECTIVE UPDATE  //  SUPER+I CLOSE  //  ESC CLOSE",
            xalign=0,
        )
        footer.get_style_context().add_class("footer")
        outer.pack_end(footer, False, False, 0)

        self.show_all()
        self.update_clock()
        GLib.timeout_add_seconds(1, self.update_clock)
        threading.Thread(target=self.worker, daemon=True).start()

    def section(self, title: str) -> Gtk.Box:
        b = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        b.get_style_context().add_class("section")
        t = Gtk.Label(label=title, xalign=0)
        t.get_style_context().add_class("section-title")
        b.pack_start(t, False, False, 0)
        return b

    def on_key(self, _w, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def update_clock(self):
        local = time.strftime("%H:%M:%S")
        zulu = time.strftime("%H:%M:%SZ", time.gmtime())
        self.clock.set(f"{local} L  /  {zulu}")
        return True

    @staticmethod
    def cpu_counters() -> tuple[int, int]:
        try:
            p = Path("/proc/stat").read_text().splitlines()[0].split()[1:]
            vals = [int(x) for x in p]
            idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
            total = sum(vals)
            return idle, total
        except Exception:
            return 0, 0

    def cpu_pct(self) -> int:
        now = self.cpu_counters()
        pi, pt = self._cpu_prev
        ni, nt = now
        self._cpu_prev = now
        dt, di = nt - pt, ni - pi
        return int(100 * (dt - di) / dt) if dt > 0 else 0

    @staticmethod
    def max_temp() -> str:
        vals: list[int] = []
        for p in Path("/sys/class/thermal").glob("thermal_zone*/temp"):
            try:
                v = int(p.read_text().strip())
                if 0 < v < 120000:
                    vals.append(v)
            except Exception:
                pass
        return f"{max(vals)//1000}°C" if vals else "--"

    def collect(self) -> dict:
        host = sh("hostname") or "unknown"
        product = read("/sys/devices/virtual/dmi/id/product_name", "Linux node")
        visual = read(str(STATE / "field_wallpaper_profile"), "clean").upper()
        cpu = self.cpu_pct()
        temp = self.max_temp()

        mem_total = int(sh("awk '/MemTotal:/ {print $2}' /proc/meminfo") or "1")
        mem_avail = int(sh("awk '/MemAvailable:/ {print $2}' /proc/meminfo") or "0")
        mem_used = max(0, mem_total - mem_avail)
        mem_pct = int(100 * mem_used / max(1, mem_total))
        mem_text = f"{mem_used/1048576:.1f} / {mem_total/1048576:.1f} GiB"
        load = sh("awk '{print $1\"  \"$2\"  \"$3}' /proc/loadavg") or "--"
        uptime = sh("uptime -p | sed 's/^up //'") or "--"

        iface = sh("nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$3==\"connected\" && ($2==\"wifi\" || $2==\"ethernet\") {print $1; exit}'")
        conn, ip4, sig, ltype = "OFFLINE", "--", None, "--"
        if iface:
            conn = sh(f"nmcli -g GENERAL.CONNECTION device show {iface!r} | head -n1") or "ONLINE"
            ip4 = sh(f"nmcli -g IP4.ADDRESS device show {iface!r} | head -n1 | cut -d/ -f1") or "--"
            ltype = sh(f"nmcli -g GENERAL.TYPE device show {iface!r} | head -n1") or "--"
            if ltype == "wifi":
                s = sh(f"nmcli -t -f IN-USE,SIGNAL device wifi list ifname {iface!r} | awk -F: '$1==\"*\" {{print $2; exit}}'")
                try:
                    sig = int(s)
                except Exception:
                    sig = None
        wg = bool(sh("nmcli -t -f NAME,TYPE connection show --active | grep -E '(:wireguard$|^mikrotik:)' | head -n1"))

        bat = sh("find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' | head -n1")
        cap, bstat, eta = None, "N/A", "--"
        if bat:
            try:
                cap = int(read(f"{bat}/capacity", "0"))
            except Exception:
                cap = None
            bstat = read(f"{bat}/status", "Unknown")
            eta = sh("dev=$(upower -e 2>/dev/null | grep -m1 '/battery_' || true); [ -n \"$dev\" ] && upower -i \"$dev\" 2>/dev/null | awk -F: '/time to empty|time to full/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}'") or "--"

        root_pct_s = sh("df -P / | awk 'NR==2 {gsub(/%/,\"\",$5); print $5}'") or "0"
        try:
            root_pct = int(root_pct_s)
        except Exception:
            root_pct = 0
        root_text = sh("df -hP / | awk 'NR==2 {print $3\" / \"$2}'") or "--"

        return {
            "host": host, "product": product, "visual": visual,
            "cpu": cpu, "temp": temp, "mem_pct": mem_pct, "mem_text": mem_text,
            "load": load, "uptime": uptime,
            "iface": iface, "conn": conn, "ip4": ip4, "sig": sig, "ltype": ltype, "wg": wg,
            "cap": cap, "bstat": bstat, "eta": eta,
            "root_pct": root_pct, "root_text": root_text,
        }

    def worker(self):
        while not self._stop.is_set():
            data = self.collect()
            GLib.idle_add(self.apply, data)
            self._stop.wait(3.0)

    def apply(self, d: dict):
        self.header_meta.set_text(f"NODE {d['host'].upper()} // LOCAL")
        self.platform.set(str(d["product"])[:30])
        self.profile.set(str(d["visual"]))
        self.cpu.set(f"{d['cpu']:02d}%  /  {d['temp']}", d["cpu"], "warn" if d["cpu"] >= 80 else None)
        self.mem.set(d["mem_text"], d["mem_pct"], "warn" if d["mem_pct"] >= 85 else None)
        self.load.set(d["load"])
        self.uptime.set(d["uptime"])
        if d["iface"]:
            self.link.set(f"● ONLINE  //  {d['conn']}  //  {d['iface']}", state="good")
            self.addr.set(d["ip4"])
        else:
            self.link.set("○ OFFLINE", state="warn")
            self.addr.set("--")
        if d["sig"] is None:
            self.signal.set("N/A", 0)
        else:
            self.signal.set(f"{d['sig']}%", d["sig"])
        self.wg.set("● ACTIVE" if d["wg"] else "○ OFF", state="good" if d["wg"] else None)
        if d["cap"] is None:
            self.battery.set("NOT DETECTED", 0)
        else:
            state = "warn" if d["cap"] <= 20 else None
            self.battery.set(f"{d['cap']}%  //  {d['bstat']}", d["cap"], state)
        self.eta.set(d["eta"])
        self.root.set(d["root_text"], d["root_pct"], "warn" if d["root_pct"] >= 85 else None)
        return False

    def do_destroy(self):
        self._stop.set()
        Gtk.Window.do_destroy(self)


if __name__ == "__main__":
    win = FieldStatus()
    Gtk.main()
