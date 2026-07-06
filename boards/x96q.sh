#!/usr/bin/env bash
# Board config: x96q TV Box — Allwinner H313
# shellcheck disable=SC2034

readonly BOARD_NAME="x96q"
readonly BOARD_SOC="Allwinner H313 (quad-core Cortex-A53)"
readonly BOARD_PLATFORM="x96q TV Box"
readonly BOARD_RAM="1 GB"

board_banner() {
  echo -e "${CYAN}"
  echo "  ╔═══════════════════════════════════════════════╗"
  echo "  ║         armkali — Kali Tools for ARM64        ║"
  echo "  ║     x96q (Allwinner H313) • Armbian • XFCE   ║"
  echo "  ╚═══════════════════════════════════════════════╝"
  echo -e "${NC}"
}

board_arch_info() {
  echo -e "${CYAN}Architecture:${NC} $(uname -m)"
  echo -e "${CYAN}SoC:${NC}          Allwinner H313 (quad-core Cortex-A53)"
  echo -e "${CYAN}Platform:${NC}     x96q TV Box"
  echo -e "${CYAN}RAM:${NC}            ${BOARD_RAM}"
  echo -e "${CYAN}WiFi:${NC}           Built-in XRadio XR819 (2.4GHz b/g/n — no monitor mode)"
  echo -e "${CYAN}OS:${NC}            $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Armbian')"
  echo -e "${CYAN}Kernel:${NC}        $(uname -r)"
}

board_gpu_warning() {
  log WARN "GPU acceleration unavailable on Allwinner H313 (Mali-G31 has no OpenCL) — hashcat will use CPU only"
}

board_wireless_note() {
  log WARN "x96q has built-in WiFi (XRadio XR819, 2.4GHz b/g/n) but the XR819 driver does NOT support monitor mode"
  log WARN "For wireless pentesting (aircrack-ng, wifite, hcxdumptool), use a USB adapter with RTL8812AU / AR9271 / RT3070"
}

board_xfce_video_driver() {
  echo "xserver-xorg-video-fbdev"
}

board_post_install() {
  log WARN "8GB eMMC is tight for full install (~5-6GB) — prefer installing categories selectively"
  board_wireless_note
  system_tune
  enable_serial_console "ttyS0" "115200"
}
