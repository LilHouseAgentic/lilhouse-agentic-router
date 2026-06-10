#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DESTDIR=""
ENABLE_SYSTEMD=1
MODE="observe-only"
WIZARD=0
DRY_RUN=0
ROUTER_WIZARD_OUT_DIR=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      if [ -z "$MODE" ]; then
        echo "Missing value for --mode"
        exit 1
      fi
      case "$MODE" in
        observe-only|router-deploy) ;;
        *)
          echo "Unknown mode: $MODE"
          echo "Supported modes: observe-only, router-deploy"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --wizard)
      WIZARD=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --destdir)
      DESTDIR="${2:-}"
      if [ -z "$DESTDIR" ]; then
        echo "Missing value for --destdir"
        exit 1
      fi
      shift 2
      ;;
    --out-dir)
      ROUTER_WIZARD_OUT_DIR="${2:-}"
      if [ -z "$ROUTER_WIZARD_OUT_DIR" ]; then
        echo "Missing value for --out-dir"
        exit 1
      fi
      shift 2
      ;;
    --no-systemd)
      ENABLE_SYSTEMD=0
      shift
      ;;
    -h|--help)
      echo "Usage: sudo ./install.sh [--mode observe-only|router-deploy] [--wizard] [--dry-run] [--destdir PATH] [--no-systemd]"
      echo
      echo "  --mode MODE      Deployment mode: observe-only or router-deploy."
      echo "  --wizard         Future router deployment wizard flag."
      echo "  --dry-run        Show intent without applying router-deploy changes."
      echo "  --out-dir PATH   Output directory for router-deploy dry-run wizard plans."
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

if [ "$MODE" = "router-deploy" ]; then
  if [ "$WIZARD" -eq 1 ] && [ "$DRY_RUN" -eq 1 ]; then
    OUT="${ROUTER_WIZARD_OUT_DIR:-${LILHOUSE_STATE_DIR:-./state}/router-wizard-dry-run}"
    echo "Router-deploy dry-run wizard requested."
    echo
    echo "No system changes will be made."
    echo
    "$REPO_DIR/bin/lilhouse-router-wizard" --out-dir "$OUT"
    exit $?
  fi

  echo "Router-deploy apply mode is planned but not implemented yet."
  echo
  echo "This future mode will configure WAN/LAN, forwarding, firewall/NAT, DHCP, Pi-hole, Unbound, CAKE/SQM, and worker timers."
  echo "For now, use the dry-run wizard:"
  echo
  echo "  ./install.sh --mode router-deploy --wizard --dry-run"
  echo
  echo "No changes made."
  exit 2
fi

if [ "$WIZARD" -eq 1 ]; then
  echo "--wizard is only supported with router-deploy dry-run for now."
  echo
  echo "Try:"
  echo "  ./install.sh --mode router-deploy --wizard --dry-run"
  echo
  echo "No changes made."
  exit 2
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry-run requested."
  echo "Observe-only mode currently supports safe fake-root testing with:"
  echo
  echo "  ./install.sh --destdir /tmp/lilhouse-install-test"
  echo
  echo "No changes made."
  exit 0
fi

if [ -z "$DESTDIR" ] && [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Please run as root: sudo ./install.sh"
  echo "For safe test install, use: ./install.sh --destdir /tmp/lilhouse-install-test"
  exit 1
fi

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
echo "Mode: $MODE"

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
backup_existing /usr/local/bin/lilhouse-interface-report
backup_existing /usr/local/bin/lilhouse-router-plan
backup_existing /usr/local/bin/lilhouse-router-plan-summary
backup_existing /usr/local/bin/lilhouse-router-wizard
backup_existing /usr/local/bin/lilhouse-router-preview-validate
backup_existing /usr/local/bin/lilhouse-router-backup-plan
backup_existing /usr/local/bin/lilhouse-router-backup-dry-run
backup_existing /usr/local/bin/lilhouse-router-backup-create
backup_existing /usr/local/bin/lilhouse-status
backup_existing /etc/systemd/system/lilhouse-current-state.service
backup_existing /etc/systemd/system/lilhouse-current-state.timer
backup_existing /etc/systemd/system/lilhouse-storage-health.service
backup_existing /etc/systemd/system/lilhouse-storage-health.timer
backup_existing /etc/systemd/system/lilhouse-status.service

install -m 0755 "$REPO_DIR/lib/lilhouse-common.sh" "$(root_path /usr/lib/lilhouse/lilhouse-common.sh)"
install -m 0755 "$REPO_DIR/bin/lilhouse-event" "$(root_path /usr/local/bin/lilhouse-event)"
install -m 0755 "$REPO_DIR/bin/lilhouse-action" "$(root_path /usr/local/bin/lilhouse-action)"
install -m 0755 "$REPO_DIR/bin/lilhouse-current-state" "$(root_path /usr/local/bin/lilhouse-current-state)"
install -m 0755 "$REPO_DIR/bin/lilhouse-storage-health" "$(root_path /usr/local/bin/lilhouse-storage-health)"
install -m 0755 "$REPO_DIR/bin/lilhouse-interface-report" "$(root_path /usr/local/bin/lilhouse-interface-report)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-plan" "$(root_path /usr/local/bin/lilhouse-router-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-plan-summary" "$(root_path /usr/local/bin/lilhouse-router-plan-summary)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-wizard" "$(root_path /usr/local/bin/lilhouse-router-wizard)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-preview-validate" "$(root_path /usr/local/bin/lilhouse-router-preview-validate)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-backup-plan" "$(root_path /usr/local/bin/lilhouse-router-backup-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-backup-dry-run" "$(root_path /usr/local/bin/lilhouse-router-backup-dry-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-backup-create" "$(root_path /usr/local/bin/lilhouse-router-backup-create)"
install -m 0755 "$REPO_DIR/bin/lilhouse-status" "$(root_path /usr/local/bin/lilhouse-status)"

install -m 0644 "$REPO_DIR/systemd/lilhouse-current-state.service" "$(root_path /etc/systemd/system/lilhouse-current-state.service)"
install -m 0644 "$REPO_DIR/systemd/lilhouse-current-state.timer" "$(root_path /etc/systemd/system/lilhouse-current-state.timer)"
install -m 0644 "$REPO_DIR/systemd/lilhouse-storage-health.service" "$(root_path /etc/systemd/system/lilhouse-storage-health.service)"
install -m 0644 "$REPO_DIR/systemd/lilhouse-storage-health.timer" "$(root_path /etc/systemd/system/lilhouse-storage-health.timer)"
install -m 0644 "$REPO_DIR/systemd/lilhouse-status.service" "$(root_path /etc/systemd/system/lilhouse-status.service)"

if [ "$ENABLE_SYSTEMD" -eq 1 ]; then
  systemctl daemon-reload
  systemctl enable --now lilhouse-current-state.timer
  systemctl enable --now lilhouse-storage-health.timer
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
echo "  systemctl status lilhouse-storage-health.timer --no-pager"
