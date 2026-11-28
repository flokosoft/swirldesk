#!/usr/bin/python3
"""MATRIX settings: existing engines own all effect lifecycles and power policy."""
import importlib.util, json, os, shutil, subprocess, sys
from pathlib import Path
HERE=Path(__file__).resolve().parent; THEME=HERE.parent; ROOT=THEME.parents[1]; STATE=ROOT/'state'
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
session=load('matrix_session',THEME/'session/digital/controller.py')
PRESETS={'eco':('off','off',0),'balanced':('on','soft',0),'immersive':('on','classic',180)}
CHOICES={'profile':('clean','code-rain','construct'),'rain':('off','on'),'crt':('off','soft','classic','strong'),'intro':('off','on'),'saver':('off','60','180','300'),'sound':('off','on'),'exit':('off','on')}
LABELS={'profile':'visual profile','rain':'digital rain (code rain / AC only)','crt':'crt phosphor (AC only)','intro':'session intro','saver':'screensaver (seconds / AC only)','sound':'connection sound','exit':'exit animation'}
def read(name): return session.read(STATE/name)
def valid(k,v): return v if v in CHOICES[k] else CHOICES[k][0]
def snapshot():
    p=session.prefs(); return {'profile':valid('profile',read('matrix_visual_profile') or 'code-rain'),'rain':valid('rain',read('matrix_rain_enabled')),'crt':valid('crt',read('matrix_crt_mode')),'saver':str(p['saver']) if p['saver'] else 'off',**{k:'on' if p[k] else 'off' for k in ('intro','sound','exit')}}
def preset_name(s):
    return next((k for k,(r,c,i) in PRESETS.items() if (s['rain'],s['crt'],int(s['saver']) if s['saver']!='off' else 0)==(r,c,i)),'custom')
def require_active():
    if not session.active() or not session.runtime() or not session.wayland_alive(): raise RuntimeError('Activate MATRIX in the current Hyprland session first.')
def run(args,timeout=15):
    p=subprocess.run([str(x) for x in args],capture_output=True,text=True,timeout=timeout)
    if p.returncode: raise RuntimeError((p.stderr or p.stdout or 'command failed').strip())
    return p.stdout.strip()
def change(k,v):
    require_active()
    if k not in CHOICES or v not in CHOICES[k]: raise ValueError('invalid setting')
    if k=='profile': run([THEME/'visual/profile.sh','--quiet','--apply',v])
    elif k=='rain': run([THEME/'visual/rain/ctl.sh',v])
    elif k=='crt': run([THEME/'visual/crt/ctl.sh',v])
    else:
        session.save(k,(0 if v=='off' else int(v)) if k=='saver' else v=='on')
        session.kick(session.runtime())
def apply(values):
    require_active()
    if any(k not in CHOICES or v not in CHOICES[k] for k,v in values.items()): raise ValueError('invalid setting')
    old=snapshot(); changed=[]
    try:
        for k,v in values.items():
            if old[k]!=v: change(k,v); changed.append(k)
    except (OSError,ValueError,RuntimeError,subprocess.SubprocessError) as e:
        # Do not silently roll back unrelated user preferences or overwrite foreign shaders.
        raise RuntimeError(f'{e}\nApplied before error: {", ".join(changed) or "none"}. Read back current settings.') from e
    return snapshot()
def preset(name):
    r,c,i=PRESETS[name]; return apply({'rain':r,'crt':c,'saver':str(i) if i else 'off'})
def status():
    s=snapshot(); return f'performance: {preset_name(s)} | power: '+('AC' if session.on_ac() else 'battery / unknown')+'\n'+ '\n'.join(f'{LABELS[k]}: {v}' for k,v in s.items())
def preview(mode):
    require_active()
    return run([THEME/'session/digital/ctl.sh','preview-intro' if mode=='intro' else 'preview'],timeout=15)
def menu_choice(title,items):
    p=subprocess.run(['fuzzel','--dmenu','--prompt',title+' > ','--width','55','--lines',str(min(12,len(items)))],input='\n'.join(items)+'\n',text=True,capture_output=True)
    return p.stdout.strip() if p.returncode==0 and p.stdout.strip() in items else None
def fallback():
    while True:
        s=snapshot(); items=[f'performance : {preset_name(s)}']+[f'{LABELS[k]} : {s[k]}' for k in CHOICES]+['preview intro','preview screensaver (8s)','master doctor']
        c=menu_choice('the matrix / settings',items)
        if c is None: return 0
        i=items.index(c)
        try:
            if i==0:
                v=menu_choice('performance',list(PRESETS)); v and preset(v)
            elif i<=len(CHOICES):
                k=list(CHOICES)[i-1]; v=menu_choice(LABELS[k],list(CHOICES[k])); v and change(k,v)
            elif c=='master doctor': subprocess.Popen(['kitty','-e','bash','-c','bash "$1"; read -r -p "Enter to close"','_',str(ROOT/'matrix-support/master-doctor.sh')])
            else: preview('intro' if c=='preview intro' else 'saver')
        except (RuntimeError,OSError,subprocess.SubprocessError) as e:
            if shutil.which('notify-send'): subprocess.run(['notify-send','MATRIX settings',str(e)])
