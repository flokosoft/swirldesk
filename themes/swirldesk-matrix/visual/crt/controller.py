#!/usr/bin/env python3
"""MATRIX CRT: opt-in, AC-only, runtime Hyprland shader. No compositor config edits."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
POWER = Path('/sys/class/power_supply')
MODES = ('off', 'soft', 'classic', 'strong')
OPTION = 'decoration:screen_shader'
# The legacy Hyprland config API uses this sentinel for an unset string.
EMPTY = {'', '[[EMPTY]]', '[[Empty]]', '<empty>'}


def read(path):
    try: return path.read_text().strip()
    except (OSError, UnicodeError): return ''


def preference(root=ROOT):
    v = read(root/'state/matrix_crt_mode')
    return v if v in MODES else 'off'


def save(mode, root=ROOT):
    if mode not in MODES: raise ValueError(mode)
    state = root/'state'; state.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=state, prefix='.crt-', delete=False) as f:
        f.write(mode+'\n'); name=f.name
    os.replace(name, state/'matrix_crt_mode')


def matrix_active(root=ROOT):
    state = root/'state'
    try:
        return (read(state/'current_theme_name') == 'swirldesk-matrix' and
                (state/'current_theme').resolve(strict=True) == (root/'themes/swirldesk-matrix').resolve(strict=True))
    except (OSError, RuntimeError): return False


def on_ac(power=POWER):
    try: devices = list(power.iterdir())
    except OSError: return False
    return any((read(d/'type') in ('Mains','Wireless') or read(d/'type').startswith('USB'))
               and read(d/'scope') != 'Device' and read(d/'online') == '1' for d in devices)


def run(args):
    p = subprocess.run(['hyprctl', *args], capture_output=True, text=True, timeout=3)
    if p.returncode: raise RuntimeError(p.stderr.strip() or p.stdout.strip() or 'hyprctl failed')
    return p.stdout.strip()


def current():
    value = json.loads(run(['-j','getoption',OPTION]))['str']
    if not isinstance(value, str): raise ValueError('invalid shader readback')
    return value.strip()


def set_shader(path):
    # Legacy Hyprland uses [[EMPTY]] for a cleared string.
    result=run(['keyword',OPTION,path or '[[EMPTY]]'])
    if result.lower() != 'ok': raise RuntimeError(result or 'no acknowledgement')
    actual=current()
    if not (actual == path if path else actual in EMPTY):
        raise RuntimeError('shader readback differs after keyword')


def paths(here=HERE): return {str(here/(m+'.frag')) for m in MODES if m!='off'}


def decision(active, mode, ac, actual, here=HERE):
    """Return desired write or None; never replace any unrelated shader."""
    owned = actual in paths(here)
    if not active or mode == 'off' or not ac:
        return ('','inactive' if not active else 'off' if mode=='off' else 'battery / paused') if owned else (None,'inactive' if not active else 'off' if mode=='off' else 'battery / paused')
    if actual not in EMPTY and not owned: return None,'foreign shader / untouched'
    desired = str(here/(mode+'.frag'))
    if not Path(desired).is_file(): return ('' if owned else None),'shader file missing'
    return (desired if actual != desired else None), 'active / '+mode


def runtime():
    sig=os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'); display=os.environ.get('WAYLAND_DISPLAY'); base=os.environ.get('XDG_RUNTIME_DIR')
    if not (sig and display and base and Path(base).is_dir()): raise RuntimeError('no Hyprland Wayland session')
    path=Path(base)/('swirldesk-matrix-crt-'+hashlib.sha256((sig+'\n'+display).encode()).hexdigest()[:24])
    path.mkdir(mode=0o700,exist_ok=True)
    return path


def reconcile(active,mode,ac):
    actual=current()
    target,status=decision(active,mode,ac,actual)
    if target is not None: set_shader(target)
    return status


def clear_owned():
    if current() in paths(): set_shader('')


def watch():
    r=runtime()
    with (r/'lock').open('a') as lock:
        try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError: return 0
        stop=False
        def halt(*_):
            nonlocal stop
            stop=True
        signal.signal(signal.SIGTERM,halt); signal.signal(signal.SIGINT,halt)
        try:
            failures=0
            while not stop:
                active=matrix_active(); mode=preference()
                try:
                    status=reconcile(active,mode,on_ac())
                    (r/'status').write_text(status+'\n'); failures=0
                except (OSError,RuntimeError,ValueError,KeyError,subprocess.SubprocessError) as e:
                    (r/'status').write_text('error / '+str(e)+'\n'); failures+=1
                if not active or mode=='off' or failures>=3: break
                time.sleep(1)
        finally:
            try: clear_owned()
            except (OSError,RuntimeError,ValueError,KeyError,subprocess.SubprocessError): pass
        return 0


def kick():
    if not matrix_active() or preference()=='off': return
    r=runtime()
    with (r/'lock').open('a') as lock:
        try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError: return
        prev=read(r/'attempt')
        if prev.isdigit() and 0<=time.time()-int(prev)<5: return
        (r/'attempt').write_text(str(int(time.time())))
        with (r/'log').open('w') as log:
            subprocess.Popen([sys.executable,str(HERE/'controller.py'),'watch'],stdin=subprocess.DEVNULL,stdout=log,stderr=log,start_new_session=True)


def status():
    print('CRT preference: '+preference())
    print('External power: '+('AC' if on_ac() else 'battery / unknown'))
    r=runtime(); actual=current()
    print('Screen shader: '+('none' if actual in EMPTY else actual))
    print('Worker: '+(read(r/'status') or 'not started'))


def menu():
    entries={'off':'off     / digital (no effect)','soft':'soft    / subtle scanlines','classic':'classic / phosphor terminal','strong':'strong  / pronounced scanlines'}
    p=subprocess.run(['fuzzel','--dmenu','--prompt','CRT ['+preference()+'] > ','--width','48','--lines','4'],input='\n'.join(entries.values())+'\n',text=True,capture_output=True)
    if p.returncode: return 0
    mode=next((k for k,v in entries.items() if v==p.stdout.strip()),None)
    if mode: select(mode)
    return 0


def select(mode):
    if mode!='off':
        if not matrix_active(): raise RuntimeError('activate MATRIX first')
        runtime(); current() # Validate API before saving preference.
    save(mode)
    if mode=='off':
        try:
            r=runtime()
            with (r/'lock').open('a') as lock:
                try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
                except BlockingIOError: return # Worker clears within next tick.
                clear_owned(); (r/'status').write_text('off\n')
        except RuntimeError as e:
            if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'): raise
    else: kick()


def main():
    cmd=sys.argv[1] if len(sys.argv)==2 else 'menu' if len(sys.argv)==1 else ''
    try:
        if cmd in MODES: select(cmd)
        elif cmd=='menu': return menu()
        elif cmd=='watch': return watch()
        elif cmd=='kick':
            if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'): kick()
        elif cmd=='status': status()
        else: print('Usage: ctl.sh off|soft|classic|strong|menu|status|kick'); return 2
        return 0
    except (OSError,RuntimeError,ValueError,KeyError,subprocess.SubprocessError) as e:
        print('CRT: '+str(e),file=sys.stderr); return 1

if __name__=='__main__': sys.exit(main())
