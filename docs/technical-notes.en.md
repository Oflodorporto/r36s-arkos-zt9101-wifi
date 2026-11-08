# Technical evidence and rebuilding

[Português](technical-notes.pt-BR.md) · [Main guide](../README.md)

## Tested build identity

- Linux `4.4.189 #3 SMP Wed Oct 13 23:24:26 EDT 2021`, aarch64.
- Kernel Image SHA-256: `acf57a15f6aecf08dc9dea98eaaf88aa355aba1193c67d13b9805f7a416df40b`.
- Module vermagic: `4.4.189 SMP mod_unload aarch64`.
- Kernel source: christianhaitian/linux, commit
  `d8402159c04b1044106b4f27b7ed7c22ed09228f` (rg351).
- Upstream driver: yjun123/ZT9101_vendor_linux_driver, commit
  `c5a28ea78a01a40f24b7e5ab3049468bf74e16f8`.
- Build profile: `rg351p_tweaked_defconfig`, with
  `CONFIG_NL80211_TESTMODE=y` and `CONFIG_LOCALVERSION_AUTO` disabled.
- Module compiler used: Ubuntu aarch64-linux-gnu GCC 13.3.0. The original
  kernel was built with Linaro GCC 6.3.1; matching those compiler versions was
  not claimed. Load/unload and hardware evidence were checked separately.

The supplied full configuration is authoritative for reproducing this module.
Do not substitute another configuration merely because its filename says ArkOS.

## Failure 1: USB configuration pointer

The first instrumented hardware test terminated `insmod` with signal 11. A
NULL+4 Oops mapped to `zt_endpoint_init+0x38`; the faulting instruction read
`bNumInterfaces` through `usb_device->actconfig`. The patch queries the USB
configuration descriptor with `usb_get_descriptor`, checks the result and
validates endpoint-array bounds. It also reads the bulk endpoint packet size
from `wMaxPacketSize` with endian conversion.

After that correction, logs showed endpoint discovery, USB power-on, both
firmware transfers and NIC registration. These results are distinct from a
working network connection.

## Failure 2: callback layout

R1 then created a Wi-Fi interface but killed `wpa_supplicant` with a kernel
Oops in `cfg80211_cancel_remain_on_channel_cb+0x28`. The callback treated a
`net_device` argument as a `wireless_dev`.

Disassembly of the running kernel showed a callback loaded from offset
**456 / 0x1c8**, called with `wiphy` and `net_device`. With the missing
`CONFIG_NL80211_TESTMODE` entries, that offset selected
`cancel_remain_on_channel`. After enabling the option, compiled `offsetof`
constants placed `flush_pmksa` at **0x1c8**, matching the runtime request.

The native exfat/gpio_keys modules and the corrected module also agreed on
the module entry/exit relocation positions: **0x170 / 0x278**. An intermediate
configuration had an incorrect exit position and loaded as permanent; it was
discarded. Agreement on these positions is useful evidence, not a complete
ABI proof. Hardware tests remain required.

R2 completed scanning, association and WPA key installation without that Oops.
The verification tool was then corrected because this driver omitted a sysfs
parent link. IPv4, SSH, HTTPS and automatic reconnection after reboot were
confirmed on the R36S. Individual validation status belongs in the README
table, not inferred from the device's case name.

## Build on an x86-64 Linux host

The tested host used WSL Ubuntu 24.04. Install ordinary build dependencies:

```sh
sudo apt update
sudo apt install build-essential gcc-aarch64-linux-gnu bc flex bison libssl-dev curl patch
bash tools/build-driver.sh
```

The script fetches the pinned kernel, extracts the supplied upstream driver
archive, applies the patch, prepares headers from the supplied configuration
and builds the module. The source archive omits the external exFAT submodule;
a minimal Kconfig placeholder is created **only for external-module header
preparation**, never for building/installing a kernel Image.

No kernel or DTB is built or installed. `CC` is passed explicitly so the old
kernel's warning-wrapper launcher does not require a `python` alias. The exact
binary file hash can differ with host/compiler/build-path metadata. The public
installer intentionally accepts only the tested binary; a different rebuild
requires a separate ABI/hardware review and release manifest.

## Storage and remaining limits

The original SD card also produced MMC timeouts. Reducing its verified active
DTB's SD clock from 150 MHz to 50 MHz stopped those errors in selected repeated
reads and subsequent boots. This was a device-specific stability measure, not
a full health/capacity certification and not a requirement silently applied by
this installer. Do not run repair-mode fsck against a mounted root filesystem.

The adapter's efuse MAC read failed and the vendor fallback generated changing
MAC addresses. DHCP can therefore assign a new address on reboot. Stable-MAC
provisioning, suspend/resume, roaming and throughput benchmarking are not
claimed as validated features. Preserve these limits when reporting results.
