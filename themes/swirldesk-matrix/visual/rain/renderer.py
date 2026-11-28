#!/usr/bin/python3
"""Local, input-transparent GTK3 layer surface; static swaybg stays underneath."""
import os, sys, time, signal
from pathlib import Path
from policy import Rain, CELL, FPS, COLORS, eligible, on_ac

def imports():
    import gi
    gi.require_version('Gtk','3.0')
    gi.require_version('GtkLayerShell','0.1')
    gi.require_version('PangoCairo','1.0')
    gi.require_foreign('cairo')
    import cairo
    from gi.repository import Gtk, Gdk, GLib, GtkLayerShell as Layer, Pango, PangoCairo
    return Gtk,Gdk,GLib,Layer,Pango,PangoCairo,cairo

if '--check' in sys.argv:
    try: imports()
    except Exception as exc:
        print(f'MISSING GTK layer-shell/Cairo: {exc}'); sys.exit(1)
    print('OK GTK3 / GtkLayerShell / Cairo / Pango'); sys.exit(0)

ROOT=Path(__file__).resolve().parents[4]
STATUS=Path(sys.argv[1])

def state(value):
    tmp=STATUS.with_suffix('.tmp'); tmp.write_text(value+'\n'); tmp.replace(STATUS)

def run():
    Gtk,Gdk,GLib,Layer,Pango,PangoCairo,cairo=imports()
    ready=Gtk.init_check()
    if not (ready[0] if isinstance(ready,tuple) else ready) or not Layer.is_supported(): raise RuntimeError('No supported Wayland layer-shell session')
    display=Gdk.Display.get_default()
    if not display: raise RuntimeError('No display')
    surfaces={}; timer=0; last=time.monotonic(); cache={}; stopping=False
    def glyph(char, shade, scale):
        key=(char,shade,scale)
        if key not in cache:
            s=cairo.ImageSurface(cairo.FORMAT_ARGB32,CELL*scale,CELL*scale)
            s.set_device_scale(scale,scale)
            c=cairo.Context(s); c.set_source_rgb(*COLORS[shade]); layout=PangoCairo.create_layout(c)
            layout.set_font_description(Pango.FontDescription.from_string('JetBrainsMono Nerd Font 12'))
            layout.set_text(char,-1); c.move_to(3,0); PangoCairo.show_layout(c,layout); cache[key]=s
        return cache[key]
    def draw(area,cr,sim):
        w=area.get_allocated_width(); h=area.get_allocated_height()
        cr.set_source_rgb(.008,.025,.014); cr.paint()
        if sim[0] is None or (sim[0].width,sim[0].height)!=(w,h): sim[0]=Rain(w,h)
        scale=max(1,area.get_scale_factor())
        for x,y,ch,shade in sim[0].visible():
            cr.set_source_surface(glyph(ch,shade,scale),x,y); cr.rectangle(x,y,CELL,CELL); cr.fill()
        return True
    def make(monitor):
        win=Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
        Layer.init_for_window(win); Layer.set_namespace(win,'swirldesk-matrix-rain')
        Layer.set_layer(win,Layer.Layer.BOTTOM); Layer.set_monitor(win,monitor)
        Layer.set_keyboard_mode(win,Layer.KeyboardMode.NONE); Layer.set_exclusive_zone(win,-1)
        for edge in (Layer.Edge.TOP,Layer.Edge.BOTTOM,Layer.Edge.LEFT,Layer.Edge.RIGHT): Layer.set_anchor(win,edge,True)
        win.set_accept_focus(False); win.set_focus_on_map(False); win.set_decorated(False)
        def passthrough(widget): widget.get_window().input_shape_combine_region(cairo.Region(),0,0)
        win.connect('realize',passthrough)
        area=Gtk.DrawingArea(); sim=[None]; area.connect('draw',draw,sim); win.add(area)
        try:
            win.realize(); passthrough(win); win.show_all(); passthrough(win)
        except Exception:
            win.destroy(); raise
        return win,area,sim
    def tick():
        nonlocal last
        now=time.monotonic(); dt=now-last; last=now
        for win,area,sim in list(surfaces.values()):
            if sim[0]: sim[0].step(dt)
            area.queue_draw()
        return True
    def clear():
        nonlocal timer
        if timer: GLib.source_remove(timer); timer=0
        for win,_,_ in list(surfaces.values()): win.destroy()
        surfaces.clear(); cache.clear()
    def stop(*args):
        nonlocal stopping
        if not stopping:
            stopping=True; clear(); state('inactive'); Gtk.main_quit()
        return False
    def poll(*args):
        nonlocal timer,last
        try:
            if not eligible(ROOT): return stop()
            if not on_ac():
                if surfaces: clear()
                state('battery / AC not confirmed'); return True
            monitors={display.get_monitor(i) for i in range(display.get_n_monitors())}
            monitors.discard(None)
            for m in set(surfaces)-monitors: surfaces.pop(m)[0].destroy()
            for m in monitors-set(surfaces): surfaces[m]=make(m)
            if surfaces and not timer: last=time.monotonic(); timer=GLib.timeout_add(round(1000/FPS),tick)
            if not surfaces and timer: GLib.source_remove(timer); timer=0
            state('live' if surfaces else 'waiting for output'); return True
        except Exception as exc:
            print(f'MATRIX rain: {exc}',file=sys.stderr); clear(); state('error'); Gtk.main_quit(); return False
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT,signal.SIGTERM,stop)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT,signal.SIGINT,stop)
    # First poll inside main loop; no unguarded surface on startup.
    GLib.idle_add(lambda: (poll(),False)[1]); GLib.timeout_add(1000,poll)
    Gtk.main(); clear()

try: run()
except Exception as exc:
    print(f'MATRIX rain: {exc}',file=sys.stderr); state('error'); sys.exit(1)
