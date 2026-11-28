"""Pure local policy and rain simulation, no GTK dependency."""
from pathlib import Path
import random

GLYPHS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉ'
CELL = 24
FPS = 12
COLORS = ((.018,.105,.044),(.025,.19,.075),(.035,.31,.12),(.055,.48,.18),(.12,.69,.28),(.48,.91,.60))

def text(path):
    try: return path.read_text().strip()
    except (OSError, UnicodeError): return ''

def eligible(root):
    state=root/'state'; theme=root/'themes/swirldesk-matrix'
    try: same=(state/'current_theme').resolve(strict=True)==theme.resolve(strict=True)
    except (OSError, RuntimeError): same=False
    return (same and text(state/'current_theme_name')=='swirldesk-matrix'
            and text(state/'matrix_rain_enabled')=='on'
            and (text(state/'matrix_visual_profile') or 'code-rain')=='code-rain'
            and text(state/'current_wallpaper')==str(theme/'wallpapers/matrix-code.png'))

def on_ac(power=Path('/sys/class/power_supply')):
    # Fail closed: only a positively online external supply allows animation.
    try: devices=list(power.iterdir())
    except OSError: return False
    for dev in devices:
        kind=text(dev/'type')
        if (kind in ('Mains','Wireless') or kind.startswith('USB')) and text(dev/'scope')!='Device' and text(dev/'online')=='1':
            return True
    return False

class Rain:
    def __init__(self,width,height,seed=None):
        self.width=width; self.height=height; self.rng=random.Random(seed)
        self.rows=max(1,height//CELL+1)
        self.columns=[self.new(x,True) for x in range(0,width,CELL)]
    def new(self,x,initial=False):
        r=self.rng
        return [x,r.uniform(-self.rows,self.rows) if initial else r.uniform(-self.rows*.65,-1),r.uniform(4,12),r.randint(7,18),[r.choice(GLYPHS) for _ in range(19)]]
    def step(self,dt):
        for i,col in enumerate(self.columns):
            col[1]+=col[2]*min(max(dt,0),.25)
            if col[1]-col[3]>self.rows:
                self.columns[i]=self.new(col[0]); continue
            if self.rng.random()<.30:
                col[4][self.rng.randrange(len(col[4]))]=self.rng.choice(GLYPHS)
    def visible(self):
        for x,head,speed,length,glyphs in self.columns:
            h=int(head)
            for i in range(length):
                y=h-i
                if 0<=y<self.rows:
                    shade=5 if i==0 else max(0,4-int(5*i/length))
                    yield x,y*CELL,glyphs[i],shade
