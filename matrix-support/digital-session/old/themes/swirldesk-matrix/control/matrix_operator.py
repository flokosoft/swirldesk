#!/usr/bin/env python3
"""MATRIX operator console, GTK3; only alive while its window is open."""
import os
import shutil
import subprocess
import threading
from pathlib import Path
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, Gio, Pango
from telemetry import Sampler

ROOT = Path.home()/'.config/swirldesk'
HERE = Path(__file__).resolve().parent


def script(name):
    return [str(ROOT/'scripts'/name)]


ACTIONS = [
    ('search applications', script('launcher.sh')), ('system monitor', ['kitty', '--class', 'btop-floating', '-e', 'btop']),
    ('network settings', ['nm-connection-editor']), ('toggle VPN', script('wireguard-toggle.sh')),
    ('audio mixer', ['pavucontrol']), ('bluetooth', ['blueman-manager']),
    ('switch theme', script('theme-switcher.sh')), ('visual profile', [str(HERE.parent/'visual/profile.sh')]),
    ('clipboard', script('clipboard.sh')), ('keybindings', script('keybinds-help.sh')),
    ('lock session', ['hyprlock']), ('session menu', script('power-menu.sh')),
]


def label(text, style='', xalign=0):
    w = Gtk.Label(label=text, xalign=xalign)
    if style:
        w.get_style_context().add_class(style)
    return w


def gib(n):
    return f'{n/1024**3:.1f} GiB'


