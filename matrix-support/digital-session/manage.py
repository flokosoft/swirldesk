#!/usr/bin/env python3
"""Guarded transactional overlay; existing files must match the released baseline."""
import hashlib,json,os,sys,tempfile
from pathlib import Path
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[1]
MANIFEST=json.loads((HERE/'manifest.json').read_text())
def digest(b): return hashlib.sha256(b).hexdigest()
def atomic(path,data,mode):
    fd,n=tempfile.mkstemp(dir=path.parent,prefix='.matrix-session-')
    try:
        with os.fdopen(fd,'wb') as f: f.write(data)
        os.chmod(n,mode); os.replace(n,path)
    finally:
        if os.path.exists(n): os.unlink(n)
def main(action):
    if action not in ('apply','restore','doctor'): return 2
    desired='old' if action=='restore' else 'new'; todo=[]; errors=[]
    for rel,h in MANIFEST.items():
        p=ROOT/rel; src=HERE/desired/rel
        if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute(): errors.append('missing/nonregular '+rel);continue
        old=p.read_bytes(); new=src.read_bytes()
        if digest(old) not in h.values() or digest(new)!=h[desired]: errors.append('customized or invalid '+rel);continue
        if action=='doctor' and old!=new: errors.append('not applied '+rel)
        elif old!=new: todo.append((p,old,new,p.stat().st_mode&0o777))
    if errors:
        print('\n'.join('MISMATCH '+e for e in errors));print('No files changed.');return 1
    done=[]
    if action!='doctor':
        try:
            for p,old,new,mode in todo: atomic(p,new,mode);done.append((p,old,mode))
        except OSError:
            for p,old,mode in reversed(done): atomic(p,old,mode)
            raise
    print('OK MATRIX digital session '+action+f' ({len(todo)} files changed)');return 0
if __name__=='__main__': sys.exit(main(sys.argv[1] if len(sys.argv)==2 else ''))
