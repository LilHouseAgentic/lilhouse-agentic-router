#!/usr/bin/env bash
set -euo pipefail

DESTDIR=""
ENABLE_SYSTEMD=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    --destdir)
      DESTDIR="${2:-}"
      if [ -z "$DESTDIR" ]; then
        echo "Missing value for --destdir"
        exit 1
      fi
      shift 2
      ;;
    --no-systemd)
      ENABLE_SYSTEMD=0
      shift
      ;;
    -h|--help)
      echo "Usage: sudo ./install.sh [--destdir PATH] [--no-systemd]"
      echo
      echo "  --destdir PATH   Install into a fake root for testing."
      echo "  --no-systemd     Copy files but do not enable/start systemd timer."
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [ -z "$DESTDIR" ] && [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Please run as root: sudo ./install.sh"
  echo "For safe test install, use: ./install.sh --destdir /tmp/lilhouse-install-test"
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

root_path() {
  local path="$1"
  if [ -n "$DESTDIR" ]; then
    printf '%s%s\n' "$DESTDIR" "$path"
  else
    printf '%s\n' "$path"
  fi
}

backup_existing() {
  local target="$1"
  if [ -n "$DESTDIR" ]; then
    return 0
  fi
  if [ -e "$target" ] && [ ! -e "$target.bak.lilhouse-agentic.$STAMP" ]; then
    cp -a "$target" "$target.bak.lilhouse-agentic.$STAMP"
  fi
}

echo "Installing LilHouse Agentic Router observe-only core..."

if [ -n "$DESTDIR" ]; then
  echo "DESTDIR test install: $DESTDIR"
  ENABLE_SYSTEMD=0
fi

install -d -m 0755 "$(root_path /etc/lilhouse)"
install -d -m 0755 "$(root_path /usr/lib/lilhouse)"
install -d -m 0755 "$(root_path /usr/local/bin)"
install -d -m 0755 "$(root_path /var/lib/lilhouse)"
install -d -m 0755 "$(root_path /var/log/lilhouse)"
install -d -m 0755 "$(root_path /run/lilhouse)"
install -d -m 0755 "$(root_path /etc/systemd/system)"

ENV_FILE="$(root_path /etc/lilhouse/lilhouse.env)"
if [ ! -f "$ENV_FILE" ]; then
  printf "%s\n" \
    "# LilHouse Agentic Router environment" \
    "# Safe observe-only defaults." \
    "" \
    "LILHOUSE_STATE_DIR=/var/lib/lilhouse" \
    "LILHOUSE_RUNTIME_DIR=/run/lilhouse" \
    "LILHOUSE_LOG_DIR=/var/log/lilhouse" \
    "LILHOUSE_WAN_IF=eth0" \
    "LILHOUSE_LAN_IF=eth1" > "$ENV_FILE"
  chmod 0644 "$ENV_FILE"
fi

backup_existing /usr/lib/lilhouse/lilhouse-common.sh
backup_existing /usr/local/bin/lilhouse-event
backup_existing /usr/local/bin/lilhouse-action
backup_existing /usr/local/bin/lilhouse-current-state
backup_existing /usr/local/bin/lilhouse-storage-health
backup_existing /usr/local/bin/lilhouse-status
backup_existing /etc/systemd/system/lilhouse-current-state.service
backup_existing /etc/systemd/system/lilhouse-current-state.timer
backup_existing /etc/systemd/system/lilhouse-status.service

install -m 0755 "$REPO_DIR/lib/lilhouse-common.sh" "$(root_path /usr/lib/lilhouse/lilhouse-common.sh)"
install -m 0755 "$REPO_DIR/bin/lilhouse-event" "$(root_path /usr/local/bin/lilhouse-event)"
install -m 0755 "$REPO_DIR/bin/lilhouse-action" "$(root_path /usr/local/bin/lilhouse-action)"
install -m 0755 "$REPO_DIR/bin/lilhouse-current-state" "$(root_path /usr/local/bin/lilhouse-current-state)"
install -m 0755 "$REPO_DIR/bin/lilhouse-storage-health" "$(root_path /usr/local/bin/lilhouse-storage-health)"
install -m 0755 "$REPO_DIR/bin/lilhouse-status" "$(root_path /usr/local/bin/lilhouse-status)"

install -m 0644 "$REPO_DIR/systemd/lilhouse-current-state.service" "$(root_path /etc/systemd/system/lilhouse-current-state.service)"
install -m 0644 "$REPO_DIR/systemd/lilhouse-current-state.timer" "$(root_path /etc/systemd/system/lilhouse-current-state.timer)"
install -m 0644 "$REPO_DIR/systemd/lilhouse-status.service" "$(root_path /etc/systemd/system/lilhouse-status.service)"

if [ "$ENABLE_SYSTEMD" -eq 1 ]; then
  systemctl daemon-reload
  systemctl enable --now lilhouse-current-state.timer
else
  echo "Systemd enable/start skipped."
fi

echo
echo "Install complete."
echo
echo "Try:"
echo "  lilhouse-current-state"
echo "  lilhouse-status"
echo "  systemctl status lilhouse-current-state.timer --no-pager"
