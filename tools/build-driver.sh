#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR=${BUILD_DIR:-"$ROOT/.build"}
export ARCH=arm64
export CROSS_COMPILE=${CROSS_COMPILE:-aarch64-linux-gnu-}
KCOMMIT=d8402159c04b1044106b4f27b7ed7c22ed09228f
SCOMMIT=c5a28ea78a01a40f24b7e5ab3049468bf74e16f8
mkdir -p "$BUILD_DIR"
for c in curl tar patch make "${CROSS_COMPILE}gcc"; do command -v "$c" >/dev/null || { echo "Missing: $c"; exit 1; }; done
[[ ! -e "$BUILD_DIR/kernel" && ! -e "$BUILD_DIR/driver" ]] || { echo 'Use a fresh BUILD_DIR to avoid reusing incompatible generated headers.'; exit 1; }
curl -fL --retry 2 "https://codeload.github.com/christianhaitian/linux/tar.gz/$KCOMMIT" -o "$BUILD_DIR/kernel.tar.gz"
mkdir "$BUILD_DIR/kernel" "$BUILD_DIR/driver"
tar -xzf "$BUILD_DIR/kernel.tar.gz" -C "$BUILD_DIR/kernel" --strip-components=1
tar -xzf "$ROOT/sources/zt9101-upstream-c5a28ea.tar.gz" -C "$BUILD_DIR/driver" --strip-components=1
(cd "$BUILD_DIR/driver" && patch -p1 < "$ROOT/patches/r36s-zt9101-r2.patch")
# The archive omits the external exFAT submodule. This Kconfig placeholder
# is used ONLY for preparing external-module headers, never a kernel image.
if [[ ! -f "$BUILD_DIR/kernel/fs/exfat/Kconfig" ]]; then
  mkdir -p "$BUILD_DIR/kernel/fs/exfat"
  printf 'config EXFAT_FS\n\ttristate "External exFAT (headers only)"\n' > "$BUILD_DIR/kernel/fs/exfat/Kconfig"
fi
cp "$ROOT/config/kernel-r36s.config" "$BUILD_DIR/kernel/.config"
make -C "$BUILD_DIR/kernel" CC="${CROSS_COMPILE}gcc" olddefconfig
make -C "$BUILD_DIR/kernel" CC="${CROSS_COMPILE}gcc" -j"$(nproc)" modules_prepare
grep -q '^#define CONFIG_NL80211_TESTMODE 1$' "$BUILD_DIR/kernel/include/generated/autoconf.h"
make -C "$BUILD_DIR/driver/ZT9101_android_V1.2.1800.20241115" ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" CC="${CROSS_COMPILE}gcc" KSRC="$BUILD_DIR/kernel" -j"$(nproc)"
echo 'Built module (not installed):'
sha256sum "$BUILD_DIR/driver/ZT9101_android_V1.2.1800.20241115/zt9101_ztopmac_usb.ko"
echo "Upstream driver commit: $SCOMMIT; kernel commit: $KCOMMIT"
echo 'A local rebuild may have a different file hash. Validate ABI and hardware before using it.'
