#!/usr/bin/env python3
"""Install the pre-integrated SwirlDesk tree; never replay developmental overlays."""
import argparse, hashlib, json, os, shutil, subprocess, sys, tempfile
from pathlib import Path
from datetime import datetime
ROOT=Path(__file__).resolve().parents[1]
HOME=Path.home(); TARGET=HOME/'.config/swirldesk'
MANIFEST=ROOT/'master/manifest.json'
PRESERVE=('hypr/monitors/','hypr/conf/','hypr/hyprland.conf','hypr/hypridle.conf','hypr/hyprlock.conf','zsh/.zshrc')
def signature(p):
    if p.is_symlink(): return 'link:'+os.readlink(p)
    if p.is_file(): return hashlib.sha256(p.read_bytes()).hexdigest()
    return None

def exists(p): return p.exists() or p.is_symlink()
def within(p,root):
    # Reject symlinked parent directories before any writes.
    return p.parent.resolve().is_relative_to(root.resolve()) and not any(x.is_symlink() for x in p.parents if x!=root and x.is_relative_to(root))
def protected(rel): return any(rel==x or (x.endswith('/') and rel.startswith(x)) for x in PRESERVE)
# The original ZIP dereferenced these historical aliases. A live Linux
# installation may still contain the original same-directory symbolic links.
FIELD_ALIAS_NAMES = {
    **{'places/'+name+'.svg': 'places/folder.svg' for name in (
        'folder-documents','folder-download','folder-music','folder-pictures',
        'folder-publicshare','folder-remote','folder-templates','folder-videos','user-desktop')},
    'places/user-trash-full.svg':'places/user-trash.svg',
    'devices/drive-harddisk-system.svg':'devices/drive-harddisk.svg',
}
FIELD_ALIAS_ROOTS = (
    'themes/swirldesk-field/icons/SwirlDesk-FIELD/scalable/',
    'plasma/field/icons/SwirlDesk-FIELD-Plasma/scalable/',
)
FIELD_ALIASES = {base+alias:base+canonical for base in FIELD_ALIAS_ROOTS
                 for alias,canonical in FIELD_ALIAS_NAMES.items()}
FIELD_ALIASES.update({FIELD_ALIAS_ROOTS[1]+'apps/'+name+'.svg':
                      FIELD_ALIAS_ROOTS[1]+'apps/swirldesk-field-launcher.svg'
                      for name in ('start-here','start-here-kde')})

def equivalent_field_alias(rel, src, dst):
    if rel not in FIELD_ALIASES or not dst.is_symlink() or src.is_symlink():
        return False
    canonical=TARGET/FIELD_ALIASES[rel]
    try:
        raw=Path(os.readlink(dst))
        # Only the expected, internal canonical file; never follow arbitrary links.
        if raw.is_absolute() or '..' in raw.parts or not within(canonical,TARGET): return False
        if dst.resolve(strict=True)!=canonical or canonical.is_symlink() or not canonical.is_file(): return False
        return signature(canonical)==signature(src)
    except (OSError,RuntimeError,ValueError):
        return False

