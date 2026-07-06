# AGENTS.md

This file provides guidance to the AI agent when working with code in this repository.

## Project Overview

Build a Bash installer script for penetration testing, ethical hacking, and security auditing tools (as found on Kali Linux) on **ARM64 single-board computers**. The installer auto-detects the board and applies board-specific configuration. Currently supported board:

- **x96q TV Box** (Allwinner H313 SoC, 1GB RAM, Armbian)

The installer must also set up a **Kali Linux GUI** using **XFCE**.

## Target Platforms

| | x96q TV Box |
|---|---|
| **SoC** | Allwinner H313 |
| **CPU** | Quad-core Cortex-A53 @ 1.5GHz |
| **RAM** | 1 GB |
| **Architecture** | `arm64` / `aarch64` |
| **WiFi** | XRadio XR819 (2.4GHz, no monitor mode) |
| **GPU** | Mali-G31 (no OpenCL) |
| **OS** | Armbian |

- Never assume x86/x86_64 binaries exist
- **GUI**: XFCE4 desktop environment
- **Constraints**: Base spec is **1GB RAM / 8GB eMMC**. No discrete GPU for hashcat. Installer is tuned for this floor (see "Base Spec Optimizations" below).

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
- **Board configs**: `boards/x96q.sh` — board constants, hardware hooks, post-install steps
- **Board hooks**: `board_banner()`, `board_arch_info()`, `board_gpu_warning()`, `board_wireless_note()`, `board_xfce_video_driver()`, `board_system_tune()`, `board_post_install()`
- **One-line install**: `curl -sSL https://raw.githubusercontent.com/ryzen30xx/armkali/main/install.sh | sudo bash`
- **Force board**: `ARMKALI_BOARD=x96q` environment variable
- **Menu-driven**: `whiptail` (preferred) or `dialog` with terminal fallback
- **Categories**: Wireless, Web, Forensics, Exploitation, Password Cracking, Sniffing/Spoofing, Reverse Engineering, Information Gathering, Reporting
- Each category defines a `_NAME`, `_DESC`, `_PACKAGES` array, and an `install_*` function
- Categories registered in `_register_all()` into parallel arrays (`CAT_TAGS`, `CAT_NAMES`, `CAT_DESCS`, `CAT_FUNCS`)
- Kali tool repo added via GPG keyring + `apt sources` — use Kali ARM64 repos
- Verify package availability via `pkg_available()` (uses preloaded associative array from `pkg_cache_preload()`; falls back to `apt-cache show` if cache is empty)
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

## Base Spec Optimizations

The installer is tuned for the **1GB RAM / 8GB eMMC** base hardware. **CPU and RAM are soldered (fixed); only storage is upgradable.** Do not regress these:

### RAM-tier architecture (do not change)

- **`detect_ram_tier()`** — reads `/proc/meminfo` and returns `base` (<1.5GB) or `extended`. Result stored in `readonly RAM_TIER`. Called once at startup.
- **`install_tiered()`** — unified helper that accepts `--base <pkgs>` and `--extra <pkgs>`. Always installs BASE; installs EXTRA only if `RAM_TIER=extended`. On base tier, logs skipped extras with CLI alternative hints.
- **Category split pattern** — each category now has `_PACKAGES_BASE` (lightweight CLI) and `_PACKAGES_EXTRA` (Java/GUI/memory-hogs). Example: `WEB_PACKAGES_BASE` = sqlmap/nikto/ffuf (light); `WEB_PACKAGES_EXTRA` = burpsuite/zaproxy/maltego (Java, 500MB-1GB RAM).
- **`Low-RAM Essentials` category** — hand-picked 27 lightest tools across all 9 categories. Tag `lowram`, registered first in `_register_all()`. Always safe on 1GB.
- **Auto-skipped on 1GB**: burpsuite, zaproxy, maltego, ghidra, jadx, jd-gui, cutter, edb-debugger, wireshark, tshark, kismet, autopsy, guymager, python3-plaso, bulk-extractor, beef-xss, social-engineer-toolkit, hashcat, ophcrack, spiderfoot, metabigor, eyewitness, cutycapt, cherrytree, keepnote, dradis.

### Dev-kit UART (default-on — do not gate behind confirm)

- **`enable_serial_console <tty> <baud>`** — helper in `lib/common.sh`. Writes a systemd override (`/etc/systemd/system/serial-getty@<tty>.service.d/override.conf`) with `agetty -8 -L <tty> <baud> $TERM`, then enables + starts the unit. Idempotent.
- **x96q**: `enable_serial_console "ttyS0" "115200"` — H313 UART pads on PCB (RX/TX/GND between USB1 and CVBS socket).
- Default-on policy: the board is sold as a dev kit — users buying a cheap ARM box expect serial access for boot-log debugging and headless recovery. Do not prompt for confirmation.

### XFCE 1GB tuning (do not remove)

- **`xfce_tune_1gb()`** — writes xfconf XML to disable compositor, shadows, animations, thumbnails. Runs only when `RAM_TIER=base` and a non-root user exists. Called from `action_install_gui` and `action_install_all`. Saves ~50MB RAM.
- **`tumblerd` masked** — thumbnailer disabled (heavy on eMMC I/O and CPU).
- **`thunar-volman` disabled** — automount polling disabled (saves CPU cycles).

### Storage tuning (less critical — storage is upgradable)

- **`pkg_cache_preload()`** — called after `apt-get update` in `repo_setup()`. Loads `apt-cache dumpavail` into an associative array. `pkg_available()` consults the array in O(1) instead of shelling out per-package (2-5s each on eMMC).
- **`system_tune()`** — default hook in `lib/common.sh`. Writes `/etc/apt/apt.conf.d/90-armkali-minimal` (no recommends/suggests/translations), creates a 1GB `/swapfile`, sets up 512MB zram compressed swap with priority 100, and bumps `vm.swappiness` to 60. Board files may override `board_system_tune()` to do board-specific tuning before calling `system_tune()`.
- **All `install_*` functions use `install_packages` (with `--no-install-recommends`)**. Do not re-add `install_packages_full` — it was removed.
- **XFCE minimal**: dropped `xfce4-goodies`, `xfce4-screensaver`, `firefox-esr`, `pulseaudio`, `pavucontrol` to fit 8GB eMMC.
- **`check_disk_space()`** — fails if `/var` <100MB, warns if `/` <2GB. Wired into `action_install_all()`.
