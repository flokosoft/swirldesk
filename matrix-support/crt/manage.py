#!/usr/bin/env python3
"""Guarded v0.8.0 -> v0.8.1 integration, preserving rain doctor consistency."""
from pathlib import Path
import os, sys, tempfile, subprocess
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
VIS=ROOT/'themes/swirldesk-matrix/visual'
FILES=[VIS/'profile.sh', ROOT/'matrix-support/rain/profile.new']

def replace(p,data):
    fd,n=tempfile.mkstemp(prefix='.crt-',dir=p.parent)
    try:
        with os.fdopen(fd,'wb') as f: f.write(data)
        os.chmod(n,p.stat().st_mode & 0o777); os.replace(n,p)
    finally:
        if os.path.exists(n): os.unlink(n)

def main(action):
    if action not in ('apply','restore','doctor'): return 2
    old=(HERE/'profile.original').read_bytes(); new=(HERE/'profile.new').read_bytes()
    previous={}
    for p in FILES:
        if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute():
            print('MISMATCH missing or nonregular: '+str(p)); return 1
        previous[p]=p.read_bytes()
        if previous[p] not in (old,new): print('MISMATCH customized or wrong baseline: '+str(p)); return 1
    if action=='doctor':
        ok=all(v==new for v in previous.values()); print(('OK' if ok else 'MISMATCH')+' CRT profile integration'); return int(not ok)
    if action=='restore':
        subprocess.run([str(VIS/'crt/ctl.sh'),'off'],check=True)
    target=new if action=='apply' else old
    done=[]
    try:
        for p in FILES:
            if previous[p]!=target: replace(p,target); done.append(p)
    except OSError:
        for p in reversed(done): replace(p,previous[p])
        raise
    print('MATRIX CRT integration '+action+' OK'); return 0
if __name__=='__main__': sys.exit(main(sys.argv[1] if len(sys.argv)==2 else ''))