class Operator(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='org.swirldesk.MatrixOperator', flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.window = None
        self.busy = False
        self.sampler = Sampler()
        self.values = {}
        self.meters = {}

    def do_activate(self):
        if self.window is not None:
            self.window.destroy()
            return
        self.window = Gtk.ApplicationWindow(application=self, title='MATRIX OPERATOR')
        self.window.set_default_size(620, 670)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.get_style_context().add_class('matrix')
        self.window.connect('destroy', self.closed)
        self.window.connect('key-press-event', self.keypress)
        provider = Gtk.CssProvider()
        provider.load_from_path(str(HERE/'operator.css'))
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, 800)
        self.provider = provider
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin=12)
        self.window.add(outer)
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        header.get_style_context().add_class('header')
        top = Gtk.Box(spacing=8)
        top.pack_start(label('the matrix / console', 'headline'), True, True, 0)
        close = Gtk.Button(label='×')
        close.connect('clicked', lambda *_: self.window.destroy())
        top.pack_end(close, False, False, 0)
        header.pack_start(top, False, False, 0)
        self.status = label('connecting to local node…', 'muted')
        header.pack_start(self.status, False, False, 0)
        outer.pack_start(header, False, False, 0)
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        # Reserve real layout space; overlay scrollbars can cover right-aligned values.
        scroll.set_overlay_scrolling(False)
        outer.pack_start(scroll, True, True, 0)
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=9)
        content.set_margin_end(12)
        scroll.add(content)
        sysbox = self.section(content, '[ system ]')
        for key, name in [('cpu','CPU LOAD'), ('memory','MEMORY'), ('disk','HOME STORAGE')]:
            row = Gtk.Box(spacing=6)
            row.pack_start(label(name, 'muted'), True, True, 0)
            value = label('—', 'value', 1)
            row.pack_end(value, False, False, 0)
            sysbox.pack_start(row, False, False, 0)
            meter = Gtk.ProgressBar()
            sysbox.pack_start(meter, False, False, 0)
            self.meters[key] = (value, meter)
        self.data_row(sysbox, 'temperature', 'CPU SENSOR')
        self.data_row(sysbox, 'uptime', 'UPTIME')
        links = self.section(content, '[ connection ]')
        for key, name in [('batteries','POWER'), ('network','UPLINK'), ('vpn','WIREGUARD'), ('audio','AUDIO'), ('workspace','ACTIVE WORKSPACE')]:
            self.data_row(links, key, name)
        actions = self.section(content, '[ commands ]')
        grid = Gtk.Grid(column_spacing=6, row_spacing=6, column_homogeneous=True)
        actions.pack_start(grid, False, False, 0)
        for i, (name, argv) in enumerate(ACTIONS):
            b = Gtk.Button(label=name)
            available = os.access(argv[0], os.X_OK) if '/' in argv[0] else bool(shutil.which(argv[0]))
            if argv[0] == 'kitty':
                available = available and bool(shutil.which('btop'))
            b.set_sensitive(available)
            if not available:
                b.set_tooltip_text('Local command unavailable')
            b.connect('clicked', self.launch, argv)
            grid.attach(b, i%2, i//2, 1, 1)
        outer.pack_end(label('local readout · 2s · esc to close', 'muted'), False, False, 0)
        self.window.show_all()
        self.poll()
        self.timer = GLib.timeout_add_seconds(2, self.poll)

    def section(self, parent, title):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.get_style_context().add_class('section')
        box.pack_start(label(title, 'section-title'), False, False, 0)
        parent.pack_start(box, False, False, 0)
        return box

    def data_row(self, parent, key, name):
        row = Gtk.Box(spacing=6)
        row.pack_start(label(name, 'muted'), False, False, 0)
        val = label('—', 'value', 1)
        val.set_ellipsize(Pango.EllipsizeMode.END)
        val.set_max_width_chars(32)
        row.pack_end(val, True, True, 0)
        parent.pack_start(row, False, False, 0)
        self.values[key] = val

    def keypress(self, _widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.window.destroy()
            return True
        return False

    def closed(self, *_):
        self.window = None
        if hasattr(self, 'timer'):
            GLib.source_remove(self.timer)
        self.quit()

    def launch(self, _button, argv):
        try:
            subprocess.Popen(argv, start_new_session=True, stdin=subprocess.DEVNULL)
        except OSError as exc:
            self.status.set_text(f'command failed: {exc.strerror}')
            return
        self.window.destroy()

    def poll(self):
        if not self.busy:
            self.busy = True
            threading.Thread(target=self.worker, daemon=True).start()
        return self.window is not None

    def worker(self):
        try:
            data = self.sampler.sample()
        except Exception:
            data = None
        GLib.idle_add(self.render, data)

    def render(self, d):
        self.busy = False
        if self.window is None:
            return False
        if d is None:
            self.status.set_text('telemetry unavailable · retrying')
            for v, m in self.meters.values():
                v.set_text('—'); m.set_fraction(0)
            for v in self.values.values():
                v.set_text('—'); v.set_tooltip_text(None)
            return False
        self.status.set_text('last sample: ' + d['timestamp'])
        for key, (v, m) in self.meters.items():
            item = d[key]
            pct = item if key == 'cpu' else item['percent'] if item else None
            text = '—' if pct is None else f'{pct:.0f}%'
            if key != 'cpu' and item:
                text += f"  {gib(item['used'])} / {gib(item['total'])}"
            v.set_text(text)
            m.set_fraction(max(0, min(1, pct/100)) if pct is not None else 0)
            ctx = m.get_style_context()
            (ctx.add_class if pct is not None and pct >= 90 else ctx.remove_class)('warning')
        u = d['uptime']
        a, ws = d['audio'], d['workspace']
        vals = {'temperature': f"{d['temperature']:.0f} °C" if d['temperature'] is not None else 'N/A',
                'uptime': f'{u//86400}d {(u//3600)%24:02d}h {(u//60)%60:02d}m' if u is not None else 'N/A',
                'batteries': ' / '.join(f"{p['name']} {p['percent']}% {p['status']}" for p in d['batteries']) or 'N/A',
                'network': 'N/A' if d['network'] is None else ', '.join(d['network']) or 'NO NM LINK',
                'vpn': 'N/A' if d['vpn'] is None else 'ACTIVE' if d['vpn'] else 'INACTIVE',
                'audio': 'N/A' if a is None else f"{a['percent']}%" + (' MUTED' if a['muted'] else ''),
                'workspace': 'N/A' if ws is None else f"{ws['id']}  /  {ws['windows']} windows"}
        for k, text in vals.items():
            self.values[k].set_text(text)
            self.values[k].set_tooltip_text(text)
        return False


if __name__ == '__main__':
    raise SystemExit(Operator().run(None))
