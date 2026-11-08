#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Verify the source patch and installer refusal/integrity behavior."""
from pathlib import Path
import os
import shutil
import subprocess
import tarfile
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory() as d:
    tmp = Path(d)
    payload = tmp/'payload'
    payload.mkdir()
    with tarfile.open(root/'ztop-r2-tested-payload.tar.gz') as t:
        t.extractall(payload, filter='data')
    env = os.environ.copy()
    env['ZT_PAYLOAD'] = str(payload)
    subprocess.run(['bash', str(root/'tools/install.sh'), '--check-package'], env=env, check=True)
    # This host-side test must never install a kernel module or call sudo.
    if os.uname().machine != 'aarch64' or os.uname().release != '4.4.189':
        result = subprocess.run(['bash', str(root/'tools/install.sh'), '--dry-run'], env=env)
        assert result.returncode != 0, 'Unsupported host was accepted'
    with (payload/'zt9101_ztopmac_usb.ko').open('ab') as f:
        f.write(b'corruption-test')
    result = subprocess.run(['bash', str(root/'tools/install.sh'), '--check-package'], env=env)
    assert result.returncode != 0, 'Corrupted payload was accepted'
    invalid = subprocess.run(['bash', str(root/'tools/rollback.sh'), str(payload)])
    assert invalid.returncode != 0, 'Arbitrary rollback directory was accepted'
    upstream = tmp/'upstream'
    upstream.mkdir()
    with tarfile.open(root/'sources/zt9101-upstream-c5a28ea.tar.gz') as t:
        t.extractall(upstream, filter='data')
    src = next(upstream.iterdir())
    subprocess.run(['patch', '--dry-run', '-p1', '-i', str(root/'patches/r36s-zt9101-r2.patch')], cwd=src, check=True)
print('Package integrity, refusal paths and exact-source patch checks passed.')
