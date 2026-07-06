#!/usr/bin/env bash
# Information gathering tools
# shellcheck disable=SC2034

readonly INFOGATHER_NAME="Information Gathering"
readonly INFOGATHER_DESC="Scanners, enumerators, and OSINT tools"
readonly INFOGATHER_PACKAGES=(
  nmap
  masscan
  fierce
  theharvester
  maltego
  recon-ng
  spiderfoot
  whois
  dnsrecon
  dnsenum
  amass
  sublist3r
  sherlock
  holehe
  ghunt
  shodan
  metabigor
)

install_infogather() {
  log STEP "Installing Information Gathering Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${INFOGATHER_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}
