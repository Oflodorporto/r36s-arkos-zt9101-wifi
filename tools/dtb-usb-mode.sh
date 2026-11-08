#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
[[ $# == 2 ]] || { echo 'Usage: sudo bash tools/dtb-usb-mode.sh /absolute/path/ACTIVE.dtb peripheral|otg|host'; exit 2; }
dtb=$1; mode=$2
[[ "$dtb" == /* && -f "$dtb" && "$dtb" == *.dtb ]] || { echo 'Specify the verified active DTB by absolute path.'; exit 1; }
case "$mode" in peripheral|otg|host) ;; *) exit 2 ;; esac
[[ $(id -u) == 0 ]] || { echo 'Run with sudo.'; exit 1; }
for c in fdtget fdtput cmp; do command -v "$c" >/dev/null || exit 1; done
node=/usb@ff300000
old=$(fdtget -t s "$dtb" "$node" dr_mode)
[[ "$old" != "$mode" ]] || { echo "Already $mode; nothing changed."; exit 0; }
backup="${dtb}.before-usb-$(date +%Y%m%d-%H%M%S)-$$"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cp "$dtb" "$backup"
cmp "$dtb" "$backup"
cp "$dtb" "$tmp"
fdtput -t s "$tmp" "$node" dr_mode "$mode"
[[ $(fdtget -t s "$tmp" "$node" dr_mode) == "$mode" ]]
cp "$tmp" "$dtb"
sync
printf 'USB role: %s -> %s. Backup: %s\nReboot required. Restore otg/host before using a Wi-Fi dongle.\n' "$old" "$mode" "$backup"
