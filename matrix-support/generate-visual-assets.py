#!/usr/bin/env python3
"""Reproducible original static geometric backgrounds; build only (Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance
import math
W,H=2560,1600
out=Path(__file__).resolve().parents[1]/'themes/swirldesk-matrix/wallpapers'
out.mkdir(parents=True,exist_ok=True)
def bg(kind):
    im=Image.new('RGB',(W,H)); pix=im.load()
    for y in range(H):
        for x in range(W):
            nx=(x-W/2)/(W/2); ny=(y-H/2)/(H/2)
            if kind=='clean':
                f=math.exp(-2.2*(nx*nx+ny*ny)); pix[x,y]=(int(4+3*f),int(7+9*f),int(5+5*f))
            else:
                f=math.exp(-1.35*(nx*nx+ny*ny)); pix[x,y]=(round(112+57*f),round(125+54*f),round(115+55*f))
    return im
im=bg('clean'); d=ImageDraw.Draw(im)
# Quiet technical registration marks in the corners, not a faux application.
for x,y,sx,sy in [(76,76,1,1),(W-76,76,-1,1),(76,H-76,1,-1),(W-76,H-76,-1,-1)]:
    d.line([(x+sx*70,y),(x,y),(x,y+sy*70)],fill=(23,49,32),width=2)
for i in range(7):
    x=W//2-36+i*12; d.line((x,H//2-2,x,H//2+2),fill=(28,56,37),width=2)
im.save(out/'matrix-clean.png',optimize=True)
im=bg('construct')
# Soft, sage-grey simulation space: preserve the horizon, with local contrast
# rather than bright fixed-color lines. Vignette is built into the gradient.
mask=Image.new('L',(W,H),0); d=ImageDraw.Draw(mask)
horizon=H//2+160; cx=W//2
for x in range(-W*2,W*3,320):
    d.line((cx,horizon,x,H),fill=160,width=1)
for offset in (25,52,90,145,225,335,485):
    if horizon+offset<H: d.line((0,horizon+offset,W,horizon+offset),fill=105,width=1)
d.line((0,horizon,W,horizon),fill=80,width=1)
im=Image.composite(ImageEnhance.Brightness(im).enhance(0.90),im,mask)
im.save(out/'matrix-construct.png',optimize=True)
