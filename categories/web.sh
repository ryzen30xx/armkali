#!/usr/bin/env bash
# Web application testing tools
# shellcheck disable=SC2034

readonly WEB_NAME="Web Application Analysis"
readonly WEB_DESC="Web scanners, proxies, and exploitation tools"
readonly WEB_PACKAGES=(
  burpsuite
  sqlmap
  nikto
  dirb
  dirbuster
  gobuster
  ffuf
  whatweb
  wpscan
  commix
  zaproxy
  fierce
  theharvester
  maltego
  sublist3r
  httrack
  skipfish
  cadaver
)

install_web() {
  log STEP "Installing Web Application Analysis Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${WEB_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}
