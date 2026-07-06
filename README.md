# armkali

**Kali Linux penetration testing tools for ARM64 boards — one-line install**

A menu-driven installer that sets up a full Kali toolset and XFCE desktop on ARM64. Auto-detects your board and configures hardware-specific packages, GPU drivers, and ARM64 compatibility automatically.

![Platform](https://img.shields.io/badge/platform-ARM64%20%7C%20aarch64-blue)
![Boards](https://img.shields.io/badge/boards-x96q%20%7C%20RPi%203B%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Supported Boards

| | **x96q TV Box** | **Raspberry Pi 3B+** |
|---|---|---|
| **SoC** | Allwinner H313 | Broadcom BCM2837B0 |
| **CPU** | Quad-core Cortex-A53 @ 1.5GHz | Quad-core Cortex-A53 @ 1.4GHz |
| **RAM** | 1 GB | 1 GB |
| **WiFi** | None (USB adapter needed) | Built-in 802.11n + BT 4.2 |
| **GPU** | Mali-G31 (no OpenCL) | VideoCore IV |
| **OS** | Armbian | Raspberry Pi OS / Armbian |
| **Storage** | eMMC or microSD | microSD |

> **Not for x86/x86_64.** This installer is purpose-built for ARM64. Force a board with `ARMKALI_BOARD=rpi3bplus` or `ARMKALI_BOARD=x96q` if auto-detection fails.

## What It Does

- **Adds the Kali Linux ARM64 repository** with proper GPG keyring signing
- **Installs 130+ penetration testing tools** across 9 categories
- **Sets up XFCE desktop** with board-specific GPU drivers
- **Filters incompatible packages** — x86-only tools are skipped, ARM64 alternatives substituted (e.g., `netexec` replaces `crackmapexec`)
- **Auto-configures hardware** — VC4 GPU on RPi, swap file for 1GB RAM, Bluetooth, WiFi firmware

## Quick Start

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/ryzen30xx/armkali/main/install.sh | sudo bash
```

The installer auto-detects your board (x96q or RPi 3B+) and applies the correct configuration.

### Force a Specific Board

```bash
# For Raspberry Pi 3B+
curl -sSL https://raw.githubusercontent.com/ryzen30xx/armkali/main/install.sh | ARMKALI_BOARD=rpi3bplus sudo -E bash

# For x96q
curl -sSL https://raw.githubusercontent.com/ryzen30xx/armkali/main/install.sh | ARMKALI_BOARD=x96q sudo -E bash
```

### Manual Install

```bash
git clone https://github.com/ryzen30xx/armkali.git
cd armkali
sudo ./install.sh
```

## Usage

The installer launches an interactive menu:

```
  ╔═══════════════════════════════════════════════╗
  ║         armkali — Kali Tools for ARM64        ║
  ║     x96q (Allwinner H313) • Armbian • XFCE   ║
  ╚═══════════════════════════════════════════════╝

  1) Setup Kali repository
  2) Install tool categories
  3) Install XFCE desktop (GUI)
  4) Install ALL tools + GUI
  5) System update & upgrade
  6) System information
  7) Exit
