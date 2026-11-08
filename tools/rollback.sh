#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
[[ $# == 1 ]] || { echo 'Usage: bash tools/rollback.sh /var/backups/r36s-zt9101/BACKUP'; exit 2; }
backup=$(realpath -e -- "$1")
[[ "$backup" == /var/backups/r36s-zt9101/* && -f "$backup/inventory.txt" ]] || { echo 'Invalid backup directory.' >&2; exit 1; }
SUDO=(); if [[ $(id -u) != 0 ]]; then sudo -v; SUDO=(sudo); fi
while read -r state p extra; do
  [[ -z "${extra:-}" ]] || exit 1
  case "$p" in
    /lib/modules/4.4.189/extra/zt9101_ztopmac_usb.ko|/lib/firmware/zt9101/fw20.bin|/lib/firmware/zt9101/fw30.bin|/lib/firmware/zt9101/wifi.cfg|/etc/modprobe.d/zt9101-r36s.conf|/etc/modprobe.d/r36h-zt9101.conf|/etc/modprobe.d/r36s-ztop-suspenso.conf) ;;
    *) echo 'Unexpected path in inventory.' >&2; exit 1 ;;
  esac
  case "$state" in present) "${SUDO[@]}" test -f "$backup$p" ;; absent) ;; *) exit 1 ;; esac
done < "$backup/inventory.txt"
while read -r state p; do
  if [[ "$state" == present ]]; then "${SUDO[@]}" cp -a "$backup$p" "$p"; else "${SUDO[@]}" rm -f "$p"; fi
done < "$backup/inventory.txt"
"${SUDO[@]}" depmod -a 4.4.189
sync
echo 'Backup restored. Reboot through the menu. The backup remains available.'
