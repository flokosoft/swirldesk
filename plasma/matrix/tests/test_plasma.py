#!/usr/bin/env python3
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

HERE=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('matrix_manage',HERE/'manage.py')
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

class PlasmaTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.home=Path(self.temp.name); root=self.home/'.config/swirldesk'; data=self.home/'.local/share'
        self.patch=patch.multiple(m,HOME=self.home,CONF=self.home/'.config',DATA=data,ROOT=root,STATE=root/'state/plasma_matrix',BACKUPS=root/'backups/plasma-matrix',TRAY_SYS=self.home/'system-tray')
        self.patch.start(); self.addCleanup(self.patch.stop)
        for name in m.PROFILES.values():
            f=root/'themes/swirldesk-matrix/wallpapers'/name; f.parent.mkdir(parents=True,exist_ok=True); f.write_bytes(b'wallpaper test')
        self.p=m.paths(); self.p['cfg-kdeglobals'].parent.mkdir(parents=True,exist_ok=True); self.p['cfg-kdeglobals'].write_text('ORIGINAL KDE CONFIG\n')
        self.p['cfg-plasma-org.kde.plasma.desktop-appletsrc'].write_text('ORIGINAL PANEL AND WALLPAPER\n')
        (m.CONF/'kwinrc').write_text('KEEP KWIN'); (m.CONF/'kglobalshortcutsrc').write_text('KEEP SHORTCUTS')
        for t in ('label','pager'):
            f=self.p['field-'+t]; f.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(HERE/f'compat/original-field{t}.qml',f)
        self.local=self.p['tray']/m.TRAY_REL; self.local.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(HERE/'tray/original-field-StatusNotifierItem.qml',self.local)
        self.commands=[]; self.running=True
        self.fake=patch.multiple(m,live_session=lambda:None,shell_active=lambda:self.running,stop_shell=self.stop,start_shell=self.start,run=self.run_cmd,kw=self.write_kw,refresh=lambda:None)
        self.fake.start(); self.addCleanup(self.fake.stop)
    def stop(self): self.running=False
    def start(self): self.running=True
    def write_kw(self,file,groups,key,value):
        with (m.CONF/file).open('a') as f: f.write(f'{groups}/{key}={value}\n')
    def run_cmd(self,*args,**kw):
        self.commands.append(tuple(str(x) for x in args)); cmd=args[0]
        if cmd=='plasmashell': return subprocess.CompletedProcess(args,0,'plasmashell 6.3.5\n','')
        if cmd=='plasma-apply-colorscheme': self.write_kw('kdeglobals',['General'],'ColorScheme',args[1])
        if cmd=='plasma-apply-desktoptheme': self.write_kw('plasmarc',['Theme'],'name',args[1])
        if cmd=='plasma-apply-wallpaperimage': self.p['cfg-plasma-org.kde.plasma.desktop-appletsrc'].write_text(str(args[1]))
        return subprocess.CompletedProcess(args,0,'','')
    def check_untouched(self):
        self.assertEqual((m.CONF/'kwinrc').read_text(),'KEEP KWIN'); self.assertEqual((m.CONF/'kglobalshortcutsrc').read_text(),'KEEP SHORTCUTS')
    def test_apply_profile_restore(self):
        with contextlib.redirect_stdout(io.StringIO()):
            m.apply('code-rain'); self.assertTrue(self.running); state=m.current(); self.assertEqual(state['status'],'active'); self.assertEqual(set(state['applied']),{'field-label','field-pager','tray'})
            self.assertIn('MATRIX //',self.p['field-label'].read_text()); self.assertIn(m.MARK,self.local.read_text()); self.assertIn('#b4dcc1',self.local.read_text())
            self.assertTrue(self.p['scheme'].is_file()); self.assertTrue(self.p['session-entry'].is_file()); self.check_untouched()
            m.profile('construct'); self.assertEqual(m.current()['profile'],'construct'); self.assertIn('matrix-construct.png',self.p['cfg-plasma-org.kde.plasma.desktop-appletsrc'].read_text())
            self.assertIn('matrix-code.png',self.p['cfg-kscreenlockerrc'].read_text()); self.assertEqual(state['backup'],m.current()['backup'])
            m.restore()
        self.assertTrue(self.running); self.assertIsNone(m.current()); self.assertEqual(self.p['cfg-kdeglobals'].read_text(),'ORIGINAL KDE CONFIG\n'); self.assertEqual(self.p['cfg-plasma-org.kde.plasma.desktop-appletsrc'].read_text(),'ORIGINAL PANEL AND WALLPAPER\n'); self.assertFalse(self.p['cfg-kscreenlockerrc'].exists()); self.assertFalse(self.p['icons'].exists()); self.assertEqual(self.local.read_bytes(),(HERE/'tray/original-field-StatusNotifierItem.qml').read_bytes()); self.check_untouched()
    def test_reapply_refused_baseline_preserved(self):
        with contextlib.redirect_stdout(io.StringIO()): m.apply('clean')
        old=m.current()['backup']
        with self.assertRaises(RuntimeError): m.apply('construct')
        self.assertEqual(m.current()['backup'],old)
    def test_custom_widget_and_tray_preserved(self):
        self.p['field-label'].write_text('custom label'); self.local.write_text('custom tray')
        with contextlib.redirect_stdout(io.StringIO()): m.apply('clean')
        state=m.current(); self.assertEqual(state['applied'],['field-pager']); self.assertEqual(self.local.read_text(),'custom tray'); self.assertEqual(self.p['field-label'].read_text(),'custom label')
    def test_unsupported_version(self): self.assertFalse(m.tray_compatible(self.local,'plasmashell 6.5.0')[0])
    def test_compatible_field_tray(self):
        for v in ('6.3.5','6.3.6'): self.assertTrue(m.tray_compatible(self.local,'plasmashell '+v)[0])
    def test_stock_compatible_only_supported_version(self):
        self.local.unlink(); f=m.TRAY_SYS/m.TRAY_REL; f.parent.mkdir(parents=True); f.write_text('AbstractItem Kirigami.Icon model.Icon model.Service onActivated onContextMenu')
        self.assertTrue(m.tray_compatible(self.local,'plasmashell 6.3.5')[0]); self.assertFalse(m.tray_compatible(self.local,'plasmashell 6.3.6')[0])
    def test_rollback_on_wallpaper_error(self):
        old=m.run
        def fail(*args,**kw):
            if args[0]=='plasma-apply-wallpaperimage': raise subprocess.CalledProcessError(1,args)
            return old(*args,**kw)
        with patch.object(m,'run',fail), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(subprocess.CalledProcessError): m.apply('clean')
        self.assertTrue(self.running); self.assertIsNone(m.current()); self.assertEqual(self.p['cfg-kdeglobals'].read_text(),'ORIGINAL KDE CONFIG\n'); self.assertFalse(self.p['icons'].exists()); self.check_untouched()
    def test_refuse_symlink(self):
        f=self.p['cfg-kdeglobals']; f.unlink(); target=self.home/'target'; target.write_text('untouched'); f.symlink_to(target)
        with self.assertRaises(RuntimeError): m.apply('clean')
        self.assertEqual(target.read_text(),'untouched'); self.assertIsNone(m.current()); self.assertTrue(self.running)
    def test_svg_and_metadata(self):
        for p in HERE.rglob('*.svg'): ET.parse(p)
        for p in HERE.rglob('metadata.json'): json.loads(p.read_text())
        q=(HERE/'tray/StatusNotifierItem.qml').read_text(); self.assertIn('isMask: taskIcon.matrixHasOverride',q); self.assertIn('active: !taskIcon.matrixHasOverride',q); self.assertIn('Qt.resolvedUrl("../../icons/matrix-chat.svg")',q)
    def test_no_hyprland_dispatch(self):
        for p in (HERE/'session').glob('*.sh'):
            self.assertNotIn('hyprctl',p.read_text()); self.assertNotIn('hyprlock',p.read_text())
    def test_no_direct_power_without_confirmation(self):
        # Execute real script with isolated fake qdbus/systemctl; no access to real desktop/power.
        bin=self.home/'mock-bin'; bin.mkdir(); log=self.home/'calls'
        for name in ('qdbus6','systemctl'):
            p=bin/name; p.write_text(f'#!/bin/sh\necho "$0 $*" >> "{log}"\ncase "$*" in *GetActive*) echo true;; esac\n'); p.chmod(0o755)
        m.STATE.mkdir(parents=True,exist_ok=True); (m.STATE/'active.json').write_text('{"status":"active"}')
        import os
        env={**os.environ,'HOME':str(self.home),'PATH':str(bin)+':'+os.environ['PATH'],'XDG_CURRENT_DESKTOP':'KDE','HYPRLAND_INSTANCE_SIGNATURE':''}
        script=HERE/'session/action.sh'
        for a in ('suspend','logout','reboot','shutdown'):
            r=subprocess.run([str(script),a],env=env,capture_output=True); self.assertEqual(r.returncode,2)
        self.assertFalse(log.exists())
        for a in ('lock','logout','reboot','shutdown','suspend'):
            r=subprocess.run([str(script),a,'--confirmed'],env=env,capture_output=True); self.assertEqual(r.returncode,0,r.stderr)
        calls=log.read_text(); self.assertIn('promptLogout',calls); self.assertIn('promptReboot',calls); self.assertIn('promptShutdown',calls); self.assertIn('GetActive',calls); self.assertIn('systemctl suspend',calls)
        env['HYPRLAND_INSTANCE_SIGNATURE']='present'; self.assertNotEqual(subprocess.run([str(script),'lock'],env=env,capture_output=True).returncode,0)

if __name__=='__main__': unittest.main(verbosity=2)