def run(*args): subprocess.run(args,check=True)
def deps(plasma, enable_backports):
    if not Path('/etc/debian_version').exists(): raise RuntimeError('Nur Debian wird unterstützt.')
    core='hyprland hyprlock hypridle waybar fuzzel dunst kitty swaybg python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-gtklayershell-0.1 swayidle pulseaudio-utils jq socat papirus-icon-theme adwaita-icon-theme fontconfig'.split()
    run('sudo','apt-get','update')
    # Respect configured package sources. Use configured Debian backports for Hyprland if available.
    suite='trixie-backports'
    policy=subprocess.run(['apt-cache','policy','hyprland'],capture_output=True,text=True,check=True).stdout
    if suite not in policy and enable_backports:
        codename=subprocess.run(['sh','-c','. /etc/os-release; printf %s "$VERSION_CODENAME"'],capture_output=True,text=True,check=True).stdout
        if codename!='trixie': raise RuntimeError('Automatische Backports-Einrichtung nur für Debian 13/trixie.')
        source=Path('/etc/apt/sources.list.d/swirldesk-trixie-backports.sources')
        if source.exists() or source.is_symlink(): raise RuntimeError('Backports-Datei vorhanden, wird nicht überschrieben; apt-Quellen prüfen.')
        content='Types: deb\nURIs: https://deb.debian.org/debian\nSuites: trixie-backports\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n'
        subprocess.run(['sudo','tee',str(source)],input=content,text=True,check=True)
        run('sudo','apt-get','update')
        policy=subprocess.run(['apt-cache','policy','hyprland'],capture_output=True,text=True,check=True).stdout
    if suite not in policy:
        candidate=next((x.split(':',1)[1].strip() for x in policy.splitlines() if x.strip().startswith('Candidate:')), '(none)')
        if candidate=='(none)' or subprocess.run(['dpkg','--compare-versions',candidate,'ge','0.53']).returncode:
            raise RuntimeError('Hyprland >= 0.53 benötigt. Debian 13 Backports konfigurieren oder --enable-backports verwenden; keine Desktop-Dateien geändert.')
    if suite in policy:
        run('sudo','apt-get','install','-y','-t',suite,'hyprland','hyprlock','hypridle')
    run('sudo','apt-get','install','-y',*core)
    opt=[s.strip() for s in (ROOT/'packages/debian.txt').read_text().splitlines() if s.strip() and not s.lstrip().startswith('#')]
    excluded={'greetd','tuigreet','unrar'}
    failed=[]
    for p in dict.fromkeys(opt+['xdg-desktop-portal-hyprland','policykit-1-gnome','util-linux','firefox-esr']):
        if p in core or p in excluded: continue
        if subprocess.run(['sudo','apt-get','install','-y',p]).returncode: failed.append(p)
    if plasma: run('sudo','apt-get','install','-y','--no-install-recommends','plasma-desktop','plasma-workspace','kwin-wayland','konsole','dolphin','spectacle','qdbus-qt6','firefox-esr')
    if failed: print('WARN optionale Pakete nicht installiert: '+', '.join(failed))

def links():
    # Create fresh desktop links using the existing path conventions. Only missing
    # links on upgrade; preserve existing custom or external paths.
    t=TARGET; current=t/'state/current_theme'
    out={HOME/'.local/bin'/p.name:p for p in (t/'bin').iterdir() if p.is_file()}
    for rel in ('waybar/config','waybar/style.css','fuzzel/fuzzel.ini','dunst/dunstrc','kitty/kitty.conf'):
        out[HOME/'.config'/rel]=current/rel
    for version in ('gtk-3.0','gtk-4.0'):
        out[HOME/'.config'/version/'settings.ini']=current/'gtk/settings.ini'
        css=current/('gtk/gtk-3.css' if version=='gtk-3.0' else 'gtk/gtk-4.css')
        if css.is_file(): out[HOME/'.config'/version/'gtk.css']=css
    if (current/'starship/starship.toml').is_file(): out[HOME/'.config/starship.toml']=current/'starship/starship.toml'
    out[HOME/'.config/hypr/hyprlock.conf']=current/'hyprlock/hyprlock.conf' if (current/'hyprlock/hyprlock.conf').is_file() else t/'hypr/hyprlock.conf'
    for rel in ('hypr/hyprland.conf','hypr/hypridle.conf','fastfetch/config.jsonc'):
        out[HOME/'.config'/rel]=t/rel
    for p in (t/'hypr/conf').glob('*.conf'): out[HOME/'.config/hypr/conf'/p.name]=p
    out[HOME/'.zshrc']=t/'zsh/.zshrc'
    for name,theme in [('SwirlDesk-MATRIX','swirldesk-matrix'),('SwirlDesk-FIELD','swirldesk-field')]:
        out[HOME/'.local/share/icons'/name]=t/'themes'/theme/'icons'/name
    return out

