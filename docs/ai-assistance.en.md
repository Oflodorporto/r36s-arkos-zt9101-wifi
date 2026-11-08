# Let your AI assistant help

[Português](ai-assistance.pt-BR.md) · [Main guide](../README.md)

An assistant can interpret logs, compare source and kernel headers, prepare
patches, run a reproducible build and help verify installation. It needs actual
device evidence and an authorized route to your PC/console. A normal chat has
no automatic access to your SD card or local IP addresses.

## Practical workflow

1. Identify the adapter's USB VID:PID, kernel/architecture and Image hash.
2. Keep a working adapter or establish the USB recovery route. Enable the
   handheld's remote service and use SSH. We used user-authorized Desktop
   Commander on Windows, WSL Ubuntu and SSH; another trusted terminal works.
3. Give the assistant the repository and a **reviewed** diagnostic report.
   Let it read first. Keep passwords, SSH keys and access tokens out of chat.
4. Ask for kernel ABI verification, a backup and a bounded test. Do not accept
   a matching version string as proof that headers are correct.
5. Evaluate each stage: module registration → firmware → interface → scan →
   authentication → IPv4 → HTTPS → reboot. A successful earlier stage does not
   prove the later ones. The user performs physical cable/dongle changes.
6. If the kernel reports an Oops, preserve the log and correct the cause before
   repeating the same test. A UI Back button cannot undo a kernel crash.

Suggested prompt:

> Help me diagnose ZT9101 USB 350b:9101 using this repository. First read its
> compatibility table, technical notes and AGENTS.md. Check my actual kernel
> Image hash and USB identity before writing anything. Preserve games, saves,
> working drivers and my own active DTB. Explain each change and its rollback.
> Distinguish module load from interface, DHCP and internet success. Use reviewed
> logs and do not publish credentials or identifying data.

For a rebuild, supply the actual kernel source/configuration and compiler
information, not just the handheld model. Ask the assistant to compare callback
layouts and unresolved symbols. This repair specifically needed
`CONFIG_NL80211_TESTMODE=y` for the tested kernel.

## Tools used in this repair

| Tool | Role |
| --- | --- |
| ChatGPT / Codex | Source/log analysis, patches, scripts and documentation |
| Desktop Commander | Authorized Windows terminal/file operations |
| WSL Ubuntu | Git, cross-compilation and SSH client |
| SSH / SCP | Device diagnostics and file transfer |
| GCC 13.3.0 cross compiler, GNU make | Building the aarch64 module |
| nm, readelf, objdump, SHA-256 | Mapping faults, comparing ABI positions and verifying files |
| NetworkManager / nmcli | Interface, scan and IPv4 verification |
| USB Network Mode / Windows RNDIS | Cable recovery without working Wi-Fi |
| dtc / fdtget / fdtput | Inspecting the active DTB and changing a verified USB role |

AI output is a proposal until logs and hardware tests support it. The project
records actual results and preserves upstream authorship rather than claiming
that an AI invented the entire driver.
