import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'themes/swirldesk-matrix/control'))
import telemetry as t

class TelemetryTests(unittest.TestCase):
    def test_cpu(self):
        a=t.cpu_ticks('cpu 100 0 50 850 0 0 0 0 8 0\n')
        b=t.cpu_ticks('cpu 120 0 60 920 0 0 0 0 9 0\n')
        self.assertEqual(t.cpu_percent(a,b),30)
        self.assertIsNone(t.cpu_percent(a,a))
        self.assertIsNone(t.cpu_ticks('bad'))
    def test_mem(self):
        self.assertEqual(t.memory('MemTotal: 1000 kB\nMemAvailable: 250 kB')['percent'],75)
        self.assertIsNone(t.memory('MemTotal: 0 kB\nMemAvailable: 0 kB'))
        self.assertIsNone(t.memory(''))
    def test_battery_and_sensor(self):
        with tempfile.TemporaryDirectory() as root:
            p=Path(root); b=p/'BAT1'; b.mkdir()
            for k,v in {'type':'Battery','capacity':'74','status':'Discharging'}.items(): (b/k).write_text(v)
            self.assertEqual(t.batteries(p)[0]['percent'],74)
            h=p/'hwmon0'; h.mkdir(); (h/'name').write_text('coretemp'); (h/'temp1_input').write_text('51000')
            self.assertEqual(t.temperature(p),51)
            (h/'temp1_input').write_text('bad')
            self.assertIsNone(t.temperature(p))
    @patch.object(t,'command')
    def test_network_audio_ws(self,c):
        c.return_value='wifi:wlp1s0:connected\nethernet:eth0:disconnected'
        self.assertEqual(t.network(),['wlp1s0'])
        c.return_value='wireguard:mikrotik'; self.assertTrue(t.vpn())
        c.return_value='Volume: 0.45 [MUTED]'; self.assertEqual(t.audio(),{'percent':45,'muted':True})
        c.return_value='{"id":9,"windows":1}'; self.assertEqual(t.workspaces()['id'],9)
        c.return_value=None
        for f in (t.network,t.vpn,t.audio,t.workspaces): self.assertIsNone(f())

if __name__ == '__main__': unittest.main()
