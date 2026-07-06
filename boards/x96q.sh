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
  echo -e "${CYAN}OS:${NC}            $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Armbian')"
  echo -e "${CYAN}Kernel:${NC}        $(uname -r)"
}

board_gpu_warning() {
  log WARN "GPU acceleration unavailable on Allwinner H313 (Mali-G31 has no OpenCL) — hashcat will use CPU only"
}

board_wireless_note() {
  log WARN "x96q has no built-in WiFi — use a USB WiFi adapter with monitor mode support (e.g., Alfa AWUS036ACH)"
}

board_xfce_video_driver() {
  echo "xserver-xorg-video-fbdev"
}

board_post_install() {
  log INFO "Setting up 1GB swap file (recommended for Allwinner H313 with 1GB RAM)..."
  if [[ ! -f /swapfile ]]; then
    fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    if ! grep -q '/swapfile' /etc/fstab; then
      echo '/swapfile none swap sw 0 0' >>/etc/fstab
    fi
    log INFO "1GB swap file created and enabled"
  else
    log INFO "Swap file already exists"
  fi
}
