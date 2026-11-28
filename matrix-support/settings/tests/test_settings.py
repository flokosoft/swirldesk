import importlib.util, unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('settings',ROOT/'themes/swirldesk-matrix/settings/settings.py'); s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)
class SettingsTest(unittest.TestCase):
 def test_presets(self):
  for n,(r,c,i) in s.PRESETS.items():
   with patch.object(s,'apply') as a:s.preset(n);a.assert_called_once_with({'rain':r,'crt':c,'saver':str(i) if i else 'off'})
   self.assertEqual(s.preset_name({'rain':r,'crt':c,'saver':str(i) if i else 'off'}),n)
 def test_custom(self):self.assertEqual(s.preset_name({'rain':'on','crt':'strong','saver':'300'}),'custom')
 def test_no_changes_when_inactive(self):
  with patch.object(s.session,'active',return_value=False),patch.object(s,'run') as r:
   with self.assertRaises(RuntimeError):s.change('crt','soft')
   r.assert_not_called()
 def test_apply_only_changed(self):
  with patch.object(s,'require_active'),patch.object(s,'snapshot',return_value={'rain':'off','crt':'off'}),patch.object(s,'change') as c:
   s.apply({'rain':'on','crt':'off'});c.assert_called_once_with('rain','on')
 def test_invalid_no_changes(self):
  with patch.object(s,'require_active'),patch.object(s,'change') as c:
   with self.assertRaises(ValueError):s.apply({'rain':'on','crt':'invalid'})
   c.assert_not_called()
 def test_partial_error(self):
  with patch.object(s,'require_active'),patch.object(s,'snapshot',return_value={'rain':'off','crt':'off'}),patch.object(s,'change',side_effect=[None,RuntimeError('test error')]):
   with self.assertRaisesRegex(RuntimeError,'Applied before error: rain'):s.apply({'rain':'on','crt':'soft'})
 def test_dispatch(self):
  with patch.object(s,'require_active'),patch.object(s,'run') as r:
   s.change('crt','classic');r.assert_called_once_with([s.THEME/'visual/crt/ctl.sh','classic'])
 def test_snapshot_defaults(self):
  with patch.object(s,'read',return_value=''),patch.object(s.session,'prefs',return_value=s.session.DEFAULT):
   self.assertEqual(s.snapshot(),{'profile':'code-rain','rain':'off','crt':'off','saver':'off','intro':'on','sound':'off','exit':'on'})
if __name__=='__main__':unittest.main()
