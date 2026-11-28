#!/usr/bin/env python3
"""Apply or undo the MATRIX digital appearance, without touching shared files."""
from pathlib import Path
import hashlib, json, os, sys, tempfile

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
MANIFEST=json.loads((HERE/'manifest.json').read_text())

def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def regular(p): return p.is_file() and not p.is_symlink() and p.resolve()==p.absolute()
def atomic(p, data, mode):
    fd, name=tempfile.mkstemp(prefix='.matrix-digital-',dir=p.parent)
    try:
        with os.fdopen(fd,'wb') as f: f.write(data)
        os.chmod(name,mode); os.replace(name,p)
    finally:
        if os.path.exists(name): os.unlink(name)

def run(action):
    if action not in ('apply','restore','doctor'): raise ValueError('Use apply, restore or doctor')
    pending=[]; bad=[]
    desired='new' if action!='restore' else 'old'
    for rel, hashes in MANIFEST.items():
        p=ROOT/rel; src=HERE/('payload' if desired=='new' else 'original')/rel
        if not regular(p) or not regular(src): bad.append(f'missing or nonregular: {rel}'); continue
        actual=digest(p)
        if digest(src)!=hashes[desired]: bad.append(f'package integrity: {rel}'); continue
        if actual not in hashes.values(): bad.append(f'customized: {rel}'); continue
        if action=='doctor':
            print(('OK      ' if actual==hashes['new'] else 'OLD     ')+rel)
            if actual!=hashes['new']: bad.append(f'not applied: {rel}')
        elif actual!=hashes[desired]: pending.append((p,src.read_bytes(),p.read_bytes(),p.stat().st_mode & 0o777))
    if bad:
        for msg in bad: print('MISMATCH '+msg,file=sys.stderr)
        print('No files changed.',file=sys.stderr); return 1
    if action=='doctor': print('MATRIX digital appearance: file integrity OK (not a live-render test)'); return 0
    done=[]
    try:
        for p,new,old,mode in pending:
            atomic(p,new,mode); done.append((p,old,mode))
    except OSError:
        for p,old,mode in reversed(done): atomic(p,old,mode)
        raise
    print(f'MATRIX digital {action}: {len(done)} files updated. Reselect MATRIX in Hyprland.')
    return 0

if __name__=='__main__':
    try: sys.exit(run(sys.argv[1] if len(sys.argv)==2 else ''))
    except (OSError,ValueError) as e: print(e,file=sys.stderr); sys.exit(1)
