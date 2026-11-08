# Credits and licensing / Créditos e licenças

This is a community integration and compatibility fix, not a new chipset driver
written from scratch. Esta é uma integração comunitária e uma correção de
compatibilidade, não um driver do chip escrito do zero.

| Component | Origin | License / use |
| --- | --- | --- |
| ZT9101 driver and firmware | [yjun123/ZT9101_vendor_linux_driver](https://github.com/yjun123/ZT9101_vendor_linux_driver), commit `c5a28ea78a01a40f24b7e5ab3049468bf74e16f8`; original copyright Shandong ZTop Microelectronics | Upstream GPL-2.0; LICENSE retained. Complete pinned upstream source archive and local patch are supplied. Firmware remains attributed to upstream. |
| Kernel source and headers | [christianhaitian/linux](https://github.com/christianhaitian/linux), rg351 commit `d8402159c04b1044106b4f27b7ed7c22ed09228f` | GPL-2.0; fetched separately for builds; no kernel Image/DTB redistributed here. |
| ArkOS community image | [AeolusUX/ArkOS-R3XS](https://github.com/AeolusUX/ArkOS-R3XS) | Platform credit; this project is independent and unofficial. |
| USB Network Mode | [ctgl1987/arkos-usb-network-mode](https://github.com/ctgl1987/arkos-usb-network-mode) | MIT; the used helper is included with its original license under third_party/usb-network. |
| Realtek RTL8188FU recovery work | [XNLFutureTechnologies/R36_RTL8188FU](https://github.com/XNLFutureTechnologies/R36_RTL8188FU) | Reference/tool credit. Realtek code/binaries are not part of this ZTop release. |
| Remote device operations | [Desktop Commander](https://desktopcommander.app/) | External tool used for user-authorized PC access; no software or credentials redistributed. |
| AI assistance | ChatGPT / Codex | Helped inspect logs, write patches/tools, compile and document. Hardware evidence and upstream authorship remain explicit. |

New standalone scripts in tools/ and the top-level launchers are MIT, as marked
by SPDX headers (LICENSES/MIT-tools.txt). Driver modifications follow the
upstream GPL-2.0 license. Documentation is provided under CC BY 4.0:
https://creativecommons.org/licenses/by/4.0/ . The USB helper retains its
separate MIT copyright notice. Binary redistribution includes corresponding
source, the exact patch, build configuration and build instructions.

Maintainer / mantenedor: **Rodolfo Porto dos Santos (Oflodorporto)**.
Contributors are welcome; preserve upstream copyright and license notices.
