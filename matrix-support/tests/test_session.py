import os, shutil, subprocess, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]; T=Path('themes/swirldesk-matrix'); S=Path('matrix-support')
class Session(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.home=Path(self.tmp.name); self.r=self.home/'.config/swirldesk'; self.r.mkdir(parents=True)
        shutil.copytree(ROOT/T,self.r/T); shutil.copytree(ROOT/S,self.r/S)
        for rel in ['scripts/power-menu.sh','bin/swirlfetch']:
            p=self.r/rel; p.parent.mkdir(); shutil.copy2(ROOT/S/(p.name+'.pre-session'),p)
        self.state=self.r/'state'; self.state.mkdir(); self.active=self.state/'current_theme_name'; self.active.write_text('swirldesk-matrix\n')
        self.b=self.home/'mock'; self.b.mkdir(); self.log=self.home/'commands'; self.env=dict(os.environ, HOME=str(self.home),PATH=str(self.b)+':'+os.environ['PATH'],HYPRLAND_INSTANCE_SIGNATURE='mock')
        for n in ('systemctl','hyprctl','hyprlock','loginctl','fastfetch','notify-send'):
            self.mock(n,'printf "%s %s\\n" "${0##*/}" "$*" >> "$HOME/commands"\nexit 0')
        self.mock('pgrep','exit "${NO_IDLE:-0}"'); self.mock('python3','exit 1')
        self.mock('fuzzel','cat >/dev/null\ncase " $* " in *VERIFY*) printf "%s\\n" "${CONFIRM:-CANCEL}";; *) printf "%s\\n" "${CHOICE:-}";; esac')
        for n in ('power-menu-fallback.sh','field-power-toggle.sh'):
            p=self.r/'scripts'/n; p.write_text('#!/bin/sh\necho original >> "$HOME/commands"\n');p.chmod(0o755)
    def tearDown(self): self.tmp.cleanup()
    def mock(self,n,c):
        p=self.b/n;p.write_text('#!/bin/sh\n'+c+'\n');p.chmod(0o755)
    def runsh(self,p,*args,**env):return subprocess.run(['bash',str(self.r/p),*args],env=self.env|env,capture_output=True,text=True,timeout=10)
    def action(self,*args,**env):return self.runsh(T/'session/action.sh',*args,**env)
    def logged(self): return self.log.read_text() if self.log.exists() else ''
    def test_confirm_and_guard(self):
        for a in ('suspend','logout','reboot','shutdown','bad'): self.assertNotEqual(self.action(a).returncode,0)
        self.assertEqual(self.logged(),''); self.assertEqual(self.action('lock').returncode,0); self.assertIn('hyprlock',self.logged())
        self.active.write_text('swirldesk-field\n'); self.assertNotEqual(self.action('reboot','--confirmed').returncode,0)
        self.active.write_text('swirldesk-matrix\n'); self.assertNotEqual(self.action('reboot','--confirmed',HYPRLAND_INSTANCE_SIGNATURE='').returncode,0); self.assertNotIn('systemctl',self.logged())
    def test_suspend_preconditions(self):
        self.assertNotEqual(self.action('suspend','--confirmed',NO_IDLE='1').returncode,0); self.assertNotIn('systemctl',self.logged())
        self.assertEqual(self.action('suspend','--confirmed').returncode,0); self.assertIn('loginctl lock-session\nsystemctl suspend',self.logged())
    def test_fallback_confirm_cancel(self):
        p=T/'session/fallback.sh'
        self.assertEqual(self.runsh(p,CHOICE='05 // SYSTEM SHUTDOWN').returncode,0); self.assertEqual(self.logged(),'')
        self.assertEqual(self.runsh(p,CHOICE='05 // SYSTEM SHUTDOWN',CONFIRM='CONFIRM shutdown').returncode,0); self.assertIn('systemctl poweroff',self.logged())
        self.assertEqual(self.runsh(p,CHOICE='03 // DISCONNECT (LOGOUT)',CONFIRM='CONFIRM logout').returncode,0); self.assertIn('hyprctl dispatch exit',self.logged())
    def test_dispatch_and_rollback(self):
        for _ in range(2):self.assertEqual(self.runsh(S/'enable-session.sh').returncode,0)
        self.assertEqual(self.runsh(Path('scripts/power-menu.sh'),CHOICE='01 // LOCK TERMINAL').returncode,0); self.assertIn('hyprlock',self.logged())
        self.assertEqual(self.runsh(Path('bin/swirlfetch'),'--version').returncode,0); self.assertIn('session/fastfetch.jsonc',self.logged())
        self.active.write_text('swirldesk-debian\n'); self.assertEqual(self.runsh(Path('scripts/power-menu.sh')).returncode,0); self.assertIn('original',self.logged())
        self.assertEqual(self.runsh(Path('bin/swirlfetch')).returncode,0); self.assertIn('/swirldesk/fastfetch/config.jsonc',self.logged())
        self.assertEqual(self.runsh(S/'rollback-session.sh').returncode,0)
        for rel in ('scripts/power-menu.sh','bin/swirlfetch'):
            p=self.r/rel;self.assertEqual(p.read_bytes(),(self.r/S/(p.name+'.pre-session')).read_bytes())
        self.assertEqual((self.r/T/'theme.conf').read_bytes(),(self.r/S/'pre-session'/T/'theme.conf').read_bytes())
    def test_custom_guard(self):
        p=self.r/'bin/swirlfetch'; p.write_text('# custom\n');self.assertNotEqual(self.runsh(S/'enable-session.sh').returncode,0);self.assertEqual(p.read_text(),'# custom\n'); self.assertEqual((self.r/'scripts/power-menu.sh').read_bytes(),(self.r/S/'power-menu.sh.pre-session').read_bytes())
if __name__=='__main__':unittest.main()
