import sys, tempfile, unittest, shutil, subprocess, os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
RAIN=ROOT/'themes/swirldesk-matrix/visual/rain'
sys.path.insert(0,str(RAIN))
from policy import Rain, on_ac, eligible, COLORS, CELL, GLYPHS
class Tests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.r=Path(self.temp.name); self.p=self.r/'power'; self.p.mkdir()
        self.state=self.r/'state'; self.state.mkdir(); self.theme=self.r/'themes/swirldesk-matrix'; self.theme.mkdir(parents=True)
        (self.state/'current_theme').symlink_to(self.theme); self.write('current_theme_name','swirldesk-matrix'); self.write('matrix_rain_enabled','on'); self.write('matrix_visual_profile','code-rain'); self.write('current_wallpaper',str(self.theme/'wallpapers/matrix-code.png'))
    def tearDown(self): self.temp.cleanup()
    def write(self,k,v): (self.state/k).write_text(v+'\n')
    def supply(self,name,kind,online,scope='System'):
        d=self.p/name; d.mkdir(exist_ok=True)
        for k,v in [('type',kind),('online',online),('scope',scope)]: (d/k).write_text(v+'\n')
    def test_ac(self):
        self.assertFalse(on_ac(self.p)); self.supply('BAT0','Battery','1'); self.assertFalse(on_ac(self.p)); self.supply('AC','Mains','1'); self.assertTrue(on_ac(self.p)); self.supply('AC','Mains','0'); self.assertFalse(on_ac(self.p)); self.supply('USB','USB_C','1','Device'); self.assertFalse(on_ac(self.p)); self.supply('USB','USB_C','1'); self.assertTrue(on_ac(self.p)); self.assertFalse(on_ac(self.p/'missing'))
    def test_eligibility(self):
        self.assertTrue(eligible(self.r))
        for k,bad,good in [('current_theme_name','swirldesk-field','swirldesk-matrix'),('matrix_rain_enabled','off','on'),('matrix_visual_profile','construct','code-rain'),('current_wallpaper','/custom',str(self.theme/'wallpapers/matrix-code.png'))]:
            self.write(k,bad); self.assertFalse(eligible(self.r)); self.write(k,good); self.assertTrue(eligible(self.r))
        (self.state/'current_theme').unlink(); self.assertFalse(eligible(self.r))
    def test_simulation(self):
        r=Rain(1920,1080,seed=5); before=list(r.visible()); self.assertTrue(before)
        for _ in range(600):
            r.step(1/12)
            for x,y,ch,shade in r.visible():
                self.assertTrue(0<=x<1920 and 0<=y<=1080+CELL and ch in GLYPHS and 0<=shade<len(COLORS))
        self.assertNotEqual(before,list(r.visible()))
    def test_installer(self):
        support=self.r/'matrix-support/rain'; support.mkdir(parents=True); shutil.copytree(ROOT/'matrix-support/rain',support,dirs_exist_ok=True); dst=self.theme/'visual'; dst.mkdir(); shutil.copytree(RAIN,dst/'rain'); profile=dst/'profile.sh'; original=(support/'profile.original').read_bytes(); profile.write_bytes(original); profile.chmod(0o755)
        def call(a): return subprocess.run([sys.executable,str(support/'manage.py'),a],capture_output=True,env={**os.environ,'HYPRLAND_INSTANCE_SIGNATURE':''})
        self.assertEqual(call('apply').returncode,0); self.assertEqual(profile.read_bytes(),(support/'profile.new').read_bytes()); self.assertEqual(call('apply').returncode,0); self.assertEqual(call('doctor').returncode,0); self.assertEqual(call('restore').returncode,0); self.assertEqual(profile.read_bytes(),original); self.assertEqual((self.state/'matrix_rain_enabled').read_text().strip(),'off'); profile.write_text('# custom'); self.assertNotEqual(call('apply').returncode,0); self.assertEqual(profile.read_text(),'# custom')
    def test_profile_menu(self):
        home=self.r/'home'; root=home/'.config/swirldesk'; theme=root/'themes/swirldesk-matrix'; visual=theme/'visual'; visual.mkdir(parents=True); shutil.copytree(RAIN,visual/'rain'); profile=visual/'profile.sh'; shutil.copy2(ROOT/'matrix-support/rain/profile.new',profile); profile.chmod(0o755)
        state=root/'state'; state.mkdir(); (state/'current_theme').symlink_to(theme); (state/'current_theme_name').write_text('swirldesk-matrix'); (theme/'wallpapers').mkdir();
        for name in ('matrix-clean.png','matrix-code.png','matrix-construct.png'): (theme/'wallpapers'/name).write_text('mock')
        bin=home/'bin'; bin.mkdir()
        for name,body in {'pkill':'exit 0','swaybg':'sleep 0.6','fuzzel':'printf "%s\\n" "$CHOICE"','notify-send':'exit 0'}.items():
            f=bin/name; f.write_text('#!/bin/sh\n'+body+'\n'); f.chmod(0o755)
        env={**os.environ,'HOME':str(home),'PATH':str(bin)+':'+os.environ['PATH'],'WAYLAND_DISPLAY':'mock','HYPRLAND_INSTANCE_SIGNATURE':''}
        def choose(choice): return subprocess.run(['bash',str(profile)],env=env|{'CHOICE':choice},capture_output=True,timeout=5)
        self.assertEqual(choose('CODE RAIN LIVE // ANIMATION (AC ONLY)').returncode,0); self.assertEqual((state/'matrix_rain_enabled').read_text().strip(),'on'); self.assertEqual((state/'matrix_visual_profile').read_text().strip(),'code-rain')
        self.assertEqual(choose('CONSTRUCT // SOFT SPACE').returncode,0); self.assertEqual((state/'matrix_rain_enabled').read_text().strip(),'on'); self.assertFalse(eligible(root))
        self.assertEqual(choose('CODE RAIN // DIGITAL STREAM').returncode,0); self.assertEqual((state/'matrix_rain_enabled').read_text().strip(),'off'); self.assertFalse(eligible(root))
if __name__=='__main__': unittest.main()
