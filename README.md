# armkali

**Kali Linux penetration testing tools on Armbian for the x96q TV box (Allwinner H313)**

A single-file, menu-driven installer that sets up a full Kali toolset and XFCE desktop on ARM64 Armbian. Built specifically for the Allwinner H313 SoC (quad-core Cortex-A53) — handles ARM64 package compatibility automatically, skipping x86-only tools and substituting alternatives where available.

![Platform](https://img.shields.io/badge/platform-ARM64%20%7C%20aarch64-blue)
![SoC](https://img.shields.io/badge/SoC-Allwinner%20H313-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## What It Does

- **Adds the Kali Linux ARM64 repository** with proper GPG keyring signing
- **Installs 130+ penetration testing tools** across 9 categories
- **Sets up XFCE desktop** with LightDM for a Kali-style GUI
- **Filters incompatible packages** — x86-only tools are skipped with warnings, and ARM64 alternatives are substituted automatically (e.g., `netexec` replaces `crackmapexec`)

## Hardware Target

| Spec | Detail |
|------|--------|
| **Device** | x96q TV Box |
| **SoC** | Allwinner H313 |
| **CPU** | Quad-core ARM Cortex-A53 @ 1.5 GHz |
| **Architecture** | `aarch64` / `arm64` |
| **RAM** | 1–2 GB |
| **Storage** | eMMC or microSD |
| **GPU** | Mali-G31 (no CUDA/OpenCL — hashcat runs CPU-only) |
| **OS** | Armbian (Debian/Ubuntu base) |

> **Not compatible with x86/x86_64 systems.** This installer is purpose-built for ARM64. While some functions may work on other ARM boards, package lists are tuned for the H313's constraints.

## Prerequisites

- x96q running **Armbian** (Debian or Ubuntu base, aarch64)
- Internet connection
- Root/sudo access
- At least **8 GB free storage** (16 GB+ recommended for full install + GUI)

## Quick Start

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/ryzen30xx/armkali/main/install.sh | sudo bash
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
| **4. Install ALL tools + GUI** | Full install — repo + all 9 categories + XFCE desktop. |
| **5. System update & upgrade** | Runs `apt-get update` and `apt-get upgrade`. |
| **6. System information** | Shows architecture, SoC, RAM, kernel, and repo status. |

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

## After Installation

### Start the Desktop

```bash
sudo systemctl start lightdm
```

Or reboot:

```bash
sudo reboot
```

The XFCE desktop will launch automatically on boot after installation.

### Auto-login

The installer configures LightDM auto-login for the user who ran `sudo`. To change this, edit:

```bash
sudo nano /etc/lightdm/lightdm.conf.d/90-autologin.conf
```

## ARM64 Compatibility

The installer handles these ARM64-specific concerns automatically:

| Issue | Handling |
|-------|----------|
| x86-only packages | Skipped with a warning |
| `crackmapexec` (x86) | Substituted with `netexec` |
| `cuda-hashcat` (NVIDIA) | Substituted with CPU `hashcat` |
| CUDA/OpenCL tools | Filtered out (no GPU support on H313) |
| `powersploit`, `unicornscan` | Skipped (no ARM64 build) |

Package availability is verified via `apt-cache show` before each install — if a package isn't in the Kali ARM64 repo, it's skipped gracefully.

## Non-Interactive Mode

Skip all confirmation prompts (useful for automation):

```bash
ARMKALI_YES=1 sudo -E ./install.sh
```

## Logs

All install output is logged to:

```
/var/log/armkali-install.log
```

## Project Structure

```
armkali/
├── install.sh      # Single self-contained installer (~880 lines)
├── AGENTS.md       # AI agent development guidelines
├── README.md       # This file
└── .gitignore
```

Everything is in one file so it works with `curl | sudo bash` — no dependencies, no submodules, no extra downloads.

## Idempotent

Safe to run multiple times. Already-installed packages are skipped, the Kali repo is only added once, and XFCE setup checks for existing installations.

## Limitations

- **No GPU cracking** — The Mali-G31 on the H313 does not support CUDA or OpenCL. Hashcat runs on CPU only (~50-100 kH/s for MD5). Use a cloud rig or external GPU for serious cracking.
- **Limited RAM** — With 1-2 GB, avoid running multiple heavy tools simultaneously (e.g., Burp Suite + Metasploit + browser). Close unused apps.
- **Storage** — A full install (all categories + XFCE) requires ~6-8 GB. Use a 32 GB+ SD card for comfortable headroom.
- **Monitor mode** — The x96q has no built-in WiFi. You'll need a USB WiFi adapter that supports monitor mode (e.g., Alfa AWUS036ACH) for wireless tools.

## Contributing

1. Fork the repo
2. Edit `install.sh` (it's the only source file)
3. Run `shfmt -w -i 2 install.sh && shellcheck -x install.sh`
4. Open a pull request

## License

MIT
