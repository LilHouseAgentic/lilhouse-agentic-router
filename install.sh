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

    if [ -n "${ROUTER_WIZARD_WAN:-}" ] || [ -n "${ROUTER_WIZARD_LAN:-}" ]; then
      if [ -z "${ROUTER_WIZARD_WAN:-}" ] || [ -z "${ROUTER_WIZARD_LAN:-}" ]; then
        echo "Both ROUTER_WIZARD_WAN and ROUTER_WIZARD_LAN must be set when using interface overrides."
        exit 2
      fi

      echo "Preview interfaces: WAN=$ROUTER_WIZARD_WAN LAN=$ROUTER_WIZARD_LAN"
      echo
      "$REPO_DIR/bin/lilhouse-router-wizard" --out-dir "$OUT" --wan "$ROUTER_WIZARD_WAN" --lan "$ROUTER_WIZARD_LAN"
      exit $?
    fi

    while true; do
      set +e
      "$REPO_DIR/bin/lilhouse-router-wizard" --out-dir "$OUT"
      WIZARD_RC=$?
      set -e

      if [ "$WIZARD_RC" -eq 0 ]; then
        exit 0
      fi

      echo
      echo "Router wizard could not detect both WAN and LAN interfaces."
      echo
      echo "Please attach another network adapter, then press Enter to check again."
      echo "Type q and press Enter to quit."
      echo

      if [ ! -t 0 ]; then
        echo "No interactive terminal available; cannot wait for NIC retry."
        exit "$WIZARD_RC"
      fi

      printf "Continue after adding NIC? [Enter/q]: "
      read -r ANSWER

      case "$ANSWER" in
        q|Q|quit|QUIT)
          echo "Router-deploy dry-run wizard cancelled."
          exit "$WIZARD_RC"
          ;;
      esac

      echo
      echo "Rechecking interfaces..."
      echo
    done
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
backup_existing /usr/local/bin/lilhouse-storage-status
backup_existing /usr/local/bin/lilhouse-storage-clean
backup_existing /usr/local/bin/lilhouse-storage-index
backup_existing /usr/local/bin/lilhouse-storage-archive
backup_existing /usr/local/bin/lilhouse-storage-ledger-checkpoint
backup_existing /usr/local/bin/lilhouse-storage-query
backup_existing /usr/local/bin/lilhouse-interface-report
backup_existing /usr/local/bin/lilhouse-router-plan
backup_existing /usr/local/bin/lilhouse-router-plan-summary
backup_existing /usr/local/bin/lilhouse-router-wizard
backup_existing /usr/local/bin/lilhouse-router-preview-validate
backup_existing /usr/local/bin/lilhouse-router-backup-plan
backup_existing /usr/local/bin/lilhouse-router-backup-dry-run
backup_existing /usr/local/bin/lilhouse-router-backup-create
backup_existing /usr/local/bin/lilhouse-router-backup-verify
backup_existing /usr/local/bin/lilhouse-router-restore-dry-run
backup_existing /usr/local/bin/lilhouse-router-restore-create
backup_existing /usr/local/bin/lilhouse-router-safety-loop
backup_existing /usr/local/bin/lilhouse-router-stage-preview
backup_existing /usr/local/bin/lilhouse-router-stage-validate
backup_existing /usr/local/bin/lilhouse-router-deploy-preflight
backup_existing /usr/local/bin/lilhouse-router-apply-plan
backup_existing /usr/local/bin/lilhouse-router-apply-dry-run
backup_existing /usr/local/bin/lilhouse-router-apply-create
backup_existing /usr/local/bin/lilhouse-router-apply-validate
backup_existing /usr/local/bin/lilhouse-router-full-dress-rehearsal
backup_existing /usr/local/bin/lilhouse-router-live-readiness
backup_existing /usr/local/bin/lilhouse-router-timed-rollback-plan
backup_existing /usr/local/bin/lilhouse-router-timed-rollback-create
backup_existing /usr/local/bin/lilhouse-router-timed-rollback-validate
backup_existing /usr/local/bin/lilhouse-router-timed-rollback-rehearsal
backup_existing /usr/local/bin/lilhouse-router-live-confirmation-plan
backup_existing /usr/local/bin/lilhouse-router-live-confirmation-check
backup_existing /usr/local/bin/lilhouse-router-post-apply-health-plan
backup_existing /usr/local/bin/lilhouse-router-post-apply-health-dry-run
backup_existing /usr/local/bin/lilhouse-router-post-apply-health-rehearsal
backup_existing /usr/local/bin/lilhouse-router-service-activation-plan
backup_existing /usr/local/bin/lilhouse-router-service-activation-dry-run
backup_existing /usr/local/bin/lilhouse-router-service-activation-rehearsal
backup_existing /usr/local/bin/lilhouse-router-live-readiness-review
backup_existing /usr/local/bin/lilhouse-router-health-probe-plan
backup_existing /usr/local/bin/lilhouse-router-health-probe-dry-run
backup_existing /usr/local/bin/lilhouse-router-health-probe-rehearsal
backup_existing /usr/local/bin/lilhouse-router-health-probe-run
backup_existing /usr/local/bin/lilhouse-router-live-preflight
backup_existing /usr/local/bin/lilhouse-router-live-backup
backup_existing /usr/local/bin/lilhouse-router-rollback-guard
backup_existing /usr/local/bin/lilhouse-router-rollback-start
backup_existing /usr/local/bin/lilhouse-router-live-config-copy
backup_existing /usr/local/bin/lilhouse-router-service-activation
backup_existing /usr/local/bin/lilhouse-router-post-apply-health-run
backup_existing /usr/local/bin/lilhouse-router-rollback-cancel
backup_existing /usr/local/bin/lilhouse-router-live-apply-executor-plan
backup_existing /usr/local/bin/lilhouse-router-final-deploy-runbook
backup_existing /usr/local/bin/lilhouse-router-release-candidate
backup_existing /usr/local/bin/lilhouse-router-release-candidate-summary
backup_existing /usr/local/bin/lilhouse-status
backup_existing /usr/local/bin/lilhouse-cake-set
backup_existing /usr/local/bin/lilhouse-router-status
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
install -m 0755 "$REPO_DIR/bin/lilhouse-storage-status" "$(root_path /usr/local/bin/lilhouse-storage-status)"
install -m 0755 "$REPO_DIR/bin/lilhouse-storage-clean" "$(root_path /usr/local/bin/lilhouse-storage-clean)"
install -m 0755 "$REPO_DIR/bin/lilhouse-storage-index" "$(root_path /usr/local/bin/lilhouse-storage-index)"
install -m 0755 "$REPO_DIR/bin/lilhouse-storage-archive" "$(root_path /usr/local/bin/lilhouse-storage-archive)"
install -m 0755 "$REPO_DIR/bin/lilhouse-storage-ledger-checkpoint" "$(root_path /usr/local/bin/lilhouse-storage-ledger-checkpoint)"
install -m 0755 "$REPO_DIR/bin/lilhouse-storage-query" "$(root_path /usr/local/bin/lilhouse-storage-query)"
install -m 0755 "$REPO_DIR/bin/lilhouse-interface-report" "$(root_path /usr/local/bin/lilhouse-interface-report)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-plan" "$(root_path /usr/local/bin/lilhouse-router-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-plan-summary" "$(root_path /usr/local/bin/lilhouse-router-plan-summary)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-wizard" "$(root_path /usr/local/bin/lilhouse-router-wizard)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-preview-validate" "$(root_path /usr/local/bin/lilhouse-router-preview-validate)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-backup-plan" "$(root_path /usr/local/bin/lilhouse-router-backup-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-backup-dry-run" "$(root_path /usr/local/bin/lilhouse-router-backup-dry-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-backup-create" "$(root_path /usr/local/bin/lilhouse-router-backup-create)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-backup-verify" "$(root_path /usr/local/bin/lilhouse-router-backup-verify)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-restore-dry-run" "$(root_path /usr/local/bin/lilhouse-router-restore-dry-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-restore-create" "$(root_path /usr/local/bin/lilhouse-router-restore-create)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-safety-loop" "$(root_path /usr/local/bin/lilhouse-router-safety-loop)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-stage-preview" "$(root_path /usr/local/bin/lilhouse-router-stage-preview)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-stage-validate" "$(root_path /usr/local/bin/lilhouse-router-stage-validate)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-deploy-preflight" "$(root_path /usr/local/bin/lilhouse-router-deploy-preflight)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-apply-plan" "$(root_path /usr/local/bin/lilhouse-router-apply-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-apply-dry-run" "$(root_path /usr/local/bin/lilhouse-router-apply-dry-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-apply-create" "$(root_path /usr/local/bin/lilhouse-router-apply-create)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-apply-validate" "$(root_path /usr/local/bin/lilhouse-router-apply-validate)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-full-dress-rehearsal" "$(root_path /usr/local/bin/lilhouse-router-full-dress-rehearsal)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-live-readiness" "$(root_path /usr/local/bin/lilhouse-router-live-readiness)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-timed-rollback-plan" "$(root_path /usr/local/bin/lilhouse-router-timed-rollback-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-timed-rollback-create" "$(root_path /usr/local/bin/lilhouse-router-timed-rollback-create)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-timed-rollback-validate" "$(root_path /usr/local/bin/lilhouse-router-timed-rollback-validate)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-timed-rollback-rehearsal" "$(root_path /usr/local/bin/lilhouse-router-timed-rollback-rehearsal)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-live-confirmation-plan" "$(root_path /usr/local/bin/lilhouse-router-live-confirmation-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-live-confirmation-check" "$(root_path /usr/local/bin/lilhouse-router-live-confirmation-check)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-post-apply-health-plan" "$(root_path /usr/local/bin/lilhouse-router-post-apply-health-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-post-apply-health-dry-run" "$(root_path /usr/local/bin/lilhouse-router-post-apply-health-dry-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-post-apply-health-rehearsal" "$(root_path /usr/local/bin/lilhouse-router-post-apply-health-rehearsal)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-service-activation-plan" "$(root_path /usr/local/bin/lilhouse-router-service-activation-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-service-activation-dry-run" "$(root_path /usr/local/bin/lilhouse-router-service-activation-dry-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-service-activation-rehearsal" "$(root_path /usr/local/bin/lilhouse-router-service-activation-rehearsal)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-live-readiness-review" "$(root_path /usr/local/bin/lilhouse-router-live-readiness-review)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-health-probe-plan" "$(root_path /usr/local/bin/lilhouse-router-health-probe-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-health-probe-dry-run" "$(root_path /usr/local/bin/lilhouse-router-health-probe-dry-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-health-probe-rehearsal" "$(root_path /usr/local/bin/lilhouse-router-health-probe-rehearsal)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-health-probe-run" "$(root_path /usr/local/bin/lilhouse-router-health-probe-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-live-preflight" "$(root_path /usr/local/bin/lilhouse-router-live-preflight)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-live-backup" "$(root_path /usr/local/bin/lilhouse-router-live-backup)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-rollback-guard" "$(root_path /usr/local/bin/lilhouse-router-rollback-guard)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-rollback-start" "$(root_path /usr/local/bin/lilhouse-router-rollback-start)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-live-config-copy" "$(root_path /usr/local/bin/lilhouse-router-live-config-copy)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-service-activation" "$(root_path /usr/local/bin/lilhouse-router-service-activation)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-post-apply-health-run" "$(root_path /usr/local/bin/lilhouse-router-post-apply-health-run)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-rollback-cancel" "$(root_path /usr/local/bin/lilhouse-router-rollback-cancel)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-live-apply-executor-plan" "$(root_path /usr/local/bin/lilhouse-router-live-apply-executor-plan)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-final-deploy-runbook" "$(root_path /usr/local/bin/lilhouse-router-final-deploy-runbook)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-release-candidate" "$(root_path /usr/local/bin/lilhouse-router-release-candidate)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-release-candidate-summary" "$(root_path /usr/local/bin/lilhouse-router-release-candidate-summary)"
install -m 0755 "$REPO_DIR/bin/lilhouse-status" "$(root_path /usr/local/bin/lilhouse-status)"
install -m 0755 "$REPO_DIR/bin/lilhouse-cake-set" "$(root_path /usr/local/bin/lilhouse-cake-set)"
install -m 0755 "$REPO_DIR/bin/lilhouse-router-status" "$(root_path /usr/local/bin/lilhouse-router-status)"

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
echo "  lilhouse-storage-status"
echo "  sudo lilhouse-storage-clean --dry-run"
echo "  sudo lilhouse-storage-index --dry-run"
echo "  sudo lilhouse-storage-archive --dry-run"
echo "  sudo lilhouse-storage-ledger-checkpoint --dry-run"
echo "  sudo lilhouse-storage-query --list"
echo "  lilhouse-router-status"
echo "  sudo lilhouse-cake-set --down 250 --up 35"
echo "  systemctl status lilhouse-current-state.timer --no-pager"
echo "  systemctl status lilhouse-storage-health.timer --no-pager"
