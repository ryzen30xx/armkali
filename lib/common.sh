#!/usr/bin/env bash
# Common variables and utility functions for armkali installer

export DEBIAN_FRONTEND=noninteractive
export KALI_KEYRING_URL="https://archive.kali.org/archive-keyring.gpg"
export KALI_KEYRING_PATH="/usr/share/keyrings/kali-archive-keyring.gpg"
export KALI_SOURCES_LIST="/etc/apt/sources.list.d/kali.list"
export LOG_FILE="/var/log/armkali-install.log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

log() {
  local level="$1"
  shift
  local msg="$*"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "${ts} [${level}] ${msg}" >>"$LOG_FILE" 2>/dev/null || true
  case "$level" in
  INFO) echo -e "${GREEN}[+]${NC} ${msg}" ;;
  WARN) echo -e "${YELLOW}[!]${NC} ${msg}" ;;
  ERROR) echo -e "${RED}[-]${NC} ${msg}" ;;
  STEP) echo -e "\n${CYAN}${BOLD}>>> ${msg}${NC}" ;;
  esac
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root (sudo).${NC}" >&2
    exit 1
  fi
}

confirm() {
  local prompt="${1:-Continue?}"
  if [[ -n "${ARMKALI_YES:-}" ]]; then
    return 0
  fi
  echo -en "${BOLD}${prompt} [y/N] ${NC}"
  read -r answer
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

pkg_available() {
  local pkg="$1"
  apt-cache show "$pkg" &>/dev/null
}

install_packages() {
  local -a pkgs=("$@")
  local -a available=()
  local -a missing=()

  for pkg in "${pkgs[@]}"; do
    if pkg_available "$pkg"; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log WARN "Skipping unavailable packages: ${missing[*]}"
  fi

  if [[ ${#available[@]} -eq 0 ]]; then
    log WARN "No packages to install from this group"
    return 0
  fi

  log INFO "Installing ${#available[@]} package(s)..."
  apt-get install -y --no-install-recommends "${available[@]}" 2>&1 | tee -a "$LOG_FILE"
}

install_packages_full() {
  local -a pkgs=("$@")
  local -a available=()
  local -a missing=()

  for pkg in "${pkgs[@]}"; do
    if pkg_available "$pkg"; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log WARN "Skipping unavailable packages: ${missing[*]}"
  fi

  if [[ ${#available[@]} -eq 0 ]]; then
    log WARN "No packages to install from this group"
    return 0
  fi

  log INFO "Installing ${#available[@]} package(s)..."
  apt-get install -y "${available[@]}" 2>&1 | tee -a "$LOG_FILE"
}

count_installed() {
  local -a pkgs=("$@")
  local count=0
  for pkg in "${pkgs[@]}"; do
    if dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'; then
      ((count++))
    fi
  done
  echo "$count"
}

system_update() {
  log STEP "Updating package lists"
  apt-get update 2>&1 | tee -a "$LOG_FILE"
}

system_upgrade() {
  log STEP "Upgrading existing packages"
  apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"
}

banner() {
  echo -e "${CYAN}"
  echo "  ╔═══════════════════════════════════════════════╗"
  echo "  ║         armkali — Kali Tools for ARM64        ║"
  echo "  ║     x96q (Allwinner H313) • Armbian • XFCE   ║"
  echo "  ╚═══════════════════════════════════════════════╝"
  echo -e "${NC}"
}
