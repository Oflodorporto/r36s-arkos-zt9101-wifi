#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Read-only Wi-Fi diagnostics. Never loads a module or changes networking."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--scan', action='store_true', help='Request a bounded NetworkManager scan')
parser.add_argument('--output', type=Path, default=Path.home() / 'ztop-diagnostics')
args = parser.parse_args()
out = args.output / time.strftime('%Y%m%d-%H%M%S')
out.mkdir(parents=True, exist_ok=False)
report = {'kernel': os.uname().release, 'architecture': os.uname().machine,
          'interfaces': [], 'usb_ids': [], 'commands': {}}
for dev in Path('/sys/bus/usb/devices').iterdir():
    try:
        report['usb_ids'].append({'vendor': (dev/'idVendor').read_text().strip(),
                                 'product': (dev/'idProduct').read_text().strip()})
    except (FileNotFoundError, NotADirectoryError, PermissionError):
        pass
for net in Path('/sys/class/net').iterdir():
    # Some vendor drivers omit the device/driver sysfs link. Its absence is
    # not evidence that the interface failed to initialize.
    report['interfaces'].append({'name': net.name,
        'wireless': net.name.startswith('wlan') or (net/'phy80211').exists(),
        'driver_link': str((net/'device/driver').resolve()) if (net/'device/driver').exists() else None})
jobs = [
    ('interfaces', ['ip', '-brief', 'address'], 3),
    ('routes', ['ip', 'route'], 3),
    ('kernel', ['dmesg'], 4),
    ('module', ['modinfo', 'zt9101_ztopmac_usb'], 3),
    ('networkmanager', ['nmcli', '--wait', '2', 'device', 'status'], 4),
]
if args.scan:
    wlan = next((x['name'] for x in report['interfaces'] if x['wireless']), None)
    if wlan:
        jobs.append(('scan', ['nmcli', '--wait', '8', 'device', 'wifi', 'list', 'ifname', wlan, '--rescan', 'yes'], 10))
deadline = time.monotonic() + 35
for label, command, limit in jobs:
    if time.monotonic() >= deadline:
        report['commands'][label] = 'overall deadline reached'
        continue
    with (out/(label+'.txt')).open('wb') as f:
        try:
            proc = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=f,
                                    stderr=subprocess.STDOUT, start_new_session=True)
        except OSError as e:
            report['commands'][label] = str(e)
            continue
        end = min(deadline, time.monotonic()+limit)
        while proc.poll() is None and time.monotonic() < end:
            time.sleep(0.1)
        code = proc.poll()
        if code is None:
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            # Do not wait for an unkillable D-state kernel task.
            report['commands'][label] = 'timed out; inspect kernel log'
        else:
            report['commands'][label] = code
(out/'report.json').write_text(json.dumps(report, indent=2)+'\n')
print('Saved:', out)
print('Review SSIDs, MAC/IP addresses and hostnames before sharing logs.')
print('A timeout cannot recover a frozen kernel. This tool made no system changes.')
