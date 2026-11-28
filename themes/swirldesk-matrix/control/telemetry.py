"""Local-only telemetry. No GUI dependencies; unknown values are None."""
import json
import os
import shutil
import subprocess
import time
from pathlib import Path


def read(path):
    try:
        return Path(path).read_text().strip()
    except (OSError, UnicodeError):
        return ''


def command(*args):
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=1.2, check=False, env={**os.environ, "LC_ALL": "C"})
        return p.stdout.strip() if p.returncode == 0 else None
    except (OSError, subprocess.SubprocessError):
        return None


def cpu_ticks(raw):
    try:
        fields = raw.splitlines()[0].split()
        if fields[0] != 'cpu':
            return None
        values = list(map(int, fields[1:9]))
        if len(values) < 4:
            return None
        return sum(values), sum(values[3:5])
    except (ValueError, IndexError):
        return None


def cpu_percent(old, new):
    if old is None or new is None:
        return None
    total, idle = new[0]-old[0], new[1]-old[1]
    return 100 * (total-idle) / total if total > 0 and 0 <= idle <= total else None


def memory(raw):
    try:
        values = {k.rstrip(':'): int(v) for line in raw.splitlines() if len(parts := line.split()) >= 2 for k, v in [parts[:2]]}
        total, available = values['MemTotal'], values['MemAvailable']
        if not 0 <= available <= total or total <= 0:
            return None
        return {'used': (total-available)*1024, 'total': total*1024, 'percent': 100*(total-available)/total}
    except (ValueError, KeyError):
        return None


def disk(path):
    try:
        total, used, free = shutil.disk_usage(path)
        return {'used': used, 'total': total, 'percent': 100*used/total} if total else None
    except OSError:
        return None


def temperature(root=Path('/sys/class/hwmon')):
    candidates = []
    for sensor in root.glob('hwmon*'):
        if read(sensor/'name') not in ('coretemp', 'k10temp', 'zenpower', 'cpu_thermal'):
            continue
        for f in sensor.glob('temp*_input'):
            try:
                value = int(read(f))/1000
                if -20 <= value <= 125:
                    candidates.append(value)
            except ValueError:
                pass
    return max(candidates) if candidates else None


def batteries(root=Path('/sys/class/power_supply')):
    packs = []
    for p in sorted(root.glob('*')):
        if read(p/'type') != 'Battery' or read(p/'present') == '0':
            continue
        try:
            capacity = int(read(p/'capacity'))
            if 0 <= capacity <= 100:
                packs.append({'name': p.name, 'percent': capacity, 'status': read(p/'status') or 'Unknown'})
        except ValueError:
            pass
    return packs


def workspaces():
    raw = command('hyprctl', 'activeworkspace', '-j')
    try:
        data = json.loads(raw)
        return {'id': data['id'], 'windows': data['windows']}
    except (TypeError, ValueError, KeyError):
        return None


def network():
    raw = command('nmcli', '-t', '-f', 'TYPE,DEVICE,STATE', 'device', 'status')
    if raw is None:
        return None
    links = []
    for line in raw.splitlines():
        parts = line.split(':')
        if len(parts) == 3 and parts[0] in ('wifi', 'ethernet', 'wwan') and parts[2] == 'connected':
            links.append(parts[1])
    return links


def vpn():
    raw = command('nmcli', '-t', '-f', 'TYPE,NAME', 'connection', 'show', '--active')
    if raw is None:
        return None
    return any(line.startswith('wireguard:') for line in raw.splitlines())


def audio():
    raw = command('wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@')
    if raw is None:
        return None
    try:
        return {'percent': round(float(raw.split()[1])*100), 'muted': '[MUTED]' in raw}
    except (IndexError, ValueError, OverflowError):
        return None


class Sampler:
    def __init__(self):
        self.previous = cpu_ticks(read('/proc/stat'))

    def sample(self):
        current = cpu_ticks(read('/proc/stat'))
        cpu = cpu_percent(self.previous, current)
        self.previous = current
        uptime = read('/proc/uptime').split()
        try:
            seconds = int(float(uptime[0]))
        except (ValueError, IndexError, OverflowError):
            seconds = None
        return {'cpu': cpu, 'memory': memory(read('/proc/meminfo')), 'disk': disk(Path.home()),
                'temperature': temperature(), 'batteries': batteries(), 'uptime': seconds,
                'network': network(), 'vpn': vpn(), 'audio': audio(), 'workspace': workspaces(),
                'timestamp': time.strftime('%H:%M:%S')}


if __name__ == '__main__':
    s = Sampler()
    time.sleep(.25)
    print(json.dumps(s.sample(), indent=2))
