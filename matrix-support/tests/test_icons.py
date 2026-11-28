import json, os, shutil, subprocess, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]; T=Path('themes/swirldesk-matrix'); S=Path('matrix-support')
class Icons(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.home=Path(self.tmp.name); self.r=self.home/'.config/swirldesk'; self.r.mkdir(parents=True)
        shutil.copytree(ROOT/T,self.r/T); shutil.copytree(ROOT/S,self.r/S)
        (self.r/'scripts').mkdir(); self.d=self.r/'scripts/theme-switcher.sh'; shutil.copy2(self.r/S/'theme-switcher.sh.profiles',self.d)
        self.link=self.home/'.local/share/icons/SwirlDesk-MATRIX'; self.state=self.r/'state'; self.state.mkdir()
        (self.state/'current_theme_name').write_text('swirldesk-debian\n'); (self.state/'current_theme').symlink_to(self.r/T)
        self.bin=self.home/'bin'; self.bin.mkdir(); self.env=dict(os.environ, HOME=str(self.home),PATH=str(self.bin)+':'+os.environ['PATH'],WAYLAND_DISPLAY='mock')
        for n,s in {'pkill':'exit 0','swaybg':'sleep 0.6','notify-send':'exit 0','fuzzel':'printf "%s\\n" "$CHOICE"','hyprctl':'exit 0','waybar':'exit 0','gdbus':'echo true','gsettings':'printf "%s\\n" "$*" >> "$HOME/gsettings.log"'}.items():
            p=self.bin/n;p.write_text('#!/bin/sh\n'+s+'\n');p.chmod(0o755)
        (self.home/'.config/waybar').mkdir(); p=self.r/'scripts/dunst-start.sh';p.write_text('#!/bin/sh\nexit 0\n');p.chmod(0o755)
        for name,icon in [('swirldesk-debian','Papirus-Dark'),('swirldesk-field','SwirlDesk-FIELD')]:
            other=self.r/'themes'/name;(other/'hypr').mkdir(parents=True);(other/'gtk').mkdir()
            for f in ['colors.conf','appearance.conf','cursor.conf']:(other/'hypr'/f).write_text('# test')
            (other/'gtk/settings.ini').write_text('[Settings]\ngtk-icon-theme-name='+icon+'\n');(other/'theme.conf').write_text('THEME_NAME="test"\n')
    def tearDown(self):self.tmp.cleanup()
    def runsh(self,p,**env):return subprocess.run(['bash',str(p)],env=self.env|env,capture_output=True,text=True,timeout=10)
    def test_enable_idempotent_rollback(self):
        original=self.d.read_bytes()
        for _ in range(2):self.assertEqual(self.runsh(self.r/S/'enable-icons.sh').returncode,0)
        self.assertEqual(self.link.resolve(),self.r/T/'icons/SwirlDesk-MATRIX')
        # 0.5 must be rolled back first because it owns the newer Waybar/theme files.
        if (self.r/S/'rollback-session.sh').exists():
            (self.r/'bin').mkdir()
            for rel in ('scripts/power-menu.sh','bin/swirlfetch'):
                dest=self.r/rel; shutil.copy2(self.r/S/(dest.name+'.pre-session'),dest)
            self.assertEqual(self.runsh(self.r/S/'rollback-session.sh').returncode,0)
        self.assertEqual(self.runsh(self.r/S/'disable-icons.sh').returncode,0)
        self.assertEqual(self.d.read_bytes(),original);self.assertFalse(self.link.exists());self.assertIn('Papirus-Dark',(self.r/T/'gtk/settings.ini').read_text())
    def test_custom_switcher_and_link_guard(self):
        self.d.write_text('# custom\n');self.assertNotEqual(self.runsh(self.r/S/'enable-icons.sh').returncode,0);self.assertFalse(self.link.exists());self.assertEqual(self.d.read_text(),'# custom\n')
        shutil.copy2(self.r/S/'theme-switcher.sh.profiles',self.d); self.link.mkdir(parents=True);self.assertNotEqual(self.runsh(self.r/S/'enable-icons.sh').returncode,0);self.assertTrue(self.link.is_dir());self.assertFalse(self.link.is_symlink())
    def test_roundtrip(self):
        self.assertEqual(self.runsh(self.r/S/'enable-icons.sh').returncode,0)
        for name,expected in [('swirldesk-matrix','SwirlDesk-MATRIX'),('swirldesk-field','SwirlDesk-FIELD'),('swirldesk-matrix','SwirlDesk-MATRIX'),('swirldesk-debian','Papirus-Dark')]:
            r=self.runsh(self.d,CHOICE=name);self.assertEqual(r.returncode,0,r.stderr)
            self.assertIn('gtk-icon-theme-name='+expected,(self.home/'.config/gtk-3.0/settings.ini').read_text());self.assertIn('set org.gnome.desktop.interface icon-theme '+expected,[line for line in (self.home/'gsettings.log').read_text().splitlines() if ' icon-theme ' in line][-1])
        log=(self.home/'gsettings.log').read_text();self.assertEqual(self.runsh(self.d,CHOICE='swirldesk-field').returncode,0);self.assertEqual((self.home/'gsettings.log').read_text(),log)
    def test_asset_integrity(self):
        r=subprocess.run(['python3',str(self.r/S/'check-icons.py')],capture_output=True,text=True);self.assertEqual(r.returncode,0,r.stderr)
        cfg=json.loads((self.r/T/'waybar/config').read_text());self.assertNotIn('chrome_status_icon_1',cfg['tray']['icons'])
if __name__=='__main__':unittest.main()
