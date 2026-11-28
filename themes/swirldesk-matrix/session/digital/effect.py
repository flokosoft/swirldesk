#!/usr/bin/python3
"""Bounded, noninteractive layer surfaces. Not a lock screen."""
import sys, time, signal, os
from pathlib import Path
from controller import active, locked, prefs, on_ac, read, THEME
from policy import Rain, CELL, COLORS

def imports():
    import gi
    gi.require_version('Gtk','3.0'); gi.require_version('GtkLayerShell','0.1'); gi.require_version('PangoCairo','1.0'); gi.require_foreign('cairo')
    import cairo
    from gi.repository import Gtk,Gdk,GLib,GtkLayerShell as Layer,Pango,PangoCairo
    return Gtk,Gdk,GLib,Layer,Pango,PangoCairo,cairo

def run(mode,runtime):
    Gtk,Gdk,GLib,Layer,Pango,PangoCairo,cairo=imports()
    ready=Gtk.init_check()
    if not (ready[0] if isinstance(ready,tuple) else ready) or not Layer.is_supported(): raise RuntimeError('No supported Wayland layer shell')
    display=Gdk.Display.get_default(); start=time.monotonic(); last=start; surfaces={}; cache={}; stopping=False
    if not display: raise RuntimeError('No display')
    lines=('wake up...','connecting to local node...','digital stream / initialized','the matrix has you.','follow the white rabbit. ▏') if mode=='intro' else ('disconnecting local session...','closing digital stream...','connection terminated. ▏')
    duration={'intro':5,'exit':2.5,'preview':8}.get(mode,420)
    def text(cr,s,x,y,size,color):
        cr.set_source_rgb(*color); l=PangoCairo.create_layout(cr); l.set_font_description(Pango.FontDescription.from_string(f'JetBrainsMono Nerd Font {size}')); l.set_text(s,-1); cr.move_to(x,y); PangoCairo.show_layout(cr,l)
    def glyph(ch,shade,scale):
        key=(ch,shade,scale)
        if key not in cache:
            s=cairo.ImageSurface(cairo.FORMAT_ARGB32,CELL*scale,CELL*scale); s.set_device_scale(scale,scale); c=cairo.Context(s); text(c,ch,3,0,12,COLORS[shade]); cache[key]=s
        return cache[key]
    def draw(area,cr,sim):
        w,h=area.get_allocated_width(),area.get_allocated_height(); cr.set_source_rgb(.008,.025,.014); cr.paint()
        if mode in ('saver','preview'):
            if sim[0] is None or (sim[0].width,sim[0].height)!=(w,h): sim[0]=Rain(w,h)
            scale=max(1,area.get_scale_factor())
            for x,y,ch,shade in sim[0].visible():
                cr.set_source_surface(glyph(ch,shade,scale),x,y); cr.rectangle(x,y,CELL,CELL); cr.fill()
            text(cr,'the matrix / idle visualization',20,h-42,10,(.48,.75,.56))
        else:
            count=int((time.monotonic()-start)*43); x=max(20,w*.12); y=max(20,h*.3)
            for i,line in enumerate(lines):
                if count<=0: break
                text(cr,line[:count],x,y+i*36,16,(.26,1,.53)); count-=len(line)+7
        return True
    def make(m):
        win=Gtk.Window(type=Gtk.WindowType.TOPLEVEL); Layer.init_for_window(win); Layer.set_namespace(win,'swirldesk-matrix-session-effect'); Layer.set_layer(win,Layer.Layer.OVERLAY); Layer.set_monitor(win,m); Layer.set_keyboard_mode(win,Layer.KeyboardMode.NONE); Layer.set_exclusive_zone(win,-1)
        for edge in (Layer.Edge.TOP,Layer.Edge.BOTTOM,Layer.Edge.LEFT,Layer.Edge.RIGHT): Layer.set_anchor(win,edge,True)
        win.set_decorated(False); win.set_accept_focus(False); win.set_focus_on_map(False)
        def passthrough(widget): widget.get_window().input_shape_combine_region(cairo.Region(),0,0)
        win.connect('realize',passthrough); area=Gtk.DrawingArea(); sim=[None]; area.connect('draw',draw,sim); win.add(area)
        win.realize(); passthrough(win); win.show_all(); passthrough(win); return win,area,sim
    def stop(*_):
        nonlocal stopping
        if not stopping:
            stopping=True
            for win,_,_ in list(surfaces.values()): win.destroy()
            surfaces.clear(); Gtk.main_quit()
        return False
    def guard():
        if not active() or time.monotonic()-start>=duration: return stop()
        if locked(): return stop()
        if mode=='saver' and (not on_ac() or not prefs()['saver'] or not read(runtime/'token') or read(runtime/'idle')!=read(runtime/'token')): return stop()
        monitors={display.get_monitor(i) for i in range(display.get_n_monitors())}; monitors.discard(None)
        for m in set(surfaces)-monitors: surfaces.pop(m)[0].destroy()
        for m in monitors-set(surfaces): surfaces[m]=make(m)
        return True
    def tick():
        nonlocal last
        now=time.monotonic(); dt=now-last; last=now
        for _,area,sim in list(surfaces.values()):
            if sim[0]: sim[0].step(dt)
            area.queue_draw()
        return True
    def safe_guard():
        try: return guard()
        except Exception as exc: print(exc,file=sys.stderr); stop(); return False
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT,signal.SIGTERM,stop); GLib.unix_signal_add(GLib.PRIORITY_DEFAULT,signal.SIGINT,stop)
    GLib.idle_add(lambda: (safe_guard(),False)[1]); GLib.timeout_add(200,safe_guard); GLib.timeout_add(100,tick); Gtk.main()
if __name__=='__main__':
    try:
        if sys.argv[1]=='--check': imports(); print('OK GTK3 / GtkLayerShell / Cairo / Pango')
        else: run(sys.argv[1],Path(sys.argv[2]))
    except Exception as exc:
        print(f'MATRIX session effect: {exc}',file=sys.stderr)
        if len(sys.argv)>2 and sys.argv[1]=='saver': (Path(sys.argv[2])/'saver-failed').touch()
        sys.exit(1)
