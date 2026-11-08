# USB recovery: handheld ↔ Windows PC

[Português](usb-network.pt-BR.md) · [Main guide](../README.md)

USB networking is an alternative way into a handheld with no working Wi-Fi.
The console acts as a USB Ethernet gadget; Windows sees a RNDIS network adapter.
This is separate from installing a Wi-Fi dongle driver.

The tested recovery path used **USB Network Mode by ctgl1987**, a data-capable
cable, a verified device-specific DTB, Windows RNDIS and SSH. The helper used
in the repair is preserved under `third_party/usb-network/`, with its MIT
license. Its original project is https://github.com/ctgl1987/arkos-usb-network-mode .

## Prerequisites

- Use the **OTG/data USB-C port**, not the charging-only port.
- Use a real data cable. Charging successfully does not prove the data wires work.
- Keep a copy of the console's own boot files and active DTB.
- Run the helper's compatibility check first. A kernel gadget module, a usable
  UDC, a compatible USB role and connected data/VBUS wiring are all required.
  Some clones cannot provide gadget mode through software alone.

## Identify the active DTB

Read `/boot/boot.ini`, its panel selectors and the actual file selected during
boot. Do not assume the DTB in `/boot/` is active: our R36S selected a file
inside `ScreenFiles/Panel 4/`. Another console can use a different path/panel.
Never copy a DTB from a sibling's handheld merely because both cases say R36S.

On the tested RK3326 device, the USB controller was `/usb@ff300000` and its
`dr_mode` needed `peripheral` for this recovery route. The optional tool below
changes **only that property**, makes a verified backup and preserves existing
screen and SD-clock settings:

```sh
sudo bash tools/dtb-usb-mode.sh '/absolute/path/to/YOUR-ACTIVE.dtb' peripheral
```

Use that command only after verifying both path and controller. If `fdtget`
cannot find the node/property, stop rather than guessing another board's file.
Record the old role printed by the tool. Reboot to apply the change.

## Universal mode: files and SSH, without PC internet sharing

1. Transfer `third_party/usb-network/USB Network Mode.sh` to the handheld's
   Tools/Options area using the existing card-reader or network route.
2. Run its compatibility check, then select **Universal** mode.
3. Connect the data cable between the handheld OTG port and Windows.
4. Wait for Windows to enumerate the RNDIS Ethernet adapter. If enumeration
   fails, inspect Device Manager and the helper's report before installing a
   random driver or changing the DTB again.
5. In Universal mode the helper configures the handheld as `10.44.44.1` and
   supplies DHCP addresses to the PC on that USB subnet.
6. From Windows Terminal or WSL, use SSH with your handheld username:

```sh
ssh YOUR_USER@10.44.44.1
scp r36s-zt9101-r2-install.tar.gz YOUR_USER@10.44.44.1:/home/YOUR_USER/
```

Accept a new SSH host key only after checking it belongs to your device.
For a changed IP, verify against the previously trusted key; do not disable
host-key checking. The original helper documents factory defaults; use the
credentials you have configured and never send them to an AI chat or issue.

Our confirmed Universal-mode test used the handheld at `10.44.44.1`, Windows
with a DHCP address on that subnet, ping and SSH. The PC did not need to share
its internet connection for these operations.

## Internet through the PC: a different mode

The helper also provides an **Internet** mode in which the handheld requests
an address from the PC. This procedure is documented by its upstream author;
it is not the same as the Universal-mode test above.

Start the helper's Internet mode and attach the cable **before** choosing an
adapter in Windows. Open `ncpa.cpl`, open the properties of the PC's adapter
that already has internet, select **Sharing**, enable Internet Connection
Sharing and choose the handheld's RNDIS adapter. Restart Internet mode on the
handheld and read the IP shown by the helper. Do not hardcode an assumed
Windows-assigned address. Check its route, DNS and an HTTPS request.

## Return to a Wi-Fi dongle

Shut down through the menu. Restore the DTB's original role (`otg` or `host`,
as recorded for that device), reboot and disconnect the PC cable before
using the Wi-Fi dongle:

```sh
sudo bash tools/dtb-usb-mode.sh '/absolute/path/to/YOUR-ACTIVE.dtb' otg
```

Use `otg` above only if that was your original working role. This repository
does not ship a replacement DTB or change a screen panel automatically.
The helper's optional Samba/web services are separate from SSH and need not
be enabled just to copy the driver package.
