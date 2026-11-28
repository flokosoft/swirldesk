import importlib.util, json, os, shutil, subprocess, tempfile, unittest, sys
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[3]
D=ROOT/'themes/swirldesk-matrix/session/digital'
sys.path.insert(0,str(D))
import controller as c
class TestSession(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(); self.t=Path(self.tmp.name)
  self.state=self.t/'state'; self.state.mkdir(); self.theme=self.t/'theme'; self.theme.mkdir(); (self.theme/'waybar').mkdir(); (self.theme/'waybar/config').write_text('session/digital/profile-status.sh'); (self.state/'current_theme').symlink_to(self.theme); (self.state/'current_theme_name').write_text('swirldesk-matrix')
  self.p=patch.multiple(c,STATE=self.state,PREF=self.state/'prefs.json',THEME=self.theme); self.p.start()
 def tearDown(self): self.p.stop(); self.tmp.cleanup()
 def test_defaults_and_invalid(self):
  self.assertEqual(c.prefs(),c.DEFAULT); c.PREF.write_text('{"intro":1,"saver":600,"sound":true}'); self.assertEqual(c.prefs(),{**c.DEFAULT,'sound':True}); c.PREF.write_text('[]');self.assertEqual(c.prefs(),c.DEFAULT)
 def test_preferences(self):
  c.save('saver',180);c.save('sound',True);self.assertEqual(c.prefs(),{**c.DEFAULT,'saver':180,'sound':True})
 def test_active(self):
  self.assertTrue(c.active()); (self.theme/'waybar/config').write_text('old');self.assertFalse(c.active());(self.theme/'waybar/config').write_text('session/digital/profile-status.sh');(self.state/'current_theme_name').write_text('field');self.assertFalse(c.active())
 def test_idle_args(self):
  a=c.idle_command(180,self.t,'abc');self.assertEqual(a[:6],['swayidle','-C','/dev/null','-w','timeout','180']);self.assertIn('idle-on abc',a[6]);self.assertIn('idle-off abc',a[8]);self.assertNotIn('lock-session',' '.join(a))
 def test_runtime_scope(self):
  with patch.dict(os.environ,{'XDG_RUNTIME_DIR':str(self.t),'WAYLAND_DISPLAY':'wayland-1','HYPRLAND_INSTANCE_SIGNATURE':'a'}):
   a=c.runtime();self.assertEqual(a,c.runtime());os.environ['HYPRLAND_INSTANCE_SIGNATURE']='b';self.assertNotEqual(a,c.runtime())
 def test_idle_token(self):
  run=self.t/'run';run.mkdir();(run/'token').write_text('fresh')
  with patch.object(c,'runtime',return_value=run),patch.object(sys,'argv',['ctl','idle-on','stale']):self.assertEqual(c.main(),0);self.assertFalse((run/'idle').exists())
  with patch.object(c,'runtime',return_value=run),patch.object(sys,'argv',['ctl','idle-on','fresh']):self.assertEqual(c.main(),0);self.assertEqual((run/'idle').read_text(),'fresh')
  with patch.object(c,'runtime',return_value=run),patch.object(sys,'argv',['ctl','idle-off','fresh']):self.assertEqual(c.main(),0);self.assertFalse((run/'idle').exists())
 def test_kick_inactive(self):
  with patch.object(c,'active',return_value=False),patch.object(c.subprocess,'Popen') as p:c.kick(self.t);p.assert_not_called()
 def test_battery_no_worker_after_intro(self):
  (self.t/'intro-seen').touch();c.save('saver',180)
  with patch.object(c,'on_ac',return_value=False),patch.object(c.shutil,'which',return_value='/usr/bin/swayidle'),patch.object(c.subprocess,'Popen') as p:c.kick(self.t);p.assert_not_called()
 def test_exit_optout(self):
  c.save('exit',False)
  with patch.object(c,'runtime',return_value=self.t),patch.object(c,'preview') as p,patch.object(sys,'argv',['ctl','exit']):self.assertEqual(c.main(),0);p.assert_not_called()
if __name__=='__main__':unittest.main()