def gui():
    import gi
    gi.require_version('Gtk','3.0')
    from gi.repository import Gtk, Gdk, GLib
    import threading
    if not Gtk.init_check(None)[0]: return fallback()
    win=Gtk.Window(title='the matrix / settings'); win.set_default_size(580,620); win.set_border_width(18)
    win.connect('destroy',Gtk.main_quit); win.connect('key-press-event',lambda w,e: (w.destroy() or True) if e.keyval==Gdk.KEY_Escape else False)
    scroll=Gtk.ScrolledWindow(); scroll.set_policy(Gtk.PolicyType.NEVER,Gtk.PolicyType.AUTOMATIC); scroll.set_overlay_scrolling(False); win.add(scroll)
    box=Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=12); box.set_margin_end(12); scroll.add(box)
    title=Gtk.Label(label='the matrix / settings ▏',xalign=0); title.get_style_context().add_class('heading'); box.pack_start(title,False,False,0)
    info=Gtk.Label(xalign=0); info.set_line_wrap(True); box.pack_start(info,False,False,0)
    controls=Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=10); box.pack_start(controls,False,False,0)
    row=Gtk.Box(spacing=8); controls.pack_start(row,False,False,0)
    combos={}
    message=Gtk.Label(xalign=0); message.set_line_wrap(True)
    def refresh_info():
        s=snapshot(); info.set_text(f'v0.9.1 / {preset_name(s)} / '+('AC' if session.on_ac() else 'battery / unknown')+'\nEffects automatically pause on battery.'); return True
    def refresh():
        refresh_info(); s=snapshot()
        for k,c in combos.items(): c.set_active_id(s[k])
    def busy(fn,hide=False):
        controls.set_sensitive(False); message.set_text('working...')
        if hide: win.hide()
        def work():
            try: fn(); msg='settings updated / readback refreshed'
            except Exception as e: msg=str(e)
            def done():
                refresh(); message.set_text(msg); controls.set_sensitive(True)
                if hide: win.show_all()
                return False
            GLib.idle_add(done)
        threading.Thread(target=work,daemon=True).start()
    for name in PRESETS:
        b=Gtk.Button(label=name); b.connect('clicked',lambda _,n=name:busy(lambda:preset(n))); row.pack_start(b,True,True,0)
    for k,options in CHOICES.items():
        r=Gtk.Box(spacing=10); r.pack_start(Gtk.Label(label=LABELS[k],xalign=0),True,True,0); c=Gtk.ComboBoxText(); combos[k]=c
        for v in options: c.append(v,v)
        r.pack_end(c,False,False,0); controls.pack_start(r,False,False,0)
    b=Gtk.Button(label='apply settings'); b.connect('clicked',lambda _:busy(lambda v={k:c.get_active_id() for k,c in combos.items()}:apply(v))); controls.pack_start(b,False,False,0)
    row=Gtk.Box(spacing=8); controls.pack_start(row,False,False,0)
    for name in ('intro','saver'):
        b=Gtk.Button(label='preview '+name); b.connect('clicked',lambda _,n=name:busy(lambda:preview(n),True)); row.pack_start(b,True,True,0)
    b=Gtk.Button(label='master doctor (terminal)'); b.connect('clicked',lambda _:subprocess.Popen(['kitty','-e','bash','-c','bash "$1"; read -r -p "Enter to close"','_',str(ROOT/'matrix-support/master-doctor.sh')])); controls.pack_start(b,False,False,0)
    box.pack_start(message,False,False,0)
    css=Gtk.CssProvider(); css.load_from_data(b'window {background:#030805;color:#b6e4c4;} * {font-family:"JetBrainsMono Nerd Font",monospace;} .heading {color:#42ff88;font-size:19px;} button,combobox button {background-image:none;background-color:#10251a;color:#b6e4c4;border-color:#254b33;} button:hover {background-color:#214d30;}'); Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),css,Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    refresh(); GLib.timeout_add_seconds(3,refresh_info); win.show_all(); Gtk.main(); return 0
def main(args):
    if args==['status']: print(status()); return 0
    require_active()
    if args==['menu']:
        try: return gui()
        except (ImportError,ValueError): return fallback()
    if len(args)==2 and args[0]=='preset' and args[1] in PRESETS: preset(args[1]); print(status()); return 0
    if len(args)==3 and args[0]=='set': change(*args[1:]); print(status()); return 0
    if len(args)==2 and args[0]=='preview' and args[1] in ('intro','saver'): preview(args[1]); return 0
    return 2
if __name__=='__main__':
    try: sys.exit(main(sys.argv[1:]))
    except (RuntimeError,OSError,ValueError,subprocess.SubprocessError) as e: print(e,file=sys.stderr); sys.exit(1)
