#!/usr/bin/env python3
"""Run as a non-root user; all writes are under a disposable HOME."""
import os, subprocess, sys, tempfile
from pathlib import Path
sys.dont_write_bytecode=True
from install import FIELD_ALIASES, ROOT

def run(home,*args,ok=True):
    p=subprocess.run([sys.executable,str(ROOT/'master/install.py'),*args],env={**os.environ,'HOME':str(home)},capture_output=True,text=True)
    assert (p.returncode==0)==ok,p.stdout+p.stderr
    return p.stdout+p.stderr

with tempfile.TemporaryDirectory(prefix='swirldesk-rc2-test-') as tmp:
    home=Path(tmp); target=home/'.config/swirldesk'
    run(home,'--fresh','--no-packages')
    for alias,canonical in FIELD_ALIASES.items():
        p=target/alias; q=target/canonical
        p.unlink(); p.symlink_to(os.path.relpath(q,p.parent))
    local=target/'packages/debian.txt'; local.write_text('# local list\nexample-package\n')
    marker=target/'hypr/conf/keybinds.conf'; marker.write_text('# local test\n')
    out=run(home,'--upgrade','--no-packages','--dry-run')
    assert out.count('KEEP ALIAS ')==24 and 'KEEP packages/debian.txt' in out and 'CONFLICT' not in out,out
    run(home,'--upgrade','--no-packages')
    assert all((target/a).is_symlink() for a in FIELD_ALIASES)
    assert local.read_text()=='# local list\nexample-package\n' and marker.read_text()=='# local test\n'
    # Genuine modified canonical SVG must remain a conflict, not be overwritten.
    a,c=next(iter(FIELD_ALIASES.items())); canonical=target/c
    original=canonical.read_bytes();canonical.write_text('<svg/>')
    out=run(home,'--upgrade','--no-packages','--dry-run',ok=False)
    assert 'CONFLICT '+a in out and canonical.read_text()=='<svg/>'
    canonical.write_bytes(original)
    # A same-content file outside the expected path is not a trusted alias.
    alias=target/a;alias.unlink(); outside=home/'outside.svg';outside.write_bytes(original);alias.symlink_to(outside)
    out=run(home,'--upgrade','--no-packages','--dry-run',ok=False)
    assert 'CONFLICT '+a in out
    alias.unlink();alias.symlink_to('missing.svg')
    assert 'CONFLICT '+a in run(home,'--upgrade','--no-packages','--dry-run',ok=False)
    print('PASS: fresh, 24 historical aliases, package list, protected config, upgrade, modified canonical, external and broken links')
