#!/usr/bin/env bash
#
# armkali — Kali Linux tools installer for x96q (Allwinner H313) on Armbian
#
# Usage: sudo ./install.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/ui.sh
source "${SCRIPT_DIR}/lib/ui.sh"
# shellcheck source=lib/repo.sh
source "${SCRIPT_DIR}/lib/repo.sh"
# shellcheck source=lib/arm64.sh
source "${SCRIPT_DIR}/lib/arm64.sh"

# Source all category modules
for f in "${SCRIPT_DIR}"/categories/*.sh; do
  # shellcheck disable=SC1090
  source "$f"
done

# Category registry: tag, name, install function
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

  local choice
  while true; do
    choice="$(show_menu \
      "armkali Installer" \
      "Kali Linux Tools for x96q (Allwinner H313)\nSelect an option:" \
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
  bash "${SCRIPT_DIR}/xfce-setup.sh"
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

  bash "${SCRIPT_DIR}/xfce-setup.sh"

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
  info="$(arch_info)"
  info+="\n\n"
  info+="$(repo_status)"

  local i
  for ((i = 0; i < ${#CAT_TAGS[@]}; i++)); do
    info+="\n${CYAN}●${NC} ${CAT_NAMES[$i]}: ${CAT_DESCS[$i]}"
  done

  show_msgbox "System Information" "$info"
}

# Entry point
check_root
_register_all
ensure_ui
banner
main_menu
