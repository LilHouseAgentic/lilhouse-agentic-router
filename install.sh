#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Please run as root: sudo ./install.sh"
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

backup_existing() {
  local target="$1"
  if [ -e "$target" ] && [ ! -e "$target.bak.lilhouse-agentic.$STAMP" ]; then
    cp -a "$target" "$target.bak.lilhouse-agentic.$STAMP"
  fi
}

echo "Installing LilHouse Agentic Router observe-only core..."

install -d -m 0755 /etc/lilhouse
install -d -m 0755 /usr/lib/lilhouse
install -d -m 0755 /usr/local/bin
install -d -m 0755 /var/lib/lilhouse
install -d -m 0755 /var/log/lilhouse
install -d -m 0755 /run/lilhouse

if [ ! -f /etc/lilhouse/lilhouse.env ]; then
  printf "%s\n" \
    "# LilHouse Agentic Router environment" \
    "# Safe observe-only defaults." \
    "" \
    "LILHOUSE_STATE_DIR=/var/lib/lilhouse" \
    "LILHOUSE_RUNTIME_DIR=/run/lilhouse" \
    "LILHOUSE_LOG_DIR=/var/log/lilhouse" \
    "LILHOUSE_WAN_IF=eth0" \
    "LILHOUSE_LAN_IF=eth1" > /etc/lilhouse/lilhouse.env
  chmod 0644 /etc/lilhouse/lilhouse.env
fi

backup_existing /usr/lib/lilhouse/lilhouse-common.sh
backup_existing /usr/local/bin/lilhouse-event
backup_existing /usr/local/bin/lilhouse-action
backup_existing /usr/local/bin/lilhouse-current-state
backup_existing /usr/local/bin/lilhouse-status
backup_existing /etc/systemd/system/lilhouse-current-state.service
backup_existing /etc/systemd/system/lilhouse-current-state.timer
backup_existing /etc/systemd/system/lilhouse-status.service

install -m 0755 "$REPO_DIR/lib/lilhouse-common.sh" /usr/lib/lilhouse/lilhouse-common.sh
install -m 0755 "$REPO_DIR/bin/lilhouse-event" /usr/local/bin/lilhouse-event
install -m 0755 "$REPO_DIR/bin/lilhouse-action" /usr/local/bin/lilhouse-action
install -m 0755 "$REPO_DIR/bin/lilhouse-current-state" /usr/local/bin/lilhouse-current-state
install -m 0755 "$REPO_DIR/bin/lilhouse-status" /usr/local/bin/lilhouse-status

install -m 0644 "$REPO_DIR/systemd/lilhouse-current-state.service" /etc/systemd/system/lilhouse-current-state.service
install -m 0644 "$REPO_DIR/systemd/lilhouse-current-state.timer" /etc/systemd/system/lilhouse-current-state.timer
install -m 0644 "$REPO_DIR/systemd/lilhouse-status.service" /etc/systemd/system/lilhouse-status.service

systemctl daemon-reload
systemctl enable --now lilhouse-current-state.timer

echo
echo "Install complete."
echo
echo "Try:"
echo "  lilhouse-current-state"
echo "  lilhouse-status"
echo "  systemctl status lilhouse-current-state.timer --no-pager"
