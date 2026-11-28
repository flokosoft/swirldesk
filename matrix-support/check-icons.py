#!/usr/bin/env python3
from pathlib import Path
import json, configparser, xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
t=root/'themes/swirldesk-matrix'; i=t/'icons/SwirlDesk-MATRIX'
m=json.loads((root/'matrix-support/icon-manifest.json').read_text())
idx=configparser.ConfigParser(); idx.read(i/'index.theme'); dirs=idx['Icon Theme']['Directories'].split(',')
assert set(m)=={str(p.relative_to(i)) for p in i.rglob('*.svg')}
for name in m:
    p=i/name; assert str(Path(name).parent) in dirs
    e=ET.parse(p).getroot(); assert e.attrib['viewBox']=='0 0 24 24'; assert e[0].attrib['stroke']=='#78d99a'
assert 'gtk-icon-theme-name=SwirlDesk-MATRIX' in (t/'gtk/settings.ini').read_text()
assert 'icon-theme=SwirlDesk-MATRIX' in (t/'fuzzel/fuzzel.ini').read_text()
for key,value in json.loads((t/'waybar/config').read_text())['tray']['icons'].items():
    assert value.startswith('$HOME/.config/swirldesk/') and (root/value.removeprefix('$HOME/.config/swirldesk/')).is_file(),key
print(f'INFO     {len(m)} SVG icon aliases, {len(set(m.values()))} original glyph designs')
