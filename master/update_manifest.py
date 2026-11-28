#!/usr/bin/env python3
"""Refresh an existing clean release manifest, retaining historical fingerprints.
Add new reviewed paths explicitly with --add. Never run on an installed tree.
"""
import argparse, json, os, sys
from pathlib import Path
sys.dont_write_bytecode = True
from install import ROOT, TARGET, MANIFEST, signature, within

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--add', action='append', default=[])
    a=p.parse_args()
    if ROOT == TARGET.resolve() or (ROOT/'state/current_theme').exists():
        raise SystemExit('Refusing to regenerate installed/runtime tree')
    m=json.loads(MANIFEST.read_text()); old=m['files']; known=m['known']; files={}
    for rel in sorted(set(old) | set(a.add)):
        path=ROOT/rel
        if (Path(rel).is_absolute() or '..' in Path(rel).parts or not within(path,ROOT)
            or rel=='master/manifest.json' or Path(rel).parts[0] in ('state','backups','fonts','.git','local')
            or any(part in ('__pycache__','.git','backups') for part in Path(rel).parts)
            or path.suffix.lower() in ('.ttf','.otf','.woff','.woff2','.pem','.key','.pyc')
            or path.name.startswith('.env')):
            raise SystemExit('Unsafe or private path: '+rel)
        new=signature(path)
        if new is None: raise SystemExit('Missing managed file (review removals explicitly): '+rel)
        files[rel]=new
        known[rel]=sorted(set(known.get(rel,[])) | {new} | ({old[rel]} if rel in old else set()))
    m.update(files=files,known=known,version=(ROOT/'VERSION').read_text().strip())
    temp=MANIFEST.with_suffix('.tmp');temp.write_text(json.dumps(m,indent=2,sort_keys=True)+'\n');os.replace(temp,MANIFEST)
    print('Manifest refreshed:', len(files), 'files. Review diff before release.')
if __name__=='__main__':main()
