import os, shutil, subprocess, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
T=Path('themes/swirldesk-matrix')
class VisualTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.home=Path(self.tmp.name); self.r=self.home/'.config/swirldesk'; self.r.mkdir(parents=True)
        shutil.copytree(ROOT/T,self.r/T); shutil.copytree(ROOT/'matrix-support',self.r/'matrix-support'); (self.r/'scripts').mkdir(); self.state=self.r/'state'; self.state.mkdir()
        (self.state/'current_theme').symlink_to(self.r/T); (self.state/'current_theme_name').write_text('swirldesk-matrix\n'); self.bin=self.home/'bin'; self.bin.mkdir()
        for name,script in {'pkill':'exit 0','swaybg':'if [ "${FAIL_SWAYBG:-0}" = 1 ]; then exit 1; fi\nprintf "%s\\n" "$*" >> "$HOME/swaybg.log"\nsleep 1', 'notify-send':'exit 0','fuzzel':'printf "%s\\n" "${CHOICE:-}"'}.items():
            p=self.bin/name; p.write_text('#!/bin/sh\n'+script+'\n'); p.chmod(0o755)
        self.env=dict(os.environ, HOME=str(self.home),PATH=str(self.bin)+':'+os.environ['PATH'],WAYLAND_DISPLAY='mock')
    def tearDown(self): self.tmp.cleanup()
    def run_script(self,p,*args,**env): return subprocess.run(['bash',str(p),*args],env=self.env|env,capture_output=True,text=True,timeout=10)
    def profile(self,*args,**env): return self.run_script(self.r/T/'visual/profile.sh',*args,**env)
    def test_select_restore_and_custom(self):
        self.assertEqual(self.profile('--current').stdout.strip(),'code-rain')
        for p,n in [('clean','matrix-clean.png'),('construct','matrix-construct.png'),('code-rain','matrix-code.png')]:
            self.assertEqual(self.profile('--apply',p).returncode,0)
            self.assertEqual((self.state/'current_wallpaper').read_text().strip(),str(self.r/T/'wallpapers'/n))
            self.assertEqual(self.profile('--current').stdout.strip(),p)
        self.assertEqual(self.profile(CHOICE='CONSTRUCT // WHITE SPACE').returncode,0)
        self.assertEqual(self.profile('--status').stdout.strip(),'CONSTRUCT')
        (self.state/'current_wallpaper').write_text('/custom.png\n'); self.assertEqual(self.profile('--status').stdout.strip(),'CUSTOM')
        self.assertEqual(self.profile('--restore').returncode,0); self.assertEqual(self.profile('--status').stdout.strip(),'CONSTRUCT')
    def test_reject_and_failure(self):
        self.assertNotEqual(self.profile('--apply','../x').returncode,0)
        self.assertNotEqual(self.profile('--apply','clean',FAIL_SWAYBG='1').returncode,0)
        self.assertFalse((self.state/'matrix_visual_profile').exists())
        self.assertEqual(self.profile().returncode,0); self.assertFalse((self.state/'matrix_visual_profile').exists())
        (self.state/'current_theme_name').write_text('swirldesk-field\n'); self.assertNotEqual(self.profile('--apply','clean').returncode,0); self.assertFalse((self.state/'current_wallpaper').exists())
    def test_theme_roundtrip(self):
        # Minimal non-MATRIX theme, mocked compositor and commands.
        other=self.r/'themes/swirldesk-debian'; (other/'hypr').mkdir(parents=True)
        for name in ['colors.conf','appearance.conf','cursor.conf']: (other/'hypr'/name).write_text('# test')
        (other/'theme.conf').write_text('THEME_NAME="Debian"\n')
        for name in ['hyprctl','waybar','gsettings','gdbus']:
            p=self.bin/name; p.write_text('#!/bin/sh\nexit 0\n'); p.chmod(0o755)
        (self.bin/"gdbus").write_text("#!/bin/sh\necho true\n")
        (self.home/'.config/waybar').mkdir(); p=self.r/'scripts/dunst-start.sh'; p.write_text('#!/bin/sh\nexit 0\n'); p.chmod(0o755)
        old=self.home/'previous.png'; old.write_bytes(b'old')
        (self.state/'current_wallpaper').write_text(str(old)+'\n'); (self.state/'current_theme_name').write_text('swirldesk-debian\n'); (self.state/'current_theme').unlink(); (self.state/'current_theme').symlink_to(other)
        s=self.r/'matrix-support/theme-switcher.sh.profiles'
        self.assertEqual(self.run_script(s,CHOICE='swirldesk-matrix').returncode,0)
        self.assertEqual(self.profile('--apply','construct').returncode,0)
        self.assertEqual(self.run_script(s,CHOICE='swirldesk-debian').returncode,0)
        self.assertEqual((self.state/'current_wallpaper').read_text().strip(),str(old))
        self.assertEqual(self.run_script(s,CHOICE='swirldesk-matrix').returncode,0)
        self.assertEqual(self.profile('--status').stdout.strip(),'CONSTRUCT')
    def test_guarded_install_rollback(self):
        s=self.r/'matrix-support'; dest=self.r/'scripts/theme-switcher.sh'; original=(s/'theme-switcher.sh.matrix').read_bytes(); dest.write_bytes(original)
        self.assertEqual(self.run_script(s/'enable-profiles.sh').returncode,0); self.assertEqual(dest.read_bytes(),(s/'theme-switcher.sh.profiles').read_bytes())
        self.assertEqual(self.run_script(s/'enable-profiles.sh').returncode,0); self.assertEqual(self.run_script(s/'disable-profiles.sh').returncode,0); self.assertEqual(dest.read_bytes(),original)
        dest.write_text('# custom\n'); self.assertNotEqual(self.run_script(s/'enable-profiles.sh').returncode,0); self.assertEqual(dest.read_text(),'# custom\n')
if __name__=='__main__': unittest.main()
