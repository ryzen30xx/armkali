#!/usr/bin/env bash
# Wireless attack tools
# shellcheck disable=SC2034

readonly WIRELESS_NAME="Wireless Attacks"
readonly WIRELESS_DESC="WiFi, Bluetooth, and RF tools"
readonly WIRELESS_PACKAGES=(
  aircrack-ng
  reaver
  bully
  cowpatty
  pixiewps
  wifite
  kismet
  hashcat
  hcxdumptool
  hcxtools
  bettercap
  mdk4
  wavemon
  wireshark
)

install_wireless() {
  log STEP "Installing Wireless Attack Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${WIRELESS_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}
