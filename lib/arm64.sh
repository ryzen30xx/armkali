#!/usr/bin/env bash
# ARM64/aarch64 compatibility checks for Allwinner H313 (x96q)

readonly ARM64_UNSUPPORTED=(
  "crackmapexec"
  "powersploit"
  "unicornscan"
  "fern-wifi-cracker"
  "cuda-hashcat"
)

readonly ARM64_ALTERNATIVES=(
  "crackmapexec:netexec"
  "cuda-hashcat:hashcat"
)

readonly X86_ONLY_PATTERNS=(
  "cuda"
  "nvidia"
  "opencl"
)

is_arm64() {
  [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]]
}

check_arch_compatibility() {
  local pkg="$1"

  for pattern in "${X86_ONLY_PATTERNS[@]}"; do
    if [[ "$pkg" == *"$pattern"* ]]; then
      return 1
    fi
  done

  for entry in "${ARM64_UNSUPPORTED[@]}"; do
    if [[ "$pkg" == "$entry" ]]; then
      return 1
    fi
  done

  return 0
}

get_alternative() {
  local pkg="$1"
  for entry in "${ARM64_ALTERNATIVES[@]}"; do
    local orig="${entry%%:*}"
    local alt="${entry##*:}"
    if [[ "$pkg" == "$orig" ]]; then
      echo "$alt"
      return 0
    fi
  done
  return 1
}

filter_arm64_packages() {
  local -a pkgs=("$@")
  local -a compatible=()
  local -a skipped=()

  for pkg in "${pkgs[@]}"; do
    if check_arch_compatibility "$pkg"; then
      compatible+=("$pkg")
    else
      local alt
      if alt="$(get_alternative "$pkg")" && pkg_available "$alt"; then
        compatible+=("$alt")
        skipped+=("${pkg}->${alt}")
      else
        skipped+=("$pkg")
      fi
    fi
  done

  if [[ ${#skipped[@]} -gt 0 ]]; then
    log WARN "ARM64 incompatible (skipped/substituted): ${skipped[*]}"
  fi

  echo "${compatible[@]}"
}

arch_info() {
  echo -e "${CYAN}Architecture:${NC} $(uname -m)"
  echo -e "${CYAN}SoC:${NC}          Allwinner H313 (quad-core Cortex-A53)"
  echo -e "${CYAN}Platform:${NC}     x96q TV Box"
  echo -e "${CYAN}OS:${NC}            $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo 'Armbian')"
  echo -e "${CYAN}Kernel:${NC}        $(uname -r)"
  echo -e "${CYAN}RAM:${NC}            $(awk '/MemTotal/ {printf "%.0f MB", $2/1024}' /proc/meminfo 2>/dev/null || echo 'unknown')"
}
