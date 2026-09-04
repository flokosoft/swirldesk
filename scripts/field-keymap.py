#!/usr/bin/env python3
"""SwirlDesk FIELD // static, high-signal keymap reference.

This is intentionally a compact reference panel rather than a full parser UI.
The listed bindings mirror SwirlDesk's shipped hypr/conf/keybinds.conf and are
kept grouped by task so the panel remains readable at a glance.
"""
from __future__ import annotations

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, Gtk  # type: ignore

TITLE = "FIELD KEYMAP"

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
}

CSS = f"""
* {{
  font-family: "JetBrains Mono", "DejaVu Sans Mono", monospace;
  font-size: 10px;
  color: {C['text']};
}}
window.field-keymap {{
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
.card {{
  background: {C['surface']};
  border: 1px solid {C['line']};
  padding: 8px 9px;
}}
.card-title {{ color: {C['coyote']}; font-weight: 700; font-size: 10px; padding-bottom: 3px; }}
.key {{ color: {C['khaki']}; font-weight: 700; font-size: 9px; }}
.desc {{ color: {C['text']}; font-size: 9px; }}
.note {{ color: {C['muted']}; font-size: 8px; }}
button {{
  background: {C['surface2']};
  border: 1px solid {C['line']};
  border-radius: 1px;
  padding: 5px 8px;
  box-shadow: none;
  text-shadow: none;
}}
button:hover {{ border-color: {C['coyote']}; }}
.footer {{ color: {C['muted']}; font-size: 8px; padding: 1px 2px; }}
"""

SECTIONS = [
    ("[01] FIELD", [
        ("SUPER + SPACE", "FIELD CONTROL"),
        ("SUPER + I", "FIELD STATUS"),
        ("SUPER + CTRL + P", "FIELD POWER"),
        ("SUPER + SHIFT + F1", "FIELD KEYMAP"),
        ("SUPER + L", "SESSION LOCK"),
    ]),
    ("[02] APPLICATIONS", [
        ("SUPER + ENTER", "TERMINAL"),
        ("SUPER + E", "FILES / THUNAR"),
        ("SUPER + B", "BROWSER / FIREFOX"),
        ("SUPER + C", "CLIPBOARD"),
        ("SUPER + CTRL + ENTER", "APP LAUNCHER"),
    ]),
    ("[03] WINDOWS", [
        ("SUPER + Q", "CLOSE ACTIVE"),
        ("SUPER + F", "FULLSCREEN"),
        ("SUPER + V", "FLOAT / TILE"),
        ("SUPER + ARROWS", "MOVE FOCUS"),
        ("SUPER + SHIFT + ARROWS", "MOVE WINDOW"),
        ("SUPER + LMB / RMB", "MOVE / RESIZE"),
    ]),
    ("[04] WORKSPACES", [
        ("SUPER + 1…0", "SELECT 1…10"),
        ("SUPER + SHIFT + 1…0", "MOVE + FOLLOW"),
        ("SUPER + CTRL + 1…9", "MOVE SILENT"),
    ]),
    ("[05] CAPTURE", [
        ("PRINT", "SELECT AREA"),
        ("SUPER + PRINT", "ACTIVE WINDOW"),
        ("CTRL + PRINT", "FULL SCREEN"),
        ("SHIFT + PRINT", "AREA // 5S"),
        ("SUPER + SHIFT + PRINT", "WINDOW // 5S"),
    ]),
    ("[06] DESKTOP", [
        ("SUPER + W", "WALLPAPER SELECT"),
        ("SUPER + SHIFT + W", "RANDOM WALLPAPER"),
        ("SUPER + SHIFT + T", "THEME SELECT"),
        ("SUPER + SHIFT + R", "RESTART UI"),
        ("SUPER + SHIFT + N", "DISPLAY NAME"),
    ]),
    ("[07] COMMS / SYSTEM", [
        ("SUPER + SHIFT + V", "WIREGUARD TOGGLE"),
        ("SUPER + SHIFT + M", "NOTIFICATIONS"),
        ("SUPER + SHIFT + S", "CONTROL CENTER"),
        ("SUPER + SHIFT + E", "EXIT HYPRLAND"),
    ]),
    ("[08] HARDWARE", [
        ("VOL + / -", "AUDIO LEVEL"),
        ("MUTE / MIC MUTE", "AUDIO TOGGLE"),
        ("BRIGHTNESS + / -", "DISPLAY LEVEL"),
        ("MEDIA PLAY / NEXT / PREV", "PLAYER CONTROL"),
        ("LID SWITCH", "MONITOR PROFILE"),
    ]),
]


class KeyRow(Gtk.Box):
    def __init__(self, key: str, desc: str):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        k = Gtk.Label(label=key, xalign=0)
        k.set_size_request(185, -1)
        k.get_style_context().add_class("key")
        d = Gtk.Label(label=desc, xalign=0)
        d.set_hexpand(True)
        d.get_style_context().add_class("desc")
        self.pack_start(k, False, False, 0)
        self.pack_start(d, True, True, 0)


class KeymapWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title=TITLE)
        self.set_name("field-keymap")
        self.get_style_context().add_class("field-keymap")
        self.set_default_size(860, 720)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.connect("destroy", Gtk.main_quit)
        self.connect("key-press-event", self.on_key)

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
        outer.pack_start(self.header(), False, False, 0)

        grid = Gtk.Grid(column_spacing=8, row_spacing=8)
        grid.set_column_homogeneous(True)
        for idx, (title, rows) in enumerate(SECTIONS):
            grid.attach(self.card(title, rows), idx % 2, idx // 2, 1, 1)
        outer.pack_start(grid, True, True, 0)

        footer = Gtk.Label(
            label="SUPER+SHIFT+F1 CLOSE  //  FIELD REFERENCE  //  HYPRLAND KEYMAP",
            xalign=0,
        )
        footer.get_style_context().add_class("footer")
        outer.pack_end(footer, False, False, 0)
        self.show_all()

    def header(self) -> Gtk.Box:
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        box.get_style_context().add_class("header")
        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        title = Gtk.Label(label="FIELD // KEYMAP", xalign=0)
        title.get_style_context().add_class("header-title")
        meta = Gtk.Label(label="QUICK REFERENCE // DAILY OPERATIONS", xalign=0)
        meta.get_style_context().add_class("header-meta")
        left.pack_start(title, False, False, 0)
        left.pack_start(meta, False, False, 0)
        close = Gtk.Button(label="X")
        close.set_size_request(34, 32)
        close.connect("clicked", lambda *_: self.destroy())
        box.pack_start(left, True, True, 0)
        box.pack_end(close, False, False, 0)
        return box

    @staticmethod
    def card(title: str, rows: list[tuple[str, str]]) -> Gtk.Box:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.get_style_context().add_class("card")
        lab = Gtk.Label(label=title, xalign=0)
        lab.get_style_context().add_class("card-title")
        box.pack_start(lab, False, False, 0)
        for key, desc in rows:
            box.pack_start(KeyRow(key, desc), False, False, 0)
        return box

    def on_key(self, _widget, event):
        if event.keyval in (Gdk.KEY_Escape, Gdk.KEY_F1):
            self.destroy()
            return True
        return False


if __name__ == "__main__":
    win = KeymapWindow()
    win.present()
    Gtk.main()
