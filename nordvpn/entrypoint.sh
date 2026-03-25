#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[meshnet] %s\n' "$*"
}

read_token() {
  if [[ -n "${NORDVPN_TOKEN:-}" ]]; then
    printf '%s' "${NORDVPN_TOKEN}"
    return 0
  fi

  if [[ -n "${NORDVPN_TOKEN_FILE:-}" && -f "${NORDVPN_TOKEN_FILE}" ]]; then
    tr -d '\r\n' < "${NORDVPN_TOKEN_FILE}"
    return 0
  fi

  return 1
}

wait_for_socket() {
  local retries=30

  until [[ -S /run/nordvpn/nordvpnd.sock ]]; do
    retries=$((retries - 1))
    if (( retries == 0 )); then
      log "NordVPN daemon socket did not appear in time."
      exit 1
    fi
    sleep 1
  done
}

is_logged_in() {
  nordvpn account >/dev/null 2>&1
}

run_allow_command() {
  local category="$1"
  local value="$2"

  if nordvpn allowlist add "${category}" "${value}" >/dev/null 2>&1; then
    return 0
  fi

  nordvpn whitelist add "${category}" "${value}" >/dev/null 2>&1
}

apply_csv_values() {
  local type="$1"
  local values="$2"
  local value

  IFS=',' read -ra items <<< "${values}"
  for value in "${items[@]}"; do
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    if [[ -n "${value}" ]]; then
      run_allow_command "${type}" "${value}" || log "Could not allow ${type} ${value}."
    fi
  done
}

ensure_login() {
  local token

  if is_logged_in; then
    log "NordVPN account already available in the persisted state."
    return 0
  fi

  if ! token="$(read_token)"; then
    log "No NordVPN token found. Add one to ./secrets/nordvpn_token or set NORDVPN_TOKEN."
    exit 1
  fi

  log "Logging in with the provided access token."
  nordvpn login --token "${token}"
}

configure_client() {
  if [[ -n "${NORDVPN_TECHNOLOGY:-}" ]]; then
    nordvpn set technology "${NORDVPN_TECHNOLOGY}" >/dev/null
  fi

  if [[ -n "${NORDVPN_LAN_DISCOVERY:-}" ]]; then
    nordvpn set lan-discovery "${NORDVPN_LAN_DISCOVERY}" >/dev/null
  fi

  if [[ -n "${NORDVPN_MESHNET:-}" ]]; then
    nordvpn set meshnet "${NORDVPN_MESHNET}" >/dev/null
  fi

  if [[ -n "${NORDVPN_EXTRA_SUBNETS:-}" ]]; then
    apply_csv_values subnet "${NORDVPN_EXTRA_SUBNETS}"
  fi

  if [[ -n "${NORDVPN_EXTRA_PORTS:-}" ]]; then
    apply_csv_values port "${NORDVPN_EXTRA_PORTS}"
  fi

  if [[ -n "${NORDVPN_CONNECT:-}" ]]; then
    log "Connecting to NordVPN target '${NORDVPN_CONNECT}'."
    nordvpn connect "${NORDVPN_CONNECT}"
  fi
}

monitor_daemon() {
  while sleep 30; do
    if ! pgrep -x nordvpnd >/dev/null 2>&1; then
      log "NordVPN daemon stopped."
      exit 1
    fi
  done
}

log "Starting NordVPN daemon."
/etc/init.d/nordvpn start >/dev/null
wait_for_socket
ensure_login
configure_client

log "Meshnet node is ready."
nordvpn account || true
nordvpn settings || true
nordvpn meshnet peer list || true

monitor_daemon
