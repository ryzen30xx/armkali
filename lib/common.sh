#!/usr/bin/env bash
# armkali — shared library (utilities, categories, XFCE, menu)
# shellcheck disable=SC2034

###############################################################################
# Constants
###############################################################################

export DEBIAN_FRONTEND=noninteractive
readonly KALI_KEYRING_URL="https://archive.kali.org/archive-keyring.gpg"
readonly KALI_KEYRING_PATH="/usr/share/keyrings/kali-archive-keyring.gpg"
readonly KALI_SOURCES_LIST="/etc/apt/sources.list.d/kali.list"
readonly LOG_FILE="/var/log/armkali-install.log"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

###############################################################################
# Utility functions
###############################################################################

log() {
  local level="$1"
  shift
  local msg="$*"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "${ts} [${level}] ${msg}" >>"$LOG_FILE" 2>/dev/null || true
  case "$level" in
  INFO) echo -e "${GREEN}[+]${NC} ${msg}" ;;
  WARN) echo -e "${YELLOW}[!]${NC} ${msg}" ;;
  ERROR) echo -e "${RED}[-]${NC} ${msg}" ;;
  STEP) echo -e "\n${CYAN}${BOLD}>>> ${msg}${NC}" ;;
  esac
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root (sudo).${NC}" >&2
    exit 1
  fi
}

