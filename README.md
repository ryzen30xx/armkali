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
| **WiFi** | XRadio XR819 (2.4GHz b/g/n, no monitor mode) | Built-in 802.11n + BT 4.2 |
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
| 0 | **Low-RAM Essentials** | 27 | lightest picks from every category, safe for 1GB RAM |
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
- Has **built-in WiFi** (XRadio XR819, 2.4GHz b/g/n) — works for normal internet but the driver **does not support monitor mode**, so wireless pentesting tools still need a USB adapter (RTL8812AU / AR9271 / RT3070)
- No built-in Bluetooth
- Creates 1GB swap file + 512MB zram + tunes apt/swappiness for 1GB RAM / 8GB eMMC
- No GPU acceleration (Mali-G31 lacks OpenCL driver on Linux)

### Raspberry Pi 3B+

- Enables **VC4 GPU driver** (`dtoverlay=vc4-fkms-v3d` in `/boot/config.txt`)
- Sets `gpu_mem=64` (base spec — preserves 64MB of system RAM vs the 128MB default)
- Installs **RPi-specific packages**: `raspberrypi-userland`, `libraspberrypi-bin`, `firmware-brcm80211`, `pi-bluetooth`
- Enables **Bluetooth service** automatically
- Notes built-in WiFi monitor mode limitations (brcmfmac driver)
- Creates 1GB swap file automatically

## Base Spec Optimizations (1GB RAM / 8GB eMMC)

The installer is tuned for the lowest common hardware. **CPU and RAM are soldered — only storage is upgradable** — so every optimization focuses on the fixed resources.

### RAM optimizations (cannot upgrade)

- **RAM-tier detection** — `detect_ram_tier()` reads `/proc/meminfo` at startup. `base` = <1.5GB (1GB hardware), `extended` = 2GB+ hardware. Shown in the menu subtitle.
- **Auto-filtered categories** — each category is split into `_BASE` (lightweight CLI) and `_EXTRA` (Java/GUI/memory-hogs). On base tier, extras are skipped with a warning and a list of CLI alternatives (e.g., use `sqlmap` instead of `burpsuite`).
- **`Low-RAM Essentials` category** — one-click install of 27 hand-picked lightest tools across all 9 categories, guaranteed safe on 1GB RAM.
- **XFCE compositor disabled on 1GB** — `xfce_tune_1gb()` writes xfconf to disable window compositing, shadows, animations, and thumbnail generation. Saves ~50MB RAM + CPU cycles. Re-enable via `xfce4-settings-manager`.
- **zram compressed swap** — 512MB of in-RAM compressed swap is set up alongside the 1GB disk swap file, effectively giving 1.5-2GB usable RAM.
- **Swappiness tuned to 60** — swaps earlier to prevent OOM kills under load.
- **RPi `gpu_mem=64`** (was 128MB) — frees 64MB back to system RAM since XFCE compositing is off.

### CPU optimizations (cannot upgrade)

- **Skip thumbnail generation** — tumblerd is masked on 1GB (heavy on eMMC I/O and CPU).
- **Skip automount polling** — thunar-volman disabled (saves CPU cycles polling USB/SD).
- **No window animations** — XFCE animations disabled (fewer CPU wakeups).

### Storage optimizations (upgradable — less critical)

- **Package cache preload** — `apt-cache dumpavail` is loaded once into an associative array after `apt-get update`, eliminating 2-5 second per-package `apt-cache show` calls on slow eMMC.
- **`--no-install-recommends` everywhere** — a persistent `/etc/apt/apt.conf.d/90-armkali-minimal` disables recommends, suggests, and translations globally. Saves 30-50% disk on every install.
- **Disk space guard** — fails fast if `/var` has <100MB (apt would fail) and warns if rootfs has <2GB (full install needs ~5-6GB).
- **Trimmed XFCE** — dropped `xfce4-goodies` (~300MB), `xfce4-screensaver` (DPMS handled by `xfce4-power-manager`), `firefox-esr` (~150MB), `pulseaudio`/`pavucontrol` (~100MB audio optional). Install them later if needed.
- **Storage warnings** — each board's `board_post_install()` warns that 8GB is tight for a full install and recommends installing categories selectively.

## Dev Kit — Serial Console Over UART

Both boards have UART pads exposed for headless development, recovery, and boot-log inspection. **Serial console is enabled by default** (serial-getty @ 115200 8N1).

### x96q (Allwinner H313) — UART pads on PCB

Three labeled pads on the top-right of the PCB, between USB1 and the CVBS socket:

| Pad | Signal |
|---|---|
| **RX** | Board receives |
| **TX** | Board sends |
| **GND** | Ground |

Maps to `/dev/ttyS0` (UART0). To reach the pads: remove the feet, unscrew the case, optionally drill a small hole on the right side of the case to route wires.

### Raspberry Pi 3B+ — UART on GPIO header

| GPIO pin | Signal |
|---|---|
| Pin 8 (GPIO14) | TXD (board sends) |
| Pin 10 (GPIO15) | RXD (board receives) |
| Pin 6 | GND |

Maps to `/dev/ttyAMA0` (PL011). Installer sets `enable_uart=1` in `/boot/config.txt` and adds `console=ttyAMA0,115200` to `/boot/cmdline.txt`.

### Connect from a host PC

Use any **3.3V USB-to-TTL adapter** (CP2102, PL2303, CH340, FTDI). **Do NOT connect VCC/5V** — cross RX↔TX, join GND.

```bash
# On your host PC (Linux/macOS):
picocom -b 115200 /dev/ttyUSB0
# or: screen /dev/ttyUSB0 115200
# or: minicom -D /dev/ttyUSB0
```

Power on the board — you'll see the full U-Boot + kernel boot log, then a login prompt.

### Disable if not needed

```bash
sudo systemctl disable --now serial-getty@ttyS0.service   # x96q
sudo systemctl disable --now serial-getty@ttyAMA0.service # RPi 3B+
```

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
- At least **8 GB free storage** (minimum, selective install) or **16 GB+** (comfortable full install + GUI)

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
- **WiFi monitor mode (x96q)** — Built-in XRadio XR819 supports normal WiFi but **not monitor mode**. For wireless pentesting, use a USB adapter with a monitor-capable chipset (e.g., Alfa AWUS036ACH with RTL8812AU, or TP-Link TL-WN722N v1 with AR9271).
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
