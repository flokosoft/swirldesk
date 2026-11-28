#!/usr/bin/env python3
"""MATRIX Plasma 0.6.0: reversible, per-user appearance overlay; no KWin shortcuts."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
HOME = Path.home()
CONF = HOME / '.config'
DATA = HOME / '.local/share'
STATE = ROOT / 'state/plasma_matrix'
BACKUPS = ROOT / 'backups/plasma-matrix'
TRAY_SYS = Path('/usr/share/plasma/plasmoids/org.kde.plasma.private.systemtray')
TRAY_REL = 'contents/ui/items/StatusNotifierItem.qml'
SHELL = 'plasma-plasmashell.service'
PROFILES = {'clean':'matrix-clean.png','code-rain':'matrix-code.png','construct':'matrix-construct.png'}
SCHEME = 'SwirlDeskMATRIX'
ICON = 'SwirlDesk-MATRIX-Plasma'
MARK = 'MATRIX 0.6.0 DIRECT SNI OVERRIDE'


def paths():
    p = {f'cfg-{name}': CONF/name for name in ('kdeglobals','plasmarc','konsolerc','kscreenlockerrc','plasma-org.kde.plasma.desktop-appletsrc')}
    p.update({'scheme': DATA/'color-schemes'/f'{SCHEME}.colors', 'style':DATA/'plasma/desktoptheme'/SCHEME,
              'icons':DATA/'icons'/ICON, 'konsole-colors':DATA/'konsole'/f'{SCHEME}.colorscheme',
              'konsole-profile':DATA/'konsole/SwirlDesk MATRIX.profile',
              'tray':DATA/'plasma/plasmoids/org.kde.plasma.private.systemtray',
              'session-entry':DATA/'applications/org.swirldesk.matrix.session.desktop',
              'launcher-entry':DATA/'applications/org.swirldesk.matrix.launcher.desktop'})
    for t in ('label','pager'):
        p[f'matrix-{t}'] = DATA/f'plasma/plasmoids/org.swirldesk.matrix{t}'
        p[f'field-{t}'] = DATA/f'plasma/plasmoids/org.swirldesk.field{t}/contents/ui/main.qml'
    return p


def run(*args, capture=False, check=True):
    return subprocess.run([str(a) for a in args], check=check, text=True, capture_output=capture, timeout=60)


def need(*cmds):
    missing = [c for c in cmds if not shutil.which(c)]
    if missing:
        raise RuntimeError('Missing commands: '+', '.join(missing))


def qdbus():
    for cmd in ('qdbus6','qdbus-qt6','qdbus'):
        if shutil.which(cmd): return cmd
    raise RuntimeError('Qt 6 D-Bus client missing')


def live_session():
    desktop = (os.environ.get('XDG_CURRENT_DESKTOP','')+';'+os.environ.get('XDG_SESSION_DESKTOP','')).lower()
    if not any(x in desktop for x in ('kde','plasma')) or os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):
        raise RuntimeError('Run from a KDE Plasma session, not Hyprland or SSH.')
    if Path(os.environ.get('XDG_CONFIG_HOME',str(CONF))) != CONF or Path(os.environ.get('XDG_DATA_HOME',str(DATA))) != DATA:
        raise RuntimeError('Nonstandard XDG directories are not supported by this test release.')
    need('systemctl','kwriteconfig6','kreadconfig6','plasma-apply-colorscheme','plasma-apply-desktoptheme','plasma-apply-wallpaperimage','plasmashell')
    qdbus()


def shell_active():
    return run('systemctl','--user','is-active','--quiet',SHELL,check=False).returncode == 0


def stop_shell():
    if shell_active(): run('systemctl','--user','stop',SHELL)
    if shell_active(): raise RuntimeError('Plasma shell did not stop; refusing to edit live files.')


def start_shell():
    run('systemctl','--user','start',SHELL)
    for _ in range(50):
        if run(qdbus(),'org.kde.plasmashell','/PlasmaShell',check=False,capture=True).returncode == 0: return
        time.sleep(.2)
    raise RuntimeError('Plasma shell D-Bus did not become ready.')


def atomic_json(path, data):
    path.parent.mkdir(parents=True,exist_ok=True)
    fd, temp = tempfile.mkstemp(dir=path.parent)
    with os.fdopen(fd,'w') as f: json.dump(data,f,indent=2); f.write('\n')
    os.replace(temp,path)


def current():
    f = STATE/'active.json'
    return json.loads(f.read_text()) if f.exists() else None


def remove(path):
    if path.is_symlink() or path.is_file(): path.unlink()
    elif path.is_dir(): shutil.rmtree(path)


def copy(src,dst):
    dst.parent.mkdir(parents=True,exist_ok=True)
    if src.is_symlink(): dst.symlink_to(os.readlink(src))
    elif src.is_dir(): shutil.copytree(src,dst,symlinks=True)
    else: shutil.copy2(src,dst)


def replace(src,dst):
    remove(dst); copy(src,dst)


def check_targets():
    # Refuse to write through links in affected paths, even if they point inside HOME.
    for path in paths().values():
        for part in (path,*path.parents):
            if part == HOME.parent: break
            if part.is_symlink(): raise RuntimeError(f'Symlink at managed path {part}; refusing unsafe overlay.')


def snapshot():
    check_targets()
    BACKUPS.mkdir(parents=True,exist_ok=True)
    dest=Path(tempfile.mkdtemp(prefix='snapshot-',dir=BACKUPS))
    os.chmod(dest,0o700)
    manifest={}
    for name,p in paths().items():
        present=p.exists() or p.is_symlink()
        if present: copy(p,dest/name)
        manifest[name]=present
    atomic_json(dest/'manifest.json',manifest)
    return dest


def restore_snapshot(dest):
    check_targets()
    dest=Path(dest).resolve()
    if dest.parent != BACKUPS.resolve(): raise RuntimeError('Invalid backup path')
    manifest=json.loads((dest/'manifest.json').read_text())
    if set(manifest) != set(paths()) or any(type(v) is not bool for v in manifest.values()): raise RuntimeError('Invalid manifest')
    for name,present in manifest.items():
        if present and not (dest/name).exists(): raise RuntimeError(f'Missing backup item: {name}')
    for name,p in paths().items():
        remove(p)
        if manifest[name]: copy(dest/name,p)


def kw(file, groups, key, value):
    args=['kwriteconfig6','--file',file]
    for g in groups: args+=['--group',g]
    run(*args,'--key',key,value)


def kr(file,groups,key):
    args=['kreadconfig6','--file',file]
    for g in groups: args+=['--group',g]
    return run(*args,'--key',key,capture=True).stdout.strip()


def wallpaper(name):
    if name not in PROFILES: raise RuntimeError('Choose clean, code-rain or construct')
    f=ROOT/'themes/swirldesk-matrix/wallpapers'/PROFILES[name]
    if not f.is_file(): raise RuntimeError(f'Missing wallpaper {f}; install MATRIX 0.3.1 first.')
    return f


def desktop_entry(name,action):
    # Desktop Exec quoting: no shell expansion; escape special characters.
    exe=str(ROOT/'bin/swirl-matrix')
    if any(c in exe for c in '\n\r%"\\`$'): raise RuntimeError('Unsupported special character in executable path')
    return f'[Desktop Entry]\nType=Application\nName={name}\nExec="{exe}" plasma {action}\nIcon=swirldesk-matrix-launcher\nTerminal=false\nOnlyShowIn=KDE;\nCategories=System;\n'


def tray_compatible(local, version):
    # Known live-tested FIELD delegate is accepted on Plasma 6.3.5/6.3.6.
    if not re.search(r'\b6\.3\.[56]\b',version): return False,'Plasma version outside 6.3.5/6.3.6'
    if local.exists():
        if local.read_bytes()==(HERE/'tray/original-field-StatusNotifierItem.qml').read_bytes(): return True,'known FIELD 0.9.3.7 delegate'
        if local.read_bytes()==(HERE/'tray/StatusNotifierItem.qml').read_bytes(): return True,'MATRIX delegate'
        if not (TRAY_SYS/TRAY_REL).is_file() or local.read_bytes()!=(TRAY_SYS/TRAY_REL).read_bytes(): return False,'custom local tray delegate, left unchanged'
    if not re.search(r'\b6\.3\.5\b',version): return False,'stock tray template verified for 6.3.5 only'
    if not (TRAY_SYS/TRAY_REL).is_file(): return False,'system tray package missing'
    text=(TRAY_SYS/TRAY_REL).read_text()
    if not all(s in text for s in ('AbstractItem','Kirigami.Icon','model.Icon','model.Service','onActivated','onContextMenu')): return False,'unrecognized system tray API'
    return True,'Plasma 6.3.5 stock delegate'


def install_assets(version):
    p=paths(); warnings=[]; applied=[]
    for key,src in {'scheme':'colors/SwirlDeskMATRIX.colors','style':'style/SwirlDeskMATRIX','icons':'icons/SwirlDesk-MATRIX-Plasma','konsole-colors':'konsole/SwirlDeskMATRIX.colorscheme','konsole-profile':'konsole/SwirlDesk MATRIX.profile','matrix-label':'plasmoid/org.swirldesk.matrixlabel','matrix-pager':'plasmoid/org.swirldesk.matrixpager'}.items(): replace(HERE/src,p[key])
    for t in ('label','pager'):
        dst=p[f'field-{t}']
        if dst.is_file() and dst.read_bytes()==(HERE/f'compat/original-field{t}.qml').read_bytes():
            replace(HERE/f'compat/field{t}.qml',dst); applied.append(f'field-{t}')
        else: warnings.append(f'FIELD {t} absent or modified; left unchanged. MATRIX widget available in Add Widgets.')
    local=p['tray']/TRAY_REL
    supported,reason=tray_compatible(local,version)
    if supported:
        if not local.exists(): replace(TRAY_SYS,p['tray'])
        for s in ('chat','vault'): replace(HERE/f'icons/{ICON}/scalable/apps/matrix-{s}.svg',p['tray']/f'contents/icons/matrix-{s}.svg')
        replace(HERE/'tray/StatusNotifierItem.qml',local)
        applied.append('tray')
    else: warnings.append('SNI override skipped: '+reason)
    for key,name,action in [('session-entry','MATRIX // Session Control','power'),('launcher-entry','MATRIX // Construct','launcher')]:
        p[key].parent.mkdir(parents=True,exist_ok=True); p[key].write_text(desktop_entry(name,action))
    kw('kdeglobals',['Icons'],'Theme',ICON)
    kw('kdeglobals',['General'],'accentColorFromWallpaper','false')
    kw('kdeglobals',['General'],'AccentColor','0,185,80')
    kw('kdeglobals',['General'],'LastUsedCustomAccentColor','0,185,80')
    kw('konsolerc',['Desktop Entry'],'DefaultProfile','SwirlDesk MATRIX.profile')
    # Use the known dark lock background regardless of the desktop profile; authentication policy untouched.
    lock=wallpaper('code-rain').as_uri()
    kw('kscreenlockerrc',['Greeter'],'WallpaperPlugin','org.kde.image')
    for k in ('Image','PreviewImage'): kw('kscreenlockerrc',['Greeter','Wallpaper','org.kde.image','General'],k,lock)
    return applied,warnings


def set_profile(name):
    run('plasma-apply-wallpaperimage',wallpaper(name))


def refresh():
    run(qdbus(),'org.kde.KWin','/KWin','reconfigure',check=False,capture=True)
    if shutil.which('kbuildsycoca6'): run('kbuildsycoca6','--noincremental',check=False,capture=True)


def apply(name):
    live_session(); wallpaper(name); wallpaper('code-rain')
    if not shell_active(): raise RuntimeError('Plasma systemd user shell is not active. No changes made.')
    if current(): raise RuntimeError('MATRIX already applied or recovery pending. Use profile or restore first.')
    check_targets()
    version=run('plasmashell','--version',capture=True).stdout.strip()
    dest=None
    try:
        stop_shell()
        dest=snapshot()
        state={'status':'pending','backup':str(dest),'profile':name,'plasma_version':version,'applied':[],'warnings':[]}
        atomic_json(STATE/'active.json',state)
        applied,warnings=install_assets(version)
        start_shell()
        run('plasma-apply-colorscheme',SCHEME)
        run('plasma-apply-desktoptheme',SCHEME)
        set_profile(name)
        refresh()
        state.update(status='active',applied=applied,warnings=warnings)
        atomic_json(STATE/'active.json',state)
    except BaseException:
        # Preserve a baseline even after partial installation. Attempt automatic rollback, but never hide failure.
        if dest and (STATE/'active.json').exists():
            try: restore()
            except BaseException as e: print(f'Automatic rollback failed: {e}; run swirl-matrix plasma restore',file=sys.stderr)
        else:
            try: start_shell()
            except Exception as e: print(f'Shell restart failed: {e}',file=sys.stderr)
        raise
    print('MATRIX // PLASMA APPLIED',name,'\nBackup:',dest)
    for w in warnings: print('INFO',w)
    print('Existing global shortcuts, KWin settings and panel containments were not modified.')


def restore():
    live_session(); state=current()
    if not state: raise RuntimeError('No MATRIX Plasma snapshot active.')
    check_targets()
    stop_shell()
    try: restore_snapshot(state['backup'])
    finally: start_shell()
    refresh()
    (STATE/'active.json').unlink()
    print('MATRIX // previous Plasma appearance restored. Backup retained at',state['backup'])
    print('Reopen existing applications or log out/in if cached colors remain.')


def profile(name):
    live_session(); state=current()
    if not state or state['status']!='active': raise RuntimeError('MATRIX Plasma is not active')
    set_profile(name); state['profile']=name; atomic_json(STATE/'active.json',state)
    print('MATRIX // VISUAL',name)


def doctor():
    issues=0; count=0
    def check(label,ok,detail=''):
        nonlocal issues,count
        print(('OK      ' if ok else 'MISMATCH')+f' {label:30} {detail}')
        if ok: count+=1
        else: issues+=1
    print('MATRIX // PLASMA DOCTOR 0.6.0')
    for name in PROFILES: check('wallpaper '+name,(ROOT/'themes/swirldesk-matrix/wallpapers'/PROFILES[name]).is_file())
    state=current()
    if not state:
        print('INFO     MATRIX Plasma inactive; apply from a KDE session.'); return int(issues!=0)
    check('transaction active',state['status']=='active',state['status'])
    check('restore snapshot',(Path(state['backup'])/'manifest.json').is_file(),state['backup'])
    check('Plasma colors',kr('kdeglobals',['General'],'ColorScheme')==SCHEME)
    check('Plasma style',kr('plasmarc',['Theme'],'name')==SCHEME)
    check('Plasma icon theme',kr('kdeglobals',['Icons'],'Theme')==ICON)
    check('Konsole profile',kr('konsolerc',['Desktop Entry'],'DefaultProfile')=='SwirlDesk MATRIX.profile')
    check('dark native lock wallpaper',kr('kscreenlockerrc',['Greeter','Wallpaper','org.kde.image','General'],'Image')==wallpaper('code-rain').as_uri())
    p=paths()
    for t in ('label','pager'):
        check('MATRIX '+t+' applet',(p[f'matrix-{t}']/'contents/ui/main.qml').is_file())
        if 'field-'+t in state['applied']:
            f=p['field-'+t]; check('FIELD '+t+' visual adapter',f.is_file() and f.read_bytes()==(HERE/f'compat/field{t}.qml').read_bytes())
    if 'tray' in state['applied']:
        f=p['tray']/TRAY_REL; check('SNI delegate exact',f.is_file() and f.read_bytes()==(HERE/'tray/StatusNotifierItem.qml').read_bytes())
        for s in ('chat','vault'):
            f=p['tray']/f'contents/icons/matrix-{s}.svg'; check('SNI '+s+' vector',f.is_file() and f.read_bytes()==(HERE/f'icons/{ICON}/scalable/apps/matrix-{s}.svg').read_bytes())
    else: print('INFO     Tray override not applied; native pixmaps can remain colored.')
    check('session launcher',p['session-entry'].is_file()); check('Plasma shell running',shell_active())
    print('INFO     saved visual profile:',state['profile'])
    for w in state['warnings']: print('INFO    ',w)
    print(f'{count} OK / {issues} issue(s); live rendering is not verified by this doctor.')
    return int(issues!=0)


def main():
    ap=argparse.ArgumentParser(description=__doc__); ap.add_argument('action',choices=['apply','restore','profile','doctor']); ap.add_argument('name',nargs='?',choices=PROFILES,default='code-rain'); a=ap.parse_args()
    if a.action=='doctor': return doctor()
    # Serialize state updates; no state file shared with Hyprland.
    STATE.mkdir(parents=True,exist_ok=True)
    with (STATE/'lock').open('a') as f:
        fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB)
        if a.action=='apply': apply(a.name)
        elif a.action=='restore': restore()
        else: profile(a.name)
    return 0

if __name__=='__main__':
    try: sys.exit(main())
    except (RuntimeError,OSError,subprocess.SubprocessError,ValueError) as e:
        print('MATRIX // ERROR:',e,file=sys.stderr); sys.exit(1)
