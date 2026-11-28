#!/usr/bin/env python3
"""Guarded profile integration. No shared or digital-manager files modified."""
from pathlib import Path
import os, sys, tempfile
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
DEST=ROOT/'themes/swirldesk-matrix/visual/profile.sh'

def main(action):
    if action not in ('apply','restore','doctor'): return 2
    old=(HERE/'profile.original').read_bytes(); new=(HERE/'profile.new').read_bytes()
    if not DEST.is_file() or DEST.is_symlink() or DEST.resolve()!=DEST.absolute():
        print('MISMATCH profile.sh missing or nonregular; unchanged'); return 1
    actual=DEST.read_bytes()
    if actual not in (old,new): print('MISMATCH customized profile.sh; unchanged'); return 1
    if action=='doctor':
        print('OK rain profile integration' if actual==new else 'MISMATCH rain profile integration not installed'); return int(actual!=new)
    if action=='restore':
        import subprocess
        subprocess.run([str(DEST.parent/'rain/ctl.sh'),'off'],check=True)
    target=new if action=='apply' else old
    if actual!=target:
        fd,name=tempfile.mkstemp(prefix='.matrix-rain-',dir=DEST.parent)
        try:
            with os.fdopen(fd,'wb') as f: f.write(target)
            os.chmod(name,DEST.stat().st_mode & 0o777); os.replace(name,DEST)
        finally:
            if os.path.exists(name): os.unlink(name)
    print('MATRIX rain integration '+action+' OK'); return 0
if __name__=='__main__': sys.exit(main(sys.argv[1] if len(sys.argv)==2 else ''))