```

### Menu Options

| Option | Description |
|--------|-------------|
| **1. Setup Kali repository** | Adds the Kali ARM64 apt source with GPG keyring. Run this first. |
| **2. Install tool categories** | Pick specific categories from a checklist. |
| **3. Install XFCE desktop** | Installs XFCE4, LightDM, Kali theme, and GUI utilities. |
| **4. Install ALL tools + GUI** | Full install — repo + all 9 categories + XFCE + board-specific config. |
| **5. System update & upgrade** | Runs `apt-get update` and `apt-get upgrade`. |
| **6. System information** | Shows board, SoC, RAM, GPU, kernel, and repo status. |

### Tool Categories

| # | Category | Tools | Examples |
|---|----------|-------|---------|
| 1 | **Wireless Attacks** | 14 | aircrack-ng, wifite, hcxdumptool, bettercap, kismet |
| 2 | **Web Application Analysis** | 18 | burpsuite, sqlmap, nikto, ffuf, wpscan, zaproxy |
| 3 | **Forensics** | 15 | autopsy, sleuthkit, binwalk, testdisk, bulk-extractor |
| 4 | **Exploitation** | 13 | metasploit-framework, impacket-scripts, evil-winrm, responder |
| 5 | **Password Cracking** | 13 | hashcat, john, hydra, medusa, crunch |
| 6 | **Sniffing & Spoofing** | 13 | wireshark, ettercap, bettercap, mitmproxy, netsniff-ng |
| 7 | **Reverse Engineering** | 12 | radare2, ghidra, gdb, apktool, jadx |
| 8 | **Information Gathering** | 17 | nmap, masscan, amass, theharvester, recon-ng |
| 9 | **Reporting** | 6 | eyewitness, dradis, cherrytree |

## Board-Specific Features

### x96q (Allwinner H313)

- Uses `xserver-xorg-video-fbdev` for display output
- Warns about missing built-in WiFi (USB adapter required for wireless tools)
- Creates 1GB swap file automatically (essential for 1GB RAM)
- No GPU acceleration (Mali-G31 lacks OpenCL driver on Linux)

### Raspberry Pi 3B+

- Enables **VC4 GPU driver** (`dtoverlay=vc4-fkms-v3d` in `/boot/config.txt`)
- Sets `gpu_mem=128` for desktop rendering
- Installs **RPi-specific packages**: `raspberrypi-userland`, `libraspberrypi-bin`, `firmware-brcm80211`, `pi-bluetooth`
- Enables **Bluetooth service** automatically
- Notes built-in WiFi monitor mode limitations (brcmfmac driver)
- Creates 1GB swap file automatically

## After Installation

### Start the Desktop

```bash
sudo systemctl start lightdm
```

Or reboot:

```bash
sudo reboot
```

XFCE launches automatically on boot.

### Auto-login

Configured for the user who ran `sudo`. To change:

```bash
sudo nano /etc/lightdm/lightdm.conf.d/90-autologin.conf
```

## ARM64 Compatibility

| Issue | Handling |
|-------|----------|
| x86-only packages | Skipped with a warning |
| `crackmapexec` (x86) | Substituted with `netexec` |
| `cuda-hashcat` (NVIDIA) | Substituted with CPU `hashcat` |
| CUDA/NVIDIA tools | Filtered out (no NVIDIA GPU) |
| `powersploit`, `unicornscan` | Skipped (no ARM64 build) |

## Prerequisites

- Supported board running **Armbian** or **Raspberry Pi OS** (aarch64)
- Internet connection
- Root/sudo access
- At least **8 GB free storage** (16 GB+ recommended for full install + GUI)

## Non-Interactive Mode

```bash
ARMKALI_YES=1 sudo -E ./install.sh
```

## Logs

```
/var/log/armkali-install.log
```

## Project Structure

```
armkali/
├── install.sh          # Entry point with board auto-detection
├── lib/
│   └── common.sh       # Shared utilities, categories, XFCE, menu system
├── boards/
│   ├── x96q.sh         # x96q (Allwinner H313) board config
│   └── rpi3bplus.sh    # Raspberry Pi 3B+ (BCM2837B0) board config
├── README.md
└── AGENTS.md
```

The one-line installer downloads only the board file it needs from GitHub.

## Idempotent

Safe to run multiple times. Packages already installed are skipped, Kali repo added only once, swap file and GPU overlay created only if missing.

## Limitations

- **No GPU cracking** — Neither the Mali-G31 nor VideoCore IV supports CUDA/OpenCL for hashcat. CPU-only (~50-100 kH/s for MD5).
- **1 GB RAM** — Avoid running multiple heavy tools simultaneously. The installer creates a 1GB swap file automatically.
- **Storage** — Full install (all categories + XFCE) requires ~6-8 GB. Use a 32 GB+ SD card.
- **WiFi monitor mode (x96q)** — No built-in WiFi. Need a USB adapter with monitor mode support (e.g., Alfa AWUS036ACH).
- **WiFi monitor mode (RPi 3B+)** — Built-in brcmfmac driver has limited monitor mode support. For full support, use the re4son kernel or an external USB adapter.

## Contributing

1. Fork the repo
2. Edit the relevant files (`install.sh`, `lib/common.sh`, or `boards/*.sh`)
3. Run `shfmt -w -i 2 <file>` and `shellcheck -x <file>`
4. Open a pull request

### Adding a New Board

1. Create `boards/yourboard.sh` with board constants and hook functions
2. Add a detection rule in `install.sh:detect_board()`
3. Update this README's Supported Boards table
4. Test on actual hardware

## License

MIT
