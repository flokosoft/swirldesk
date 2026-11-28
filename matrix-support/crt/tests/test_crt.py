import sys, tempfile, unittest, shutil, subprocess, os
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[3]; CRT=ROOT/'themes/swirldesk-matrix/visual/crt'
sys.path.insert(0,str(CRT)); import controller as c
class Test(unittest.TestCase):
 def test_modes(self):
  for m in c.MODES[1:]:
   p=str(CRT/(m+'.frag')); self.assertEqual(c.decision(True,m,True,'[[EMPTY]]')[0],p); self.assertIsNone(c.decision(True,m,True,p)[0]); self.assertEqual(c.decision(True,m,False,p)[0],''); self.assertEqual(c.decision(False,m,True,p)[0],''); self.assertEqual(c.decision(True,'off',True,p)[0],'')
 def test_foreign(self):
  for a in (True,False):
   for m in c.MODES:
    for ac in (True,False): self.assertIsNone(c.decision(a,m,ac,'/other/shader.frag')[0])
 def test_switch(self):
  self.assertEqual(c.decision(True,'strong',True,str(CRT/'soft.frag'))[0],str(CRT/'strong.frag'))
 def test_power_and_state(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d); state=root/'state'; state.mkdir(); theme=root/'themes/swirldesk-matrix'; theme.mkdir(parents=True); (state/'current_theme').symlink_to(theme); (state/'current_theme_name').write_text('swirldesk-matrix')
   self.assertTrue(c.matrix_active(root)); self.assertEqual(c.preference(root),'off'); c.save('classic',root); self.assertEqual(c.preference(root),'classic'); (state/'current_theme_name').write_text('swirldesk-field'); self.assertFalse(c.matrix_active(root))
   p=root/'power'; p.mkdir(); ac=p/'AC'; ac.mkdir(); (ac/'type').write_text('Mains'); (ac/'online').write_text('1'); self.assertTrue(c.on_ac(p)); (ac/'online').write_text('0'); self.assertFalse(c.on_ac(p)); (ac/'online').write_text('1'); (ac/'scope').write_text('Device'); self.assertFalse(c.on_ac(p)); self.assertFalse(c.on_ac(p/'no'))
 def test_runtime_readback(self):
  with patch.object(c,'run',side_effect=['ok','{"str":"[[EMPTY]]"}']) as r:
   c.set_shader(''); self.assertEqual(r.call_args_list[0].args[0],['keyword',c.OPTION,'[[EMPTY]]'])
  with patch.object(c,'run',side_effect=['ok','{"str":"/wrong"}']):
   with self.assertRaises(RuntimeError): c.set_shader('/right')
  with patch.object(c,'current',return_value='/foreign'),patch.object(c,'set_shader') as s: c.clear_owned(); s.assert_not_called()
 def test_installer(self):
  with tempfile.TemporaryDirectory() as d:
   r=Path(d); s=r/'matrix-support/crt'; s.mkdir(parents=True); shutil.copytree(ROOT/'matrix-support/crt',s,dirs_exist_ok=True); v=r/'themes/swirldesk-matrix/visual'; v.mkdir(parents=True); shutil.copytree(CRT,v/'crt'); rain=s.parent/'rain'; rain.mkdir(); orig=(s/'profile.original').read_bytes(); new=(s/'profile.new').read_bytes(); a=v/'profile.sh'; b=rain/'profile.new'; a.write_bytes(orig); b.write_bytes(orig)
   def run(op): return subprocess.run([sys.executable,str(s/'manage.py'),op],capture_output=True,env={**os.environ,'HYPRLAND_INSTANCE_SIGNATURE':''})
   self.assertEqual(run('apply').returncode,0); self.assertEqual(a.read_bytes(),new); self.assertEqual(b.read_bytes(),new); self.assertEqual(run('apply').returncode,0); self.assertEqual(run('doctor').returncode,0); self.assertEqual(run('restore').returncode,0); self.assertEqual(a.read_bytes(),orig); self.assertEqual(b.read_bytes(),orig); b.write_text('#custom'); self.assertNotEqual(run('apply').returncode,0); self.assertEqual(a.read_bytes(),orig)
if __name__=='__main__': unittest.main()
