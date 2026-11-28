#!/usr/bin/python3
"""Per-compositor session effects; never owns authentication or power policy."""
import fcntl, hashlib, json, os, shlex, shutil, signal, subprocess, sys, tempfile, time
from pathlib import Path
HERE=Path(__file__).resolve().parent
THEME=HERE.parents[1]; ROOT=THEME.parents[1]; STATE=ROOT/'state'
sys.path.insert(0,str(THEME/'visual/rain'))
from policy import on_ac
DEFAULT={'intro':True,'saver':0,'sound':False,'exit':True}
PREF=STATE/'matrix_digital_session.json'

def read(p):
    try: return p.read_text().strip()
    except (OSError, UnicodeError): return ''
def prefs():
    try: v=json.loads(read(PREF))
    except (ValueError,TypeError): v={}
    if not isinstance(v,dict): v={}
    return {k:(v[k] if k in v and type(v[k]) is type(d) and (k!='saver' or v[k] in (0,60,180,300)) else d) for k,d in DEFAULT.items()}
def save(k,v):
    STATE.mkdir(parents=True,exist_ok=True)
    with (STATE/'matrix_digital_session.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX); p=prefs(); p[k]=v
        fd,n=tempfile.mkstemp(dir=STATE,prefix='.matrix-session-')
        with os.fdopen(fd,'w') as f: json.dump(p,f); f.write('\n')
        os.replace(n,PREF)
def active():
    return (read(STATE/'current_theme_name')=='swirldesk-matrix' and (STATE/'current_theme').resolve()==THEME.resolve() and 'session/digital/profile-status.sh' in read(THEME/'waybar/config'))
def runtime():
    sig=os.environ.get('HYPRLAND_INSTANCE_SIGNATURE',''); way=os.environ.get('WAYLAND_DISPLAY',''); r=os.environ.get('XDG_RUNTIME_DIR','')
    if not sig or not way or not r or not Path(r).is_dir(): return None
    p=Path(r)/('swirldesk-matrix-session-'+hashlib.sha256((sig+'\n'+way).encode()).hexdigest()[:24]); p.mkdir(mode=0o700,exist_ok=True); return p
def wayland_alive():
    name=os.environ.get('WAYLAND_DISPLAY',''); base=os.environ.get('XDG_RUNTIME_DIR','')
    return bool(name and base and (Path(base)/name).is_socket())
def call(args,**kw): return subprocess.run(args,stdin=subprocess.DEVNULL,timeout=kw.pop('timeout',4),**kw)
def locked():
    # Conservative: don't draw above a known lock screen. Real session lock always remains independent.
    try: return call(['pgrep','-u',str(os.getuid()),'-x','hyprlock'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0
    except (OSError,subprocess.TimeoutExpired): return True

def stop(p):
    if p and p.poll() is None:
        p.terminate()
        try: p.wait(timeout=1)
        except subprocess.TimeoutExpired: p.kill(); p.wait()
def spawn_effect(mode,run):
    return subprocess.Popen(['/usr/bin/python3',str(HERE/'effect.py'),mode,str(run)],stdin=subprocess.DEVNULL,env={**os.environ,'GDK_BACKEND':'wayland'})
def play():
    if prefs()['sound'] and shutil.which('paplay'):
        try: call(['paplay','--volume=12000',str(HERE/'connect.wav')],timeout=2,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        except (OSError,subprocess.TimeoutExpired): pass

def idle_command(seconds,run,token):
    cmd=shlex.join(['/usr/bin/python3',str(HERE/'controller.py')])
    # -C /dev/null avoids reading a user's existing swayidle config.
    return ['swayidle','-C','/dev/null','-w','timeout',str(seconds),cmd+' idle-on '+token,'resume',cmd+' idle-off '+token]
def worker(run):
    lock=(run/'worker.lock').open('a')
    try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    except BlockingIOError: return 0
    running=True; idle=None; effect=None; last=None; token=''; failed=False; shown=False
    def shutdown(*_):
        nonlocal running; running=False
    signal.signal(signal.SIGTERM,shutdown); signal.signal(signal.SIGINT,shutdown)
    try:
        if not active(): return 0
        p=prefs()
        if not (run/'intro-seen').exists():
            (run/'intro-seen').touch()
            if p['intro'] and not locked():
                effect=spawn_effect('intro',run); play()
        while running and active() and wayland_alive():
            p=prefs(); target=p['saver'] if shutil.which('swayidle') and on_ac() else 0
            if target!=last:
                stop(idle); idle=None; (run/'idle').unlink(missing_ok=True); failed=False
                token=os.urandom(12).hex(); (run/'token').write_text(token); last=target
                if target:
                    idle=subprocess.Popen(idle_command(target,run,token),stdin=subprocess.DEVNULL)
            if idle and idle.poll() is not None:
                idle=None; failed=True; (run/'idle').unlink(missing_ok=True); break
            if effect and effect.poll() is not None: effect=None
            want=bool(target and idle and read(run/'idle')==token and not locked())
            # After intro ends, show saver only for current idle event.
            if want and effect is None and not shown:
                shown=True; effect=spawn_effect('saver',run)
            if not want: shown=False
            (run/'status').write_text('idle backend failed' if failed else ('watching '+str(target)+'s' if target else 'idle saver off / battery / dependency missing'))
            if not target and effect is None: break
            time.sleep(.5)
    finally:
        stop(idle); stop(effect); (run/'idle').unlink(missing_ok=True); (run/'token').unlink(missing_ok=True); (run/'status').write_text('idle backend failed; see log' if failed else 'stopped')
    return 0

def kick(run):
    if not active(): return
    p=prefs()
    if (run/'intro-seen').exists() and (not p['saver'] or not shutil.which('swayidle') or not on_ac()): return
    with (run/'launch.lock').open('a') as f:
        try: fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError: return
        with (run/'worker.lock').open('a') as w:
            try: fcntl.flock(w,fcntl.LOCK_EX|fcntl.LOCK_NB)
            except BlockingIOError: return
        try: prev=float(read(run/'attempt'))
        except ValueError: prev=0
        if time.monotonic()-prev < (30 if 'failed' in read(run/'status') else 3): return
        (run/'attempt').write_text(str(time.monotonic()))
        with (run/'log').open('w') as log:
            subprocess.Popen(['/usr/bin/python3',str(__file__),'worker'],stdin=subprocess.DEVNULL,stdout=log,stderr=log,start_new_session=True)
def preview(mode,run):
    if not active() or locked(): return 1
    p=spawn_effect(mode,run)
    try:
        if mode=='intro': play()
        return p.wait(timeout=9)
    except subprocess.TimeoutExpired: return 1
    finally: stop(p)
def menu(run):
    if not active(): return 1
    while True:
        p=prefs(); choices=[f"intro : {'on' if p['intro'] else 'off'}",f"screensaver : {str(p['saver'])+'s / AC only' if p['saver'] else 'off'}",f"sound : {'on' if p['sound'] else 'off'}",f"exit animation : {'on' if p['exit'] else 'off'}",'preview intro','preview screensaver (8s)','back']
        try: r=subprocess.run(['fuzzel','--dmenu','--prompt','session > ','--width','50','--lines','7'],input='\n'.join(choices)+'\n',text=True,capture_output=True)
        except OSError: return 1
        if r.returncode or r.stdout.strip() not in choices: return 0
        i=choices.index(r.stdout.strip())
        if i==6: return 0
        if i in (0,2,3): k={0:'intro',2:'sound',3:'exit'}[i]; save(k,not p[k])
        elif i==1:
            opts=['off','60','180','300']; r=subprocess.run(['fuzzel','--dmenu','--prompt','idle seconds > ','--lines','4'],input='\n'.join(opts)+'\n',text=True,capture_output=True)
            if r.returncode==0 and r.stdout.strip() in opts: save('saver',0 if r.stdout.strip()=='off' else int(r.stdout.strip()))
        elif i in (4,5): preview('intro' if i==4 else 'preview',run)
        kick(run)
def main():
    cmd=sys.argv[1] if len(sys.argv)>1 else 'status'; run=runtime()
    if cmd=='status':
        print(json.dumps(prefs(),indent=2)); print('swayidle:',shutil.which('swayidle') or 'not installed'); print('paplay:',shutil.which('paplay') or 'not installed'); print('runtime:',read(run/'status') if run else 'no Hyprland session'); return 0
    if not run: return 0 if cmd in ('kick','exit') else 1
    if cmd=='kick': kick(run); return 0
    if cmd=='worker': return worker(run)
    if cmd=='menu':
        return subprocess.call(['/usr/bin/python3',str(THEME/'settings/settings.py'),'menu'])
    if cmd=='session-menu': return menu(run)
    if cmd=='preview-intro': return preview('intro',run)
    if cmd in ('idle-on','idle-off') and len(sys.argv)==3:
        token=sys.argv[2]
        if token and read(run/'token')==token:
            if cmd=='idle-on' and active(): (run/'idle').write_text(token)
            else: (run/'idle').unlink(missing_ok=True)
        return 0
    if cmd=='exit':
        if prefs()['exit']: preview('exit',run)
        return 0
    if cmd=='preview': return preview('preview',run)
    return 2
if __name__=='__main__': sys.exit(main())
