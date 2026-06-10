#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Please run as root: sudo ./uninstall.sh"
  exit 1
fi

echo "Uninstalling LilHouse Agentic Router observe-only core..."

systemctl disable --now lilhouse-current-state.timer 2>/dev/null || true
systemctl disable --now lilhouse-storage-health.timer 2>/dev/null || true
systemctl stop lilhouse-current-state.service 2>/dev/null || true
systemctl stop lilhouse-storage-health.service 2>/dev/null || true

rm -f /etc/systemd/system/lilhouse-current-state.service
rm -f /etc/systemd/system/lilhouse-current-state.timer
rm -f /etc/systemd/system/lilhouse-storage-health.service
rm -f /etc/systemd/system/lilhouse-storage-health.timer
rm -f /etc/systemd/system/lilhouse-status.service

rm -f /usr/local/bin/lilhouse-event
rm -f /usr/local/bin/lilhouse-action
rm -f /usr/local/bin/lilhouse-current-state
rm -f /usr/local/bin/lilhouse-storage-health
rm -f /usr/local/bin/lilhouse-interface-report
rm -f /usr/local/bin/lilhouse-router-plan
rm -f /usr/local/bin/lilhouse-router-plan-summary
rm -f /usr/local/bin/lilhouse-status
rm -f /usr/lib/lilhouse/lilhouse-common.sh

systemctl daemon-reload

echo
echo "Uninstall complete."
echo "Kept /etc/lilhouse, /var/lib/lilhouse, and /var/log/lilhouse for safety."
