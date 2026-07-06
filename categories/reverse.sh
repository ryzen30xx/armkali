#!/usr/bin/env bash
# Reverse engineering tools
# shellcheck disable=SC2034

readonly REVERSE_NAME="Reverse Engineering"
readonly REVERSE_DESC="Disassemblers, debuggers, and binary analysis"
readonly REVERSE_PACKAGES=(
  radare2
  ghidra
  gdb
  ollydump
  apktool
  dex2jar
  jadx
  jd-gui
  edb-debugger
  binwalk
  rizin
  cutter
)

install_reverse() {
  log STEP "Installing Reverse Engineering Tools"
  log WARN "Some RE tools require Java — will be installed as dependency"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${REVERSE_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}
