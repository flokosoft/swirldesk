#!/usr/bin/env python3
"""Read-only inventory of a SwirlDesk source or installed tree (no GUI or power actions)."""
import argparse
import json
import shutil
import sys
from pathlib import Path
sys.dont_write_bytecode = True
import install as engine


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source', action='store_true', help='check clean release source instead of installed tree')
    a = p.parse_args()
    root = engine.ROOT if a.source else engine.TARGET
    if not root.is_dir() or root.is_symlink():
        print('MISMATCH invalid tree:', root)
        return 1
    try:
        m = json.loads((root/'master/manifest.json').read_text())
    except (OSError, ValueError) as e:
        print('MISMATCH manifest:', e)
        return 1
    print('SWIRLDESK // MASTER DOCTOR', m['version'], '(source)' if a.source else '(installed)')
    ok = keep = bad = 0
    for rel, expected in m['files'].items():
        path = root/rel
        if not engine.within(path, root):
            print('MISMATCH unsafe path', rel); bad += 1; continue
        actual = engine.signature(path)
        if actual == expected:
            ok += 1; continue
        if not a.source and actual is not None and (engine.protected(rel) or (rel == 'packages/debian.txt' and path.is_file() and not path.is_symlink())):
            print('KEEP local configuration', rel); keep += 1; continue
        if not a.source and rel in engine.FIELD_ALIASES and path.is_symlink():
            canonical = root/engine.FIELD_ALIASES[rel]
            try:
                raw = Path(path.readlink())
                if (not raw.is_absolute() and '..' not in raw.parts and engine.within(canonical, root)
                    and not canonical.is_symlink() and canonical.is_file() and path.resolve(strict=True) == canonical
                    and engine.signature(canonical) == expected):
                    print('KEEP verified FIELD alias', rel); keep += 1; continue
            except (OSError, RuntimeError, ValueError):
                pass
        print('MISMATCH missing/changed', rel); bad += 1
    if not a.source:
        try:
            name = (root/'state/current_theme_name').read_text().strip()
            active = root/'state/current_theme'
            if name not in ('swirldesk-debian','swirldesk-graphite','swirldesk-field','swirldesk-matrix') or not active.is_symlink() or not active.is_dir() or active.resolve() != root/'themes'/name:
                raise ValueError('inconsistent active theme')
            print('OK active Hyprland theme:', name)
        except (OSError, ValueError, RuntimeError) as e:
            print('MISMATCH theme state:', e); bad += 1
        for command in ('hyprctl','waybar','fuzzel','kitty','hyprlock','hypridle','swaybg','swayidle','paplay','fastfetch','plasmashell','qdbus6'):
            print('INFO', command, shutil.which(command) or 'not found (check applicable session/dependencies)')
        print('INFO component runtime checks are separate; no compositor or power commands executed.')
    print(f'MASTER // {ok} matching / {keep} local retained / {bad} issue(s)')
    return int(bool(bad))

if __name__ == '__main__':
    sys.exit(main())
