# AGENTS.md

This file provides guidance to the AI agent when working with code in this repository.

## Project Overview

Build a Bash installer script for penetration testing, ethical hacking, and security auditing tools (as found on Kali Linux) on **Armbian for the x96q TV box** (Allwinner H313 SoC, aarch64). The installer must also set up a **Kali Linux GUI** using **XFCE**.

## Target Platform

- **SoC**: Allwinner H313 (quad-core Cortex-A53, aarch64)
- **OS**: Armbian (Debian/Ubuntu base, aarch64)
- **Architecture**: `arm64` / `aarch64` — never assume x86/x86_64 binaries exist
- **GUI**: XFCE4 desktop environment
- **Constraints**: Limited RAM (~1-2 GB), eMMC or SD-card storage, no discrete GPU for hashcat

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

- **Menu-driven**: Use `dialog` or `whiptail` for a categorized tool selection UI
- **Categories**: Wireless, Web, Forensics, Exploitation, Password Cracking, Sniffing/Spoofing, Reverse Engineering, Information Gathering, Reporting
- Each category maps to a list of packages; user selects categories or individual tools
- Kali tool repo added via `apt sources` — use Kali ARM64 repos, not x86 metapackages blindly
- Verify package availability with `apt-cache show <pkg>` before attempting install
- XFCE setup is a separate step: `xfce4`, `xfce4-goodies`, `kali-desktop-xfce`

## ARM64 / Kali Compatibility Notes

- Most Kali tools are in the `kali-linux-default` / `kali-linux-large` ARM64 repos
- Some tools ship only x86 binaries — check and skip with a warning rather than failing
- Tools known to need special handling on ARM64: `exploitdb`, some commercial tools, CUDA-dependent tools (hashcat with GPU)
- Prefer `apt install` over compiling from source unless the package is missing for arm64

## Lint and Format

- **Formatter**: `shfmt -w -i 2 <file>` (auto-applied on edit via hook)
- **Linter**: `shellcheck -x <file>`
- Run both before marking any script change as complete
