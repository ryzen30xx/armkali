#!/usr/bin/env bash
# whiptail/dialog-based UI helpers

_has_whiptail() {
  command -v whiptail &>/dev/null
}

_has_dialog() {
  command -v dialog &>/dev/null
}

_ui_cmd() {
  if _has_whiptail; then
    echo "whiptail"
  elif _has_dialog; then
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

show_gauge() {
  local title="$1"
  local text="$2"
  local percent="$3"
  local cmd
  cmd="$(_ui_cmd)"

  if [[ -z "$cmd" ]]; then
    echo -e "${CYAN}[${title}]${NC} ${text} (${percent}%)"
    return
  fi

  echo "$percent" | $cmd --title "$title" --gauge "$text" 8 60 0 3>&1 1>&2 2>&3
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
