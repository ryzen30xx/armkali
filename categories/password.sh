#!/usr/bin/env bash
# Password cracking tools
# shellcheck disable=SC2034

readonly PASSWORD_NAME="Password Cracking"
readonly PASSWORD_DESC="Hash cracking, brute-force, and dictionary attack tools"
readonly PASSWORD_PACKAGES=(
  hashcat
  john
  hydra
  medusa
  crunch
  cewl
  cupp
  fcrackzip
  pdfcrack
  rarcrack
  hash-identifier
  ophcrack
  ophcrack-cli
)

install_password() {
  log STEP "Installing Password Cracking Tools"
  log WARN "GPU acceleration unavailable on Allwinner H313 — hashcat will use CPU only"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${PASSWORD_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}
