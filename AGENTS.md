# AGENTS.md

This file provides guidance to the AI agent when working with code in this repository.

## Project Overview

Build a Bash installer script for penetration testing, ethical hacking, and security auditing tools (as found on Kali Linux) on **ARM64 single-board computers**. The installer auto-detects the board and applies board-specific configuration. Currently supported boards:

- **x96q TV Box** (Allwinner H313 SoC, 1GB RAM, Armbian)
- **Raspberry Pi 3B+** (Broadcom BCM2837B0 SoC, 1GB RAM, Raspberry Pi OS/Armbian)

The installer must also set up a **Kali Linux GUI** using **XFCE**.

## Target Platforms

| | x96q TV Box | Raspberry Pi 3B+ |
|---|---|---|
| **SoC** | Allwinner H313 | Broadcom BCM2837B0 |
| **CPU** | Quad-core Cortex-A53 @ 1.5GHz | Quad-core Cortex-A53 @ 1.4GHz |
| **RAM** | 1 GB | 1 GB |
| **Architecture** | `arm64` / `aarch64` | `arm64` / `aarch64` |
| **WiFi** | None (USB adapter required) | Built-in 802.11n + BT 4.2 |
| **GPU** | Mali-G31 (no OpenCL) | VideoCore IV |
| **OS** | Armbian | Raspberry Pi OS / Armbian |

- Never assume x86/x86_64 binaries exist
- **GUI**: XFCE4 desktop environment
- **Constraints**: Limited RAM (1 GB), eMMC or SD-card storage, no discrete GPU for hashcat

## Scripting Conventions

- Use **Bash** (not POSIX sh, not zsh)
- Indent with **2 spaces** (enforced by shfmt: `shfmt -w -i 2`)
- Run **shellcheck** before committing: `shellcheck -x <script.sh>`
- All scripts must be **idempotent** — safe to run multiple times without side effects
- Use `set -euo pipefail` at the top of every script
- Prefer `[[ ]]` over `[ ]`, use bash arrays, process substitution, and other modern bash features
- Use `apt-get` (not `apt`) in scripts for predictable non-interactive behavior
- Always use `DEBIAN_FRONTEND=noninteractive` for unattended package installs
- Check for root/sudo at script entry; exit early with a clear message if missing

## Installer Architecture

- **Entry point**: `install.sh` — board auto-detection, downloads board files from GitHub if running via `curl | bash`
- **Shared library**: `lib/common.sh` — utilities, UI, repo management, ARM64 compat, all 9 categories, XFCE setup, menu system
- **Board configs**: `boards/x96q.sh`, `boards/rpi3bplus.sh` — board constants, hardware hooks, post-install steps
- **Board hooks**: `board_banner()`, `board_arch_info()`, `board_gpu_warning()`, `board_wireless_note()`, `board_xfce_video_driver()`, `board_post_install()`
- **One-line install**: `curl -sSL https://raw.githubusercontent.com/ryzen30xx/armkali/main/install.sh | sudo bash`
- **Force board**: `ARMKALI_BOARD=rpi3bplus` or `ARMKALI_BOARD=x96q` environment variable
- **Menu-driven**: `whiptail` (preferred) or `dialog` with terminal fallback
- **Categories**: Wireless, Web, Forensics, Exploitation, Password Cracking, Sniffing/Spoofing, Reverse Engineering, Information Gathering, Reporting
- Each category defines a `_NAME`, `_DESC`, `_PACKAGES` array, and an `install_*` function
- Categories registered in `_register_all()` into parallel arrays (`CAT_TAGS`, `CAT_NAMES`, `CAT_DESCS`, `CAT_FUNCS`)
- Kali tool repo added via GPG keyring + `apt sources` — use Kali ARM64 repos
- Verify package availability with `apt-cache show <pkg>` before attempting install
- XFCE setup is a menu option with board-specific video driver via `board_xfce_video_driver()`

## ARM64 / Kali Compatibility Notes

- Most Kali tools are in the `kali-linux-default` / `kali-linux-large` ARM64 repos
- Some tools ship only x86 binaries — check and skip with a warning rather than failing
- Tools known to need special handling on ARM64: `exploitdb`, some commercial tools, CUDA-dependent tools (hashcat with GPU)
- Prefer `apt install` over compiling from source unless the package is missing for arm64

## Lint and Format

- **Formatter**: `shfmt -w -i 2 <file>` (auto-applied on edit via hook)
- **Linter**: `shellcheck -x <file>`
- Run both before marking any script change as complete
