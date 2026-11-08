# R36S / R36SH ArkOS ZT9101 Wi-Fi Fix

**[Português do Brasil](README.pt-BR.md) · English**

Community-tested compatibility fixes for the **ZTop ZT9101 USB Wi-Fi dongle
`350b:9101`** on the specific **ArkOS Linux 4.4.189 aarch64** build below.
Includes the tested R2 module, corresponding source, installer/rollback tools,
USB-to-PC recovery instructions and an AI-assisted troubleshooting guide.

This project grew out of repairing two family handhelds. Rodolfo tested real
hardware while ChatGPT/Codex helped analyze kernel logs, patch upstream code and
build the module. The chipset driver itself comes from ZTop and the upstream
community; see [credits and licenses](THIRD_PARTY.md).

## What was fixed

1. **USB initialization crash:** the driver dereferenced an invalid configuration
   pointer in `zt_endpoint_init`. R2 obtains the configuration descriptor through
   the kernel USB API and checks lengths, endpoint arrays and pointers.
2. **Wi-Fi service crash after loading:** a missing `CONFIG_NL80211_TESTMODE`
   build option shifted `cfg80211_ops` callbacks. The kernel's `flush_pmksa`
   request reached `cancel_remain_on_channel`, with an incompatible argument.
   The supplied build profile restores the correct layout.
3. **False diagnostic failure:** vendor drivers may omit the sysfs
   `device/driver` link. A missing link does not mean `wlan0` was not created.
   Verification now distinguishes module loading, interface creation, association,
   DHCP/IPv4 and actual internet access.

## Compatibility comes first

| Item | Validated scope |
| --- | --- |
| USB chipset | ZTop ZT9101, VID:PID `350b:9101` |
| Handheld | R36S: direct network/reboot validation; R36SH: installation/load/unload checked and Wi-Fi after dongle swap confirmed by owner |
| Architecture / kernel | aarch64, `4.4.189`, SMP, module unloading |
| Tested Image SHA-256 | `acf57a15f6aecf08dc9dea98eaaf88aa355aba1193c67d13b9805f7a416df40b` |
| Tested R2 module SHA-256 | `50657888964e79889ccbe17823d4b9cf83bb0b1deb9437b6fae7d764c92cfc78` |
| R36S hardware evidence | Firmware loaded; interface created; WPA connection; IPv4; SSH; HTTPS; automatic connection after reboot |
| Other kernels, mainline Linux, dArkOS, other clone boards | Not established by these tests; rebuild and validate separately |

**The kernel version string alone is not enough.** The installer refuses a
different `/boot/Image` hash. Do not rename an unrelated adapter or force a
MediaTek/Realtek driver onto this USB ID. R36S/R36SH case names alone do not
identify the kernel, screen panel or USB wiring.

## Tested boards and the Wi-Fi Off case

| Test unit | Physical identification | Evidence and limits |
| --- | --- | --- |
| Vertical R36S | Visible PCB marking in the owner's photo: **`R36S-V12`**, dated **`2023-08-18`** | Wi-Fi was recovered on this unit. The photographed marking identifies the visible PCB; it does not independently establish the revision of every board inside the handheld. Screen setup used Panel 4. |
| Horizontal R36SH / R36S-H | Visible PCB marking in the owner's photo: **`HL-R36H-V20`**, dated **`2024-05-18`** | R2 installation, module load/unload were checked; Wi-Fi after swapping dongles was confirmed by the owner. The case/model name must not be used as a PCB revision. |

The vertical unit had shown **Wi-Fi Off**, empty network lists and Wi-Fi/menu
hangs. The owner reported that **the same handheld and Realtek dongle worked
with the other unit's configured SD card**, while the original card did not.
This comparison pointed toward the software/boot configuration on the card;
it did not support declaring this unit permanently incapable of USB Wi-Fi.
Subsequent network tests confirmed recovery on the vertical unit.

The other tested adapter was **Realtek RTL8188FTV, USB `0bda:f179`**, using
`rtl8188fu`. **The ZTop R2 installer in this repository is for `350b:9101`;
it does not install a Realtek driver.** The Realtek is documented here as a
working comparison/recovery route, not as proof that every adapter with that
name or every R36S-V12-marked PCB will work with this package.

If a supported-looking Realtek dongle still shows Wi-Fi Off, compare the
**USB ID, exact kernel Image, matching module, blacklist/configuration and
active DTB/USB role**, then distinguish USB detection, interface creation,
association and DHCP. Matching the printed kernel version or the case name
alone does not establish compatibility. An empty scan alone cannot identify
a faulty board. These results document the tested units, not universal support
for all boards or a diagnosis of every Wi-Fi failure.

## Install the tested package

Download **[r36s-zt9101-r2-install.tar.gz](r36s-zt9101-r2-install.tar.gz)** from this repository, extract it and
copy the complete `ztop-r2` directory to `/roms/tools/` on the handheld. You may
use an SD-card reader or the [USB network route](docs/usb-network.en.md).
Preserve the existing working network path until the files are transferred.

Run from an SSH shell or the handheld's file manager:

```sh
cd /roms/tools/ztop-r2
bash tools/install.sh --check-package
bash tools/install.sh --dry-run
bash Install-ZTop.sh
```

The installer verifies the payload and kernel, creates a backup under
`/var/backups/r36s-zt9101/`, installs the ZTop module/firmware/config, clears the
known temporary ZTop block and runs `depmod`. It does not unload an active
adapter, reboot automatically or modify games, saves, the Realtek driver,
kernel Image or screen DTB.

Shut down using the menu, connect the ZTop to the **OTG/data port**, then boot.
Open Wi-Fi and select your network if it does not reconnect automatically.
Check **Network Info** for the current address. No 40-second experimental test
launcher is required after installation.

The vendor driver fell back to a generated MAC on our adapter. Its DHCP address
changed between boots; obtain the current IP instead of assuming the previous
one still applies. A changing address is not, by itself, a lost connection.

## Verify and recover

```sh
ip -brief address
nmcli device status
python3 tools/diagnose.py --scan
```

Verify SSH and an HTTPS request, then reboot once and verify automatic
reconnection. `insmod` exit 0 alone is not a successful Wi-Fi test. Diagnostics
use bounded subprocess waits; they cannot recover a frozen kernel.

Restore a backup with:

```sh
bash tools/rollback.sh /var/backups/r36s-zt9101/YOUR-BACKUP
```

Reboot after rollback. Keep the backup. If networking is unavailable, use the
working Realtek adapter or USB recovery; the installer preserves those paths.

## Build, understand and contribute

- [Technical evidence and build instructions](docs/technical-notes.en.md)
- [USB cable, Windows RNDIS, SSH and internet sharing](docs/usb-network.en.md)
- [How your AI assistant can help](docs/ai-assistance.en.md)
- [Credits / licensing](THIRD_PARTY.md) · [safe diagnostic sharing](SECURITY.md)

The full pinned upstream source archive is in `sources/`; our changes are in
`patches/`; the exact build configuration is in `config/`. The install archive
also carries the corresponding source and patch. Build tools are provided
without claiming support for untested hardware. Please report the USB ID,
kernel hash, build profile and sanitized evidence when contributing.

Maintained by **Rodolfo Porto dos Santos — [Oflodorporto](https://github.com/Oflodorporto)**.
Independent community work; not an official ArkOS, ZTop or OpenAI product.
