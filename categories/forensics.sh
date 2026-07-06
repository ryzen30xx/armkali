#!/usr/bin/env bash
# Digital forensics tools
# shellcheck disable=SC2034

readonly FORENSICS_NAME="Forensics"
readonly FORENSICS_DESC="Disk imaging, memory analysis, and evidence gathering"
readonly FORENSICS_PACKAGES=(
  autopsy
  sleuthkit
  binwalk
  foremost
  scalpel
  testdisk
  gddrescue
  afflib-tools
  ewf-tools
  chntpw
  dc3dd
  guymager
  libregf-utils
  python3-plaso
  bulk-extractor
)

install_forensics() {
  log STEP "Installing Forensics Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${FORENSICS_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}
