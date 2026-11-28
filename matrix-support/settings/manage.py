#!/usr/bin/python3
import os,sys,tempfile
from pathlib import Path
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[1]; target=ROOT/'themes/swirldesk-matrix/session/digital/controller.py'
old=(HERE/'controller.old').read_bytes(); new=(HERE/'controller.new').read_bytes()
cmd=sys.argv[1] if len(sys.argv)==2 else ''
if cmd not in ('apply','restore','doctor'): sys.exit(2)
if not target.is_file() or target.is_symlink() or target.read_bytes() not in (old,new): print('MISMATCH session controller baseline; no files changed');sys.exit(1)
want=old if cmd=='restore' else new
if cmd=='doctor' and target.read_bytes()!=want: print('MISMATCH settings integration not active');sys.exit(1)
if cmd!='doctor' and target.read_bytes()!=want:
    fd,n=tempfile.mkstemp(dir=target.parent)
    try:
        with os.fdopen(fd,'wb') as f: f.write(want)
        os.chmod(n,target.stat().st_mode&0o777);os.replace(n,target)
    finally:
        if os.path.exists(n): os.unlink(n)
print('OK MATRIX settings '+cmd)
