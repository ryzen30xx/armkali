#!/usr/bin/env bash
# XFCE desktop environment setup for Kali-style GUI on ARM64

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/repo.sh
source "${SCRIPT_DIR}/lib/repo.sh"

set -euo pipefail

xfce_is_installed() {
  command -v xfce4-session &>/dev/null && command -v startx &>/dev/null
}

xfce_install() {
  if xfce_is_installed; then
    log INFO "XFCE desktop is already installed"
    return 0
  fi

  log STEP "Installing XFCE Desktop Environment"

  log INFO "Installing X server and display manager..."
  install_packages_full \
    xorg \
    xserver-xorg-core \
    xserver-xorg-video-fbdev \
    lightdm \
    lightdm-gtk-greeter

  log INFO "Installing XFCE4 desktop..."
  install_packages_full \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    xfce4-power-manager \
    xfce4-screensaver \
    xfce4-notifyd

  log INFO "Installing Kali desktop theme..."
  local -a theme_pkgs=(kali-desktop-xfce kali-themes kali-menu)
  local -a available_theme=()
  for pkg in "${theme_pkgs[@]}"; do
    if pkg_available "$pkg"; then
      available_theme+=("$pkg")
    else
      log WARN "Theme package not available: $pkg"
    fi
  done
  if [[ ${#available_theme[@]} -gt 0 ]]; then
    install_packages_full "${available_theme[@]}"
  fi

  log INFO "Installing essential GUI utilities..."
  install_packages_full \
    dbus-x11 \
    x11-xserver-utils \
    xdg-utils \
    mesa-utils \
    pulseaudio \
    pavucontrol \
    network-manager-gnome \
    thunar-archive-plugin \
    file-roller \
    mousepad \
    firefox-esr

  log INFO "Enabling LightDM display manager..."
  if command -v systemctl &>/dev/null; then
    systemctl enable lightdm 2>/dev/null || true
    systemctl set-default graphical.target 2>/dev/null || true
  fi

  log INFO "XFCE desktop environment installed successfully"
}

xfce_configure_autologin() {
  local user="${1:-}"
  if [[ -z "$user" ]]; then
    user="$(logname 2>/dev/null || echo "${SUDO_USER:-root}")"
  fi

  if [[ "$user" == "root" ]]; then
    log WARN "Skipping autologin for root user"
    return 0
  fi

  local lightdm_conf="/etc/lightdm/lightdm.conf.d/90-autologin.conf"
  log INFO "Configuring autologin for user: $user"
  mkdir -p "$(dirname "$lightdm_conf")"
  cat >"$lightdm_conf" <<EOF
[Seat:*]
autologin-user=${user}
autologin-user-timeout=0
EOF

  log INFO "Autologin configured for $user"
}

xfce_start() {
  log STEP "Starting XFCE Desktop"
  if command -v systemctl &>/dev/null; then
    systemctl start lightdm 2>/dev/null && {
      log INFO "LightDM started — GUI should appear on your display"
      return 0
    }
  fi
  log INFO "To start the desktop, reboot or run: sudo systemctl start lightdm"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  check_root
  repo_setup
  xfce_install
  xfce_configure_autologin
  echo ""
  log INFO "XFCE setup complete. Reboot to start the graphical desktop."
fi
