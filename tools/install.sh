#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
PAYLOAD=${ZT_PAYLOAD:-"$ROOT/payload"}
MODE=install
case "${1:-}" in
  --check-package) MODE=check ;;
  --dry-run) MODE=dry ;;
  '') ;;
  *) echo 'Usage: bash tools/install.sh [--check-package|--dry-run]' >&2; exit 2 ;;
esac
EXPECTED_IMAGE=acf57a15f6aecf08dc9dea98eaaf88aa355aba1193c67d13b9805f7a416df40b
EXPECTED_MODULE=50657888964e79889ccbe17823d4b9cf83bb0b1deb9437b6fae7d764c92cfc78
[[ -d "$PAYLOAD" ]] || { echo 'Extract the tested payload into payload/ first. See README.' >&2; exit 1; }
(cd "$PAYLOAD" && sha256sum -c SHA256SUMS)
printf '%s  %s\n' "$EXPECTED_MODULE" "$PAYLOAD/zt9101_ztopmac_usb.ko" | sha256sum -c -
[[ "$MODE" != check ]] || { echo 'Package integrity OK. No system files changed.'; exit 0; }
[[ $(uname -r) == 4.4.189 && $(uname -m) == aarch64 ]] || { echo 'Unsupported kernel/architecture. Rebuild for your kernel; see docs.' >&2; exit 1; }
[[ -f /boot/Image ]] || { echo '/boot/Image is missing.' >&2; exit 1; }
[[ $(sha256sum /boot/Image | cut -d ' ' -f1) == "$EXPECTED_IMAGE" ]] || { echo 'Kernel Image hash differs from the tested build. Installation refused.' >&2; exit 1; }
if [[ "$MODE" == dry ]]; then
  echo 'Compatible tested kernel and payload. Would back up and install ZTop R2; no changes made.'
  exit 0
fi
SUDO=()
if [[ $(id -u) != 0 ]]; then sudo -v; SUDO=(sudo); fi
backup="/var/backups/r36s-zt9101/$(date +%Y%m%d-%H%M%S)-$$"
"${SUDO[@]}" mkdir -p "$backup"
paths=(
 /lib/modules/4.4.189/extra/zt9101_ztopmac_usb.ko
 /lib/firmware/zt9101/fw20.bin /lib/firmware/zt9101/fw30.bin /lib/firmware/zt9101/wifi.cfg
 /etc/modprobe.d/zt9101-r36s.conf /etc/modprobe.d/r36h-zt9101.conf
 /etc/modprobe.d/r36s-ztop-suspenso.conf
)
for p in "${paths[@]}"; do
  if "${SUDO[@]}" test -e "$p"; then
    "${SUDO[@]}" cp -a --parents "$p" "$backup/"
    printf 'present %s\n' "$p" | "${SUDO[@]}" tee -a "$backup/inventory.txt" >/dev/null
  else
    printf 'absent %s\n' "$p" | "${SUDO[@]}" tee -a "$backup/inventory.txt" >/dev/null
  fi
done
"${SUDO[@]}" install -D -m 644 "$PAYLOAD/zt9101_ztopmac_usb.ko" /lib/modules/4.4.189/extra/zt9101_ztopmac_usb.ko.new
"${SUDO[@]}" mv /lib/modules/4.4.189/extra/zt9101_ztopmac_usb.ko.new /lib/modules/4.4.189/extra/zt9101_ztopmac_usb.ko
"${SUDO[@]}" install -d /lib/firmware/zt9101 /etc/modprobe.d
for f in fw20.bin fw30.bin wifi.cfg; do "${SUDO[@]}" install -m 644 "$PAYLOAD/$f" "/lib/firmware/zt9101/$f"; done
"${SUDO[@]}" install -m 644 "$PAYLOAD/r36h-zt9101.conf" /etc/modprobe.d/zt9101-r36s.conf
"${SUDO[@]}" rm -f /etc/modprobe.d/r36h-zt9101.conf /etc/modprobe.d/r36s-ztop-suspenso.conf
"${SUDO[@]}" depmod -a 4.4.189
sync
printf 'Installed ZTop R2. Backup: %s\nReboot through the menu with the ZTop connected to OTG.\n' "$backup"
echo 'No ROMs, saves, Realtek driver, boot Image or DTB were modified.'
