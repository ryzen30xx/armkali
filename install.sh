#!/usr/bin/env bash
#
# armkali — Kali Linux tools installer for ARM64 boards
#
# Supported boards:
#   • x96q TV Box (Allwinner H313, 1GB RAM)
#   • Raspberry Pi 3B+ (Broadcom BCM2837B0, 1GB RAM)
#
# One-line install:
#   curl -sSL https://raw.githubusercontent.com/ryzen30xx/armkali/main/install.sh | sudo bash
#
# Or clone and run:
#   git clone https://github.com/ryzen30xx/armkali.git && cd armkali && sudo ./install.sh
#
# Force a specific board:
#   ARMKALI_BOARD=rpi3bplus curl -sSL .../install.sh | sudo -E bash
#   ARMKALI_BOARD=x96q ./install.sh
#

set -euo pipefail

GH_RAW="https://raw.githubusercontent.com/ryzen30xx/armkali/main"

###############################################################################
# Pre-flight: root check (before any downloads)
###############################################################################

if [[ $EUID -ne 0 ]]; then
  echo "Error: This script must be run as root (sudo)." >&2
  exit 1
fi

###############################################################################
# Resolve SCRIPT_DIR — works for both local clone and curl pipe
###############################################################################

if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR="/tmp/armkali-$$"
  mkdir -p "$SCRIPT_DIR"
fi

###############################################################################
# Board detection
###############################################################################

detect_board() {
  if [[ -n "${ARMKALI_BOARD:-}" ]]; then
    echo "$ARMKALI_BOARD"
    return
  fi

  # Check /proc/device-tree/compatible (device tree based boards)
  local compat=""
  if [[ -f /proc/device-tree/compatible ]]; then
    compat="$(tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null)"
  fi

  if echo "$compat" | grep -qi "raspberry"; then
    echo "rpi3bplus"
    return
  fi

  if echo "$compat" | grep -qi "allwinner\|sun50i\|h313\|x96q"; then
    echo "x96q"
    return
  fi

  # Check /proc/cpuinfo
  local cpuinfo=""
  if [[ -f /proc/cpuinfo ]]; then
    cpuinfo="$(cat /proc/cpuinfo 2>/dev/null)"
  fi

  if echo "$cpuinfo" | grep -qi "BCM2837\|BCM2835\|Raspberry"; then
    echo "rpi3bplus"
    return
  fi

  if echo "$cpuinfo" | grep -qi "Allwinner\|sun50i\|H313"; then
    echo "x96q"
    return
  fi

  # Default fallback
  echo "x96q"
}

BOARD="$(detect_board)"

###############################################################################
# Ensure board files exist (download from GitHub if running via curl pipe)
###############################################################################

_ensure_file() {
  local path="$1"
  if [[ ! -f "${SCRIPT_DIR}/${path}" ]]; then
    mkdir -p "${SCRIPT_DIR}/$(dirname "$path")"
    curl -fsSL "${GH_RAW}/${path}" -o "${SCRIPT_DIR}/${path}" 2>/dev/null || {
      echo "Error: Could not download ${path} from GitHub" >&2
      exit 1
    }
  fi
}

_ensure_file "lib/common.sh"
_ensure_file "boards/${BOARD}.sh"

###############################################################################
# Source library and board config
###############################################################################

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/boards/${BOARD}.sh"

###############################################################################
# Entry point
###############################################################################

_register_all
ensure_ui
board_banner
log INFO "Detected board: ${BOARD_NAME} (${BOARD_SOC})"
main_menu
