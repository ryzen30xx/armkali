#!/usr/bin/env bash
# Board config: Raspberry Pi 3B+ — Broadcom BCM2837B0
# shellcheck disable=SC2034

readonly BOARD_NAME="rpi3bplus"
readonly BOARD_SOC="Broadcom BCM2837B0 (quad-core Cortex-A53)"
readonly BOARD_PLATFORM="Raspberry Pi 3B+"
readonly BOARD_RAM="1 GB"

board_banner() {
  echo -e "${CYAN}"
  echo "  ╔═══════════════════════════════════════════════╗"
  echo "  ║         armkali — Kali Tools for ARM64        ║"
  echo "  ║      Raspberry Pi 3B+ (BCM2837B0) • XFCE     ║"
  echo "  ╚═══════════════════════════════════════════════╝"
  echo -e "${NC}"
}

board_arch_info() {
  echo -e "${CYAN}Architecture:${NC} $(uname -m)"
  echo -e "${CYAN}SoC:${NC}          Broadcom BCM2837B0 (quad-core Cortex-A53 @ 1.4GHz)"
  echo -e "${CYAN}Platform:${NC}     Raspberry Pi 3B+"
  echo -e "${CYAN}RAM:${NC}            ${BOARD_RAM}"
  echo -e "${CYAN}WiFi:${NC}           Built-in 802.11n (2.4GHz) + Bluetooth 4.2"
  echo -e "${CYAN}GPU:${NC}            Broadcom VideoCore IV"
  echo -e "${CYAN}OS:${NC}            $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Armbian/Raspberry Pi OS')"
  echo -e "${CYAN}Kernel:${NC}        $(uname -r)"
}

board_gpu_warning() {
  log WARN "VideoCore IV GPU detected — hashcat uses CPU only (no CUDA/OpenCL on BCM2837B0)"
}

board_wireless_note() {
  log INFO "RPi 3B+ has built-in WiFi (brcmfmac) — monitor mode may require re4son kernel or external adapter for full support"
}

board_xfce_video_driver() {
  echo "xserver-xorg-video-fbdev"
}

board_post_install() {
  log STEP "Raspberry Pi 3B+ post-install configuration"

  log INFO "Installing RPi-specific hardware support packages..."
  install_packages_full \
    raspberrypi-userland \
    libraspberrypi0 \
    libraspberrypi-bin \
    firmware-brcm80211 \
    pi-bluetooth \
    hostapd

  log INFO "Configuring VC4 GPU driver for XFCE..."
  local config_txt="/boot/config.txt"
  if [[ -f "$config_txt" ]]; then
    if ! grep -q "dtoverlay=vc4-fkms-v3d" "$config_txt"; then
      {
        echo ""
        echo "# armkali: enable VC4 GPU acceleration"
        echo "dtoverlay=vc4-fkms-v3d"
      } >>"$config_txt"
      log INFO "Added dtoverlay=vc4-fkms-v3d to config.txt (reboot to apply)"
    else
      log INFO "VC4 overlay already configured"
    fi

    if ! grep -q "gpu_mem=" "$config_txt"; then
      echo "gpu_mem=128" >>"$config_txt"
      log INFO "Set gpu_mem=128MB for desktop rendering"
    fi
  else
    log WARN "/boot/config.txt not found — VC4 GPU config must be done manually"
  fi

  log INFO "Setting up 1GB swap file (recommended for RPi 3B+ with 1GB RAM)..."
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

  log INFO "Enabling Bluetooth service..."
  if command -v systemctl &>/dev/null; then
    systemctl enable bluetooth 2>/dev/null || true
  fi
}
