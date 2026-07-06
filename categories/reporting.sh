#!/usr/bin/env bash
# Reporting and documentation tools
# shellcheck disable=SC2034

readonly REPORTING_NAME="Reporting"
readonly REPORTING_DESC="Report generation and documentation tools"
readonly REPORTING_PACKAGES=(
  eyewitness
  cutycapt
  pipal
  cherrytree
  keepnote
  dradis
)

install_reporting() {
  log STEP "Installing Reporting Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${REPORTING_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}
