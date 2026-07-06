#!/usr/bin/env bash
# Kali Linux repository management for ARM64/Armbian

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
  local keyring_dir
  keyring_dir="$(dirname "$KALI_KEYRING_PATH")"
  mkdir -p "$keyring_dir"

  curl -fsSL "$KALI_KEYRING_URL" -o "$KALI_KEYRING_PATH"

  log INFO "Adding Kali repository..."
  cat >"$KALI_SOURCES_LIST" <<EOF
deb [signed-by=${KALI_KEYRING_PATH}] http://http.kali.org/kali kali-rolling main contrib non-free
EOF

  log INFO "Updating package lists..."
  apt-get update 2>&1 | tee -a "$LOG_FILE"

  log INFO "Kali repository configured successfully"
}

repo_remove() {
  if [[ -f "$KALI_SOURCES_LIST" ]]; then
    log STEP "Removing Kali repository"
    rm -f "$KALI_SOURCES_LIST"
    rm -f "$KALI_KEYRING_PATH"
    apt-get update 2>&1 | tee -a "$LOG_FILE"
    log INFO "Kali repository removed"
  fi
}

repo_status() {
  if repo_is_configured; then
    echo -e "${GREEN}●${NC} Kali repository: configured"
  else
    echo -e "${RED}●${NC} Kali repository: not configured"
  fi
}