confirm() {
  local prompt="${1:-Continue?}"
  if [[ -n "${ARMKALI_YES:-}" ]]; then
    return 0
  fi
  echo -en "${BOLD}${prompt} [y/N] ${NC}"
  read -r answer
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

pkg_available() {
  local pkg="$1"
  apt-cache show "$pkg" &>/dev/null
}

install_packages() {
  local -a pkgs=("$@")
  local -a available=()
  local -a missing=()

  for pkg in "${pkgs[@]}"; do
    if pkg_available "$pkg"; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log WARN "Skipping unavailable packages: ${missing[*]}"
  fi

  if [[ ${#available[@]} -eq 0 ]]; then
    log WARN "No packages to install from this group"
    return 0
  fi

  log INFO "Installing ${#available[@]} package(s)..."
  apt-get install -y --no-install-recommends "${available[@]}" 2>&1 | tee -a "$LOG_FILE"
}

install_packages_full() {
  local -a pkgs=("$@")
  local -a available=()
  local -a missing=()

  for pkg in "${pkgs[@]}"; do
    if pkg_available "$pkg"; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log WARN "Skipping unavailable packages: ${missing[*]}"
  fi

  if [[ ${#available[@]} -eq 0 ]]; then
    log WARN "No packages to install from this group"
    return 0
  fi

  log INFO "Installing ${#available[@]} package(s)..."
  apt-get install -y "${available[@]}" 2>&1 | tee -a "$LOG_FILE"
}

system_update() {
  log STEP "Updating package lists"
  apt-get update 2>&1 | tee -a "$LOG_FILE"
}

system_upgrade() {
  log STEP "Upgrading existing packages"
  apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"
}

###############################################################################
# UI — whiptail/dialog with terminal fallback
###############################################################################

_ui_cmd() {
  if command -v whiptail &>/dev/null; then
    echo "whiptail"
  elif command -v dialog &>/dev/null; then
    echo "dialog"
  else
    echo ""
  fi
}

ensure_ui() {
  local cmd
  cmd="$(_ui_cmd)"
  if [[ -z "$cmd" ]]; then
    log INFO "Installing whiptail for menu interface..."
    apt-get install -y --no-install-recommends whiptail 2>&1 | tee -a "$LOG_FILE"
  fi
}

show_menu() {
  local title="$1"
  local text="$2"
  shift 2
  local -a items=("$@")
  local cmd result
  cmd="$(_ui_cmd)"

  if [[ -z "$cmd" ]]; then
    _fallback_menu "$title" "$text" "${items[@]}"
    return
  fi

  local height=$((${#items[@]} / 2 + 8))
  ((height > 24)) && height=24

  result=$($cmd --title "$title" \
    --menu "$text" "$height" 70 16 \
    "${items[@]}" \
    3>&1 1>&2 2>&3) || return 1

  echo "$result"
}

show_checklist() {
  local title="$1"
  local text="$2"
  shift 2
  local -a items=("$@")
  local cmd result
  cmd="$(_ui_cmd)"

  if [[ -z "$cmd" ]]; then
    _fallback_checklist "$title" "$text" "${items[@]}"
    return
  fi

  local height=$((${#items[@]} / 3 + 8))
  ((height > 24)) && height=24

  result=$($cmd --title "$title" \
    --checklist "$text" "$height" 70 16 \
    "${items[@]}" \
    3>&1 1>&2 2>&3) || return 1

  echo "$result"
}

show_msgbox() {
  local title="$1"
  local text="$2"
  local cmd
  cmd="$(_ui_cmd)"

  if [[ -z "$cmd" ]]; then
    echo -e "\n${BOLD}${title}${NC}"
    echo "$text"
    echo ""
    read -r -p "Press Enter to continue..."
    return
  fi

  $cmd --title "$title" --msgbox "$text" 16 70 3>&1 1>&2 2>&3
}

show_infobox() {
  local title="$1"
  local text="$2"
  local cmd
  cmd="$(_ui_cmd)"

  if [[ -z "$cmd" ]]; then
    echo -e "${CYAN}[${title}]${NC} ${text}"
    return
  fi

  $cmd --title "$title" --infobox "$text" 8 60 3>&1 1>&2 2>&3
}

_fallback_menu() {
  local title="$1"
  local text="$2"
  shift 2
  local -a items=("$@")
  local i=1

  echo -e "\n${BOLD}${title}${NC}"
  echo "$text"
  echo ""

  while [[ $i -le ${#items[@]} ]]; do
    local tag="${items[$((i - 1))]}"
    local desc="${items[$i]}"
    printf "  %2d) %-20s %s\n" "$i" "$tag" "$desc"
    ((i += 2))
  done

  echo ""
  echo -n "Enter selection: "
  read -r choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#items[@]} / 2)); then
    echo "${items[$(((choice - 1) * 2))]}"
  else
    return 1
  fi
}

_fallback_checklist() {
  local title="$1"
  local text="$2"
  shift 2
  local -a items=("$@")
  local i=1
  local -a selected=()

  echo -e "\n${BOLD}${title}${NC}"
  echo "$text"
  echo "Enter numbers to toggle (comma-separated), then press Enter:"
  echo ""

  while [[ $i -le ${#items[@]} ]]; do
    local tag="${items[$((i - 1))]}"
    local desc="${items[$i]}"
    local status="${items[$((i + 1))]}"
    printf "  %2d) [%s] %-20s %s\n" "$(((i - 1) / 3 + 1))" "$status" "$tag" "$desc"
    ((i += 3))
  done

  echo ""
  echo -n "Toggle items: "
  read -r choices

  i=1
  while [[ $i -le ${#items[@]} ]]; do
    local tag="${items[$((i - 1))]}"
    local idx=$(((i - 1) / 3 + 1))
    local status="${items[$((i + 1))]}"

    if [[ ",$choices," == *",$idx,"* ]]; then
      if [[ "$status" == "ON" ]]; then
        status="OFF"
      else
        status="ON"
      fi
    fi

    if [[ "$status" == "ON" ]]; then
      selected+=("\"$tag\"")
    fi
    ((i += 3))
  done

  echo "${selected[*]}"
}

###############################################################################
# Kali repository management
###############################################################################

repo_is_configured() {
  [[ -f "$KALI_SOURCES_LIST" ]] && grep -q "kali.org" "$KALI_SOURCES_LIST" 2>/dev/null
}

repo_setup() {
  if repo_is_configured; then
    log INFO "Kali repository already configured"
    return 0
  fi

  log STEP "Setting up Kali Linux ARM64 repository"

  log INFO "Installing prerequisites..."
  apt-get install -y --no-install-recommends \
    curl gnupg2 ca-certificates 2>&1 | tee -a "$LOG_FILE"

  log INFO "Downloading Kali archive keyring..."
  mkdir -p "$(dirname "$KALI_KEYRING_PATH")"
  curl -fsSL "$KALI_KEYRING_URL" -o "$KALI_KEYRING_PATH"

  log INFO "Adding Kali repository..."
  cat >"$KALI_SOURCES_LIST" <<EOF
deb [signed-by=${KALI_KEYRING_PATH}] http://http.kali.org/kali kali-rolling main contrib non-free
EOF

  log INFO "Updating package lists..."
  apt-get update 2>&1 | tee -a "$LOG_FILE"
  log INFO "Kali repository configured successfully"
}

repo_status() {
  if repo_is_configured; then
    echo -e "${GREEN}●${NC} Kali repository: configured"
  else
    echo -e "${RED}●${NC} Kali repository: not configured"
  fi
}

###############################################################################
# ARM64 compatibility
###############################################################################

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

###############################################################################
# Board hook defaults (overridden by board files)
###############################################################################

board_banner() {
  echo -e "${CYAN}"
  echo "  ╔═══════════════════════════════════════════════╗"
  echo "  ║         armkali — Kali Tools for ARM64        ║"
  echo "  ╚═══════════════════════════════════════════════╝"
  echo -e "${NC}"
}

board_arch_info() {
  echo -e "${CYAN}Architecture:${NC} $(uname -m)"
  echo -e "${CYAN}OS:${NC}            $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Armbian')"
  echo -e "${CYAN}Kernel:${NC}        $(uname -r)"
  echo -e "${CYAN}RAM:${NC}            $(awk '/MemTotal/ {printf "%.0f MB", $2/1024}' /proc/meminfo 2>/dev/null || echo 'unknown')"
}

board_gpu_warning() {
  log WARN "GPU acceleration not available — hashcat will use CPU only"
}

board_wireless_note() { :; }
board_xfce_video_driver() { echo "xserver-xorg-video-fbdev"; }
board_post_install() { :; }

###############################################################################
# Category: Wireless Attacks
###############################################################################

readonly WIRELESS_NAME="Wireless Attacks"
readonly WIRELESS_DESC="WiFi, Bluetooth, and RF tools"
readonly WIRELESS_PACKAGES=(
  aircrack-ng reaver bully cowpatty pixiewps wifite
  kismet hashcat hcxdumptool hcxtools bettercap mdk4
  wavemon wireshark
)

install_wireless() {
  log STEP "Installing Wireless Attack Tools"
  board_wireless_note
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${WIRELESS_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# Category: Web Application Analysis
###############################################################################

readonly WEB_NAME="Web Application Analysis"
readonly WEB_DESC="Web scanners, proxies, and exploitation tools"
readonly WEB_PACKAGES=(
  burpsuite sqlmap nikto dirb dirbuster gobuster ffuf
  whatweb wpscan commix zaproxy fierce theharvester
  maltego sublist3r httrack skipfish cadaver
)

install_web() {
  log STEP "Installing Web Application Analysis Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${WEB_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# Category: Forensics
###############################################################################

readonly FORENSICS_NAME="Forensics"
readonly FORENSICS_DESC="Disk imaging, memory analysis, and evidence gathering"
readonly FORENSICS_PACKAGES=(
  autopsy sleuthkit binwalk foremost scalpel testdisk
  gddrescue afflib-tools ewf-tools chntpw dc3dd guymager
  libregf-utils python3-plaso bulk-extractor
)

install_forensics() {
  log STEP "Installing Forensics Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${FORENSICS_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# Category: Exploitation
###############################################################################

readonly EXPLOITATION_NAME="Exploitation"
readonly EXPLOITATION_DESC="Exploit frameworks, payloads, and vulnerability assessment"
readonly EXPLOITATION_PACKAGES=(
  metasploit-framework searchsploit sqlmap beef-xss
  social-engineer-toolkit crackmapexec impacket-scripts
  evil-winrm responder empire routersploit ysoserial commix
)

install_exploitation() {
  log STEP "Installing Exploitation Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${EXPLOITATION_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# Category: Password Cracking
###############################################################################

readonly PASSWORD_NAME="Password Cracking"
readonly PASSWORD_DESC="Hash cracking, brute-force, and dictionary attack tools"
readonly PASSWORD_PACKAGES=(
  hashcat john hydra medusa crunch cewl cupp
  fcrackzip pdfcrack rarcrack hash-identifier
  ophcrack ophcrack-cli
)

install_password() {
  log STEP "Installing Password Cracking Tools"
  board_gpu_warning
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${PASSWORD_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# Category: Sniffing & Spoofing
###############################################################################

readonly SNIFFING_NAME="Sniffing & Spoofing"
readonly SNIFFING_DESC="Network sniffing, MITM, and spoofing tools"
readonly SNIFFING_PACKAGES=(
  wireshark tshark ettercap-text-only bettercap responder
  mitmproxy sslstrip tcpflow ngrep netsniff-ng macchanger
  arpspoof dnschef
)

install_sniffing() {
  log STEP "Installing Sniffing & Spoofing Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${SNIFFING_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# Category: Reverse Engineering
###############################################################################

readonly REVERSE_NAME="Reverse Engineering"
readonly REVERSE_DESC="Disassemblers, debuggers, and binary analysis"
readonly REVERSE_PACKAGES=(
  radare2 ghidra gdb apktool dex2jar jadx jd-gui
  edb-debugger binwalk rizin cutter
)

install_reverse() {
  log STEP "Installing Reverse Engineering Tools"
  log WARN "Some RE tools require Java — will be installed as dependency"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${REVERSE_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# Category: Information Gathering
###############################################################################

readonly INFOGATHER_NAME="Information Gathering"
readonly INFOGATHER_DESC="Scanners, enumerators, and OSINT tools"
readonly INFOGATHER_PACKAGES=(
  nmap masscan fierce theharvester maltego recon-ng
  spiderfoot whois dnsrecon dnsenum amass sublist3r
  sherlock holehe ghunt shodan metabigor
)

install_infogather() {
  log STEP "Installing Information Gathering Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${INFOGATHER_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# Category: Reporting
###############################################################################

readonly REPORTING_NAME="Reporting"
readonly REPORTING_DESC="Report generation and documentation tools"
readonly REPORTING_PACKAGES=(
  eyewitness cutycapt pipal cherrytree keepnote dradis
)

install_reporting() {
  log STEP "Installing Reporting Tools"
  local -a filtered
  read -ra filtered <<<"$(filter_arm64_packages "${REPORTING_PACKAGES[@]}")"
  install_packages "${filtered[@]}"
}

###############################################################################
# XFCE Desktop Environment
###############################################################################

xfce_is_installed() {
  command -v xfce4-session &>/dev/null && command -v startx &>/dev/null
}

xfce_install() {
  if xfce_is_installed; then
    log INFO "XFCE desktop is already installed"
    return 0
  fi

  log STEP "Installing XFCE Desktop Environment"

  local video_driver
  video_driver="$(board_xfce_video_driver)"

  log INFO "Installing X server and display manager..."
  install_packages_full \
    xorg xserver-xorg-core "$video_driver" \
    lightdm lightdm-gtk-greeter

  log INFO "Installing XFCE4 desktop..."
  install_packages_full \
    xfce4 xfce4-goodies xfce4-terminal \
    xfce4-power-manager xfce4-screensaver xfce4-notifyd

  log INFO "Installing Kali desktop theme..."
  local -a theme_pkgs=(kali-desktop-xfce kali-themes kali-menu)
  local -a available_theme=()
  for pkg in "${theme_pkgs[@]}"; do
    if pkg_available "$pkg"; then
      available_theme+=("$pkg")
    else
      log WARN "Theme package not available: $pkg"
    fi
  done
  if [[ ${#available_theme[@]} -gt 0 ]]; then
    install_packages_full "${available_theme[@]}"
  fi

  log INFO "Installing essential GUI utilities..."
  install_packages_full \
    dbus-x11 x11-xserver-utils xdg-utils mesa-utils \
    pulseaudio pavucontrol network-manager-gnome \
    thunar-archive-plugin file-roller mousepad firefox-esr

  log INFO "Enabling LightDM display manager..."
  if command -v systemctl &>/dev/null; then
    systemctl enable lightdm 2>/dev/null || true
    systemctl set-default graphical.target 2>/dev/null || true
  fi

  log INFO "XFCE desktop environment installed successfully"
}

xfce_configure_autologin() {
  local user="${1:-}"
  if [[ -z "$user" ]]; then
    user="$(logname 2>/dev/null || echo "${SUDO_USER:-root}")"
  fi

  if [[ "$user" == "root" ]]; then
    log WARN "Skipping autologin for root user"
    return 0
  fi

  local lightdm_conf="/etc/lightdm/lightdm.conf.d/90-autologin.conf"
  log INFO "Configuring autologin for user: $user"
  mkdir -p "$(dirname "$lightdm_conf")"
  cat >"$lightdm_conf" <<EOF
[Seat:*]
autologin-user=${user}
autologin-user-timeout=0
EOF

  log INFO "Autologin configured for $user"
}

###############################################################################
# Category registry
###############################################################################

declare -a CAT_TAGS=()
declare -a CAT_NAMES=()
declare -a CAT_DESCS=()
declare -a CAT_FUNCS=()

register_category() {
  local tag="$1" name="$2" desc="$3" func="$4"
  CAT_TAGS+=("$tag")
  CAT_NAMES+=("$name")
  CAT_DESCS+=("$desc")
  CAT_FUNCS+=("$func")
}

_register_all() {
  register_category "wireless" "$WIRELESS_NAME" "$WIRELESS_DESC" "install_wireless"
  register_category "web" "$WEB_NAME" "$WEB_DESC" "install_web"
  register_category "forensics" "$FORENSICS_NAME" "$FORENSICS_DESC" "install_forensics"
  register_category "exploitation" "$EXPLOITATION_NAME" "$EXPLOITATION_DESC" "install_exploitation"
  register_category "password" "$PASSWORD_NAME" "$PASSWORD_DESC" "install_password"
  register_category "sniffing" "$SNIFFING_NAME" "$SNIFFING_DESC" "install_sniffing"
  register_category "reverse" "$REVERSE_NAME" "$REVERSE_DESC" "install_reverse"
  register_category "infogather" "$INFOGATHER_NAME" "$INFOGATHER_DESC" "install_infogather"
  register_category "reporting" "$REPORTING_NAME" "$REPORTING_DESC" "install_reporting"
}

###############################################################################
# Menu actions
###############################################################################

action_setup_repo() {
  repo_setup
  echo ""
  read -r -p "Press Enter to return to menu..."
}

action_install_categories() {
  local -a checklist_items=()
  local i

  for ((i = 0; i < ${#CAT_TAGS[@]}; i++)); do
    checklist_items+=("${CAT_TAGS[$i]}" "${CAT_NAMES[$i]} — ${CAT_DESCS[$i]}" "OFF")
  done

  local selected
  selected="$(show_checklist \
    "Select Categories" \
    "Choose tool categories to install:" \
    "${checklist_items[@]}")" || return 0

  if [[ -z "$selected" ]]; then
    log WARN "No categories selected"
    return 0
  fi

  repo_setup

  local -a selected_tags
  read -ra selected_tags <<<"$selected"

  for tag in "${selected_tags[@]}"; do
    tag="${tag//\"/}"
    for ((i = 0; i < ${#CAT_TAGS[@]}; i++)); do
      if [[ "${CAT_TAGS[$i]}" == "$tag" ]]; then
        "${CAT_FUNCS[$i]}"
        break
      fi
    done
  done

  echo ""
  log INFO "Selected categories installed"
  read -r -p "Press Enter to return to menu..."
}

action_install_gui() {
  repo_setup
  xfce_install
  xfce_configure_autologin
  echo ""
  read -r -p "Press Enter to return to menu..."
}

action_install_all() {
  show_msgbox "Full Install" "This will install:\n\n• Kali repository\n• ALL tool categories\n• XFCE desktop environment\n\nThis may take a long time on limited storage."

  if ! confirm "Proceed with full installation?"; then
    return 0
  fi

  repo_setup
  system_update

  local i
  for ((i = 0; i < ${#CAT_FUNCS[@]}; i++)); do
    "${CAT_FUNCS[$i]}"
  done

  xfce_install
  xfce_configure_autologin
  board_post_install

  echo ""
  log INFO "Full installation complete!"
  log INFO "Reboot to start the XFCE desktop environment."
  read -r -p "Press Enter to return to menu..."
}

action_system_update() {
  if confirm "Update package lists and upgrade system?"; then
    system_update
    system_upgrade
    log INFO "System updated successfully"
  fi
  echo ""
  read -r -p "Press Enter to return to menu..."
}

action_system_info() {
  local info
  info="$(board_arch_info)"
  info+="\n\n"
  info+="$(repo_status)"

  local i
  for ((i = 0; i < ${#CAT_TAGS[@]}; i++)); do
    info+="\n${CYAN}●${NC} ${CAT_NAMES[$i]}: ${CAT_DESCS[$i]}"
  done

  show_msgbox "System Information" "$info"
}

###############################################################################
# Main menu
###############################################################################

main_menu() {
  local -a menu_items=(
    "1" "Setup Kali repository"
    "2" "Install tool categories"
    "3" "Install XFCE desktop (GUI)"
    "4" "Install ALL tools + GUI"
    "5" "System update & upgrade"
    "6" "System information"
    "7" "Exit"
  )

  local subtitle="Kali Linux Tools for ${BOARD_PLATFORM:-ARM64} (${BOARD_SOC:-unknown})"

  local choice
  while true; do
    choice="$(show_menu \
      "armkali Installer" \
      "${subtitle}\nSelect an option:" \
      "${menu_items[@]}")" || break

    case "$choice" in
    1) action_setup_repo ;;
    2) action_install_categories ;;
    3) action_install_gui ;;
    4) action_install_all ;;
    5) action_system_update ;;
    6) action_system_info ;;
    7) break ;;
    *) log ERROR "Invalid selection" ;;
    esac
  done
}
