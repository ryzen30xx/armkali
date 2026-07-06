#!/usr/bin/env bash
# Sniffing and spoofing tools
# shellcheck disable=SC2034

readonly SNIFFING_NAME="Sniffing & Spoofing"
readonly SNIFFING_DESC="Network sniffing, MITM, and spoofing tools"
readonly SNIFFING_PACKAGES=(
  wireshark
  tshark
  ettercap-text-only
  bettercap
  responder
  mitmproxy
  sslstrip
  tcpflow
  ngrep
  netsniff-ng
  macchanger
  arpspoof
  dnschef
)

install_sniffing() {
  log STEP "Installing Sniffing & Spoofing Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${SNIFFING_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}