def main():
    ap=argparse.ArgumentParser(description=__doc__); g=ap.add_mutually_exclusive_group();g.add_argument('--fresh',action='store_true');g.add_argument('--upgrade',action='store_true');ap.add_argument('--no-packages',action='store_true',help='use already installed dependencies');ap.add_argument('--plasma',action='store_true',help='also install KDE Plasma packages; no theme activation');ap.add_argument('--enable-backports',action='store_true',help='allow adding official Debian 13 backports if missing');ap.add_argument('--dry-run',action='store_true');a=ap.parse_args()
    if TARGET.is_symlink(): raise RuntimeError('SwirlDesk-Ziel ist Symlink; manueller Umzug erforderlich.')
    if os.geteuid()==0: raise RuntimeError("Nicht als root installieren.")
    m=json.loads(MANIFEST.read_text()); files=m['files']; known=m['known']; inplace=ROOT==TARGET.resolve()
    installed=exists(TARGET/'state/current_theme') or (TARGET/'state/current_theme_name').exists()
    if a.fresh and installed: raise RuntimeError('Bestehende Installation: --upgrade verwenden.')
    if not a.upgrade and not a.fresh and installed: raise RuntimeError('Bestehende Installation: --upgrade ausdrücklich angeben.')
    if a.upgrade and not TARGET.is_dir(): raise RuntimeError('Kein Upgrade-Ziel vorhanden.')
    if not a.upgrade and TARGET.exists() and not inplace and any(TARGET.iterdir()): raise RuntimeError('Ziel nicht leer: --upgrade verwenden.')
    plan=[]; conflicts=[]; kept=[]; aliases=[]
    for rel,want in files.items():
        src=ROOT/rel; dst=TARGET/rel
        if not within(src,ROOT) or signature(src)!=want: raise RuntimeError('Quellintegrität: '+rel)
        if not within(dst,TARGET): conflicts.append(rel+' (Symlink-Pfad)');continue
        old=signature(dst)
        if exists(dst) and old is None: conflicts.append(rel+' (kein regulärer Dateityp)');continue
        if a.upgrade and exists(dst) and protected(rel): kept.append(rel);continue
        if a.upgrade and rel=='packages/debian.txt' and dst.is_file() and not dst.is_symlink():
            kept.append(rel);continue
        if old==want: continue
        if a.upgrade and equivalent_field_alias(rel,src,dst):
            aliases.append(rel);continue
        if exists(dst) and old not in known.get(rel,[]): conflicts.append(rel);continue
        plan.append((src,dst,old))
    # Manifest itself is intentionally not self-hashed.
    md=TARGET/'master/manifest.json'
    if not inplace and signature(md)!=signature(MANIFEST):
        if not within(md,TARGET) or (exists(md) and not md.is_file()) or md.is_symlink(): conflicts.append('master/manifest.json')
        else: plan.append((MANIFEST,md,signature(md)))
    print(f'{len(plan)} Dateien zu installieren/aktualisieren; {len(kept)} lokale Konfigurationsdateien geschützt.')
    for p in kept: print('KEEP',p)
    for p in aliases: print('KEEP ALIAS',p)
    if conflicts:
        for p in conflicts: print('CONFLICT',p)
        raise RuntimeError('Keine Dateien geändert. Lokale Änderungen zuerst sichern/abgleichen.')
    if a.dry_run: print('DRY RUN: keine Änderungen, keine apt-Aufrufe.');return
    if not a.no_packages: deps(a.plasma,a.enable_backports)
    if a.upgrade and installed:
        cur=TARGET/'state/current_theme'; name=TARGET/'state/current_theme_name'
        if not cur.is_symlink() or not cur.is_dir() or not name.is_file() or cur.resolve()!=TARGET/'themes'/name.read_text().strip(): raise RuntimeError('Bestehender Theme-State inkonsistent; nicht überschrieben.')
    stamp=datetime.now().strftime('%Y%m%d-%H%M%S-%f'); backup=HOME/'.local/state/swirldesk/master-backups'/stamp
    backup.mkdir(parents=True,mode=0o700); done=[]
    def replace(src,dst,old):
        dst.parent.mkdir(parents=True,exist_ok=True)
        if signature(dst)!=old: raise RuntimeError('Datei während Installation verändert: '+str(dst))
        if old is not None:
            b=backup/'files'/dst.relative_to(TARGET);b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,b,follow_symlinks=False)
        temp=dst.parent/('.swirldesk-master-'+stamp)
        try:
            if src.is_symlink(): temp.symlink_to(os.readlink(src))
            else: shutil.copy2(src,temp)
            os.replace(temp,dst)
        finally:
            if exists(temp): temp.unlink()
        done.append((dst,old))
    try:
        for src,dst,old in plan: replace(src,dst,old)
    except BaseException:
        for dst,old in reversed(done):
            if old is None: dst.unlink(missing_ok=True)
            else:
                dst.unlink(missing_ok=True);shutil.copy2(backup/'files'/dst.relative_to(TARGET),dst,follow_symlinks=False)
        raise
    (backup/'changed.json').write_text(json.dumps([{'path':str(d.relative_to(TARGET)),'previous':o} for d,o in done],indent=2))
    state=TARGET/'state';state.mkdir(exist_ok=True)
    if not exists(state/'current_theme'):
        if exists(state/'current_theme_name'): raise RuntimeError('Theme-State unvollständig; bitte manuell prüfen.')
        (state/'current_theme').symlink_to(TARGET/'themes/swirldesk-debian');(state/'current_theme_name').write_text('swirldesk-debian\n')
    monitor=HOME/'.local/state/swirldesk/monitors-active.conf';monitor.parent.mkdir(parents=True,exist_ok=True)
    if not exists(monitor): monitor.symlink_to(TARGET/'hypr/monitors/open.conf')
    for dst,src in links().items():
        if not src.exists(): print('WARN Quelle fehlt',src);continue
        if exists(dst):
            if dst.is_symlink() and dst.resolve()==src.resolve(): continue
            if a.upgrade or dst.is_dir() or dst.is_symlink(): print('KEEP bestehende Verknüpfung/Konfiguration',dst);continue
            b=backup/'home'/dst.relative_to(HOME);b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,b);dst.unlink()
        dst.parent.mkdir(parents=True,exist_ok=True);dst.symlink_to(src)
    wall=HOME/'Bilder/Wallpapers';wall.mkdir(parents=True,exist_ok=True)
    for p in (TARGET/'wallpapers').rglob('*'):
        if p.is_file() and not p.is_symlink():
            dst=wall/p.relative_to(TARGET/'wallpapers');dst.parent.mkdir(parents=True,exist_ok=True)
            if not exists(dst): shutil.copy2(p,dst)
    (HOME/'Bilder/Screenshots').mkdir(parents=True,exist_ok=True)
    (HOME/'.config/hypr/monitors-nwg.conf').touch(exist_ok=True) if not exists(HOME/'.config/hypr/monitors-nwg.conf') else None
    if shutil.which('fc-list'):
        families=subprocess.run(['fc-list',':','family'],capture_output=True,text=True).stdout
        if 'JetBrainsMono Nerd Font' not in families: print('INFO JetBrainsMono Nerd Font separat installieren.')
    print('SwirlDesk Master installiert. Sicherung:',backup)
    print('Hyprland: nach Anmeldung Super+Shift+T. Plasma: bewusst separat aktivieren (README).')
    print('Keine laufenden Sitzungen neu gestartet. ~/.local/bin muss im PATH sein.')
if __name__=='__main__':
    try: main()
    except (OSError,ValueError,RuntimeError,subprocess.CalledProcessError) as e: print('FEHLER:',e,file=sys.stderr);sys.exit(1)
