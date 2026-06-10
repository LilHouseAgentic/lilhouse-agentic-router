#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/lilhouse-smoke-test-root"
TMP_STATE="${TMPDIR:-/tmp}/lilhouse-smoke-test-state"
TMP_RUN="${TMPDIR:-/tmp}/lilhouse-smoke-test-run"
TMP_LOG="${TMPDIR:-/tmp}/lilhouse-smoke-test-log"

rm -rf "$TMP_ROOT" "$TMP_STATE" "$TMP_RUN" "$TMP_LOG"

echo "== install into fake root =="
"$REPO_DIR/install.sh" --destdir "$TMP_ROOT"

echo
echo "== verify installed files =="
test -x "$TMP_ROOT/usr/local/bin/lilhouse-event"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-action"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-current-state"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-storage-health"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-interface-report"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-plan-summary"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-wizard"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-preview-validate"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-backup-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-backup-dry-run"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-backup-create"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-backup-verify"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-restore-dry-run"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-restore-create"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-safety-loop"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-stage-preview"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-stage-validate"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-deploy-preflight"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-apply-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-apply-dry-run"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-apply-create"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-apply-validate"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-full-dress-rehearsal"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-live-readiness"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-timed-rollback-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-timed-rollback-create"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-timed-rollback-validate"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-timed-rollback-rehearsal"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-live-confirmation-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-live-confirmation-check"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-post-apply-health-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-post-apply-health-dry-run"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-post-apply-health-rehearsal"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-service-activation-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-service-activation-dry-run"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-service-activation-rehearsal"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-live-readiness-review"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-health-probe-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-health-probe-dry-run"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-health-probe-rehearsal"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-live-apply-executor-plan"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-final-deploy-runbook"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-release-candidate"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-release-candidate-summary"
test -x "$TMP_ROOT/usr/local/bin/lilhouse-status"
test -x "$TMP_ROOT/usr/lib/lilhouse/lilhouse-common.sh"
test -f "$TMP_ROOT/etc/lilhouse/lilhouse.env"
test -f "$TMP_ROOT/etc/systemd/system/lilhouse-current-state.service"
test -f "$TMP_ROOT/etc/systemd/system/lilhouse-current-state.timer"
test -f "$TMP_ROOT/etc/systemd/system/lilhouse-storage-health.service"
test -f "$TMP_ROOT/etc/systemd/system/lilhouse-storage-health.timer"
test -f "$TMP_ROOT/etc/systemd/system/lilhouse-status.service"

echo
echo "== run repo scripts with temporary state =="
LILHOUSE_STATE_DIR="$TMP_STATE" \
LILHOUSE_RUNTIME_DIR="$TMP_RUN" \
LILHOUSE_LOG_DIR="$TMP_LOG" \
LILHOUSE_CURRENT_STATE_FILE="$TMP_STATE/current-state.json" \
"$REPO_DIR/bin/lilhouse-event" test info "smoke test event" smoke-test

LILHOUSE_STATE_DIR="$TMP_STATE" \
LILHOUSE_RUNTIME_DIR="$TMP_RUN" \
LILHOUSE_LOG_DIR="$TMP_LOG" \
LILHOUSE_CURRENT_STATE_FILE="$TMP_STATE/current-state.json" \
"$REPO_DIR/bin/lilhouse-action" test success "smoke test action" smoke-test

LILHOUSE_STATE_DIR="$TMP_STATE" \
LILHOUSE_RUNTIME_DIR="$TMP_RUN" \
LILHOUSE_LOG_DIR="$TMP_LOG" \
LILHOUSE_CURRENT_STATE_FILE="$TMP_STATE/current-state.json" \
"$REPO_DIR/bin/lilhouse-current-state" >/dev/null

LILHOUSE_STATE_DIR="$TMP_STATE" \
LILHOUSE_RUNTIME_DIR="$TMP_RUN" \
LILHOUSE_LOG_DIR="$TMP_LOG" \
LILHOUSE_STORAGE_PATHS="/,$REPO_DIR" \
"$REPO_DIR/bin/lilhouse-storage-health" >/dev/null

"$REPO_DIR/bin/lilhouse-interface-report" >"$TMP_STATE/interface-report.json"

"$REPO_DIR/bin/lilhouse-router-plan" \
  --wan wan0 \
  --lan lan0 \
  --lan-ip 10.23.0.1 \
  --subnet 10.23.0.0/24 \
  --dhcp-start 10.23.0.100 \
  --dhcp-end 10.23.0.200 \
  --output "$TMP_STATE/router-plan.json" >/dev/null

"$REPO_DIR/bin/lilhouse-router-plan-summary" "$TMP_STATE/router-plan.json" >"$TMP_STATE/router-plan-summary.txt"

"$REPO_DIR/bin/lilhouse-router-wizard" \
  --out-dir "$TMP_STATE/router-wizard" \
  --wan wan0 \
  --lan lan0 \
  --lan-ip 10.23.0.1 \
  --subnet 10.23.0.0/24 \
  --dhcp-start 10.23.0.100 \
  --dhcp-end 10.23.0.200 >/dev/null

LILHOUSE_STATE_DIR="$TMP_STATE" \
LILHOUSE_RUNTIME_DIR="$TMP_RUN" \
LILHOUSE_LOG_DIR="$TMP_LOG" \
LILHOUSE_CURRENT_STATE_FILE="$TMP_STATE/current-state.json" \
"$REPO_DIR/bin/lilhouse-status" >/dev/null

echo
echo "== verify output files =="
test -s "$TMP_STATE/events.jsonl"
test -s "$TMP_STATE/actions.jsonl"
test -s "$TMP_STATE/current-state.json"
test -s "$TMP_STATE/storage-health.json"
test -s "$TMP_STATE/interface-report.json"
test -s "$TMP_STATE/router-plan.json"
test -s "$TMP_STATE/router-plan-summary.txt"
test -s "$TMP_STATE/router-wizard/interface-report.json"
test -s "$TMP_STATE/router-wizard/router-plan.json"
test -s "$TMP_STATE/router-wizard/router-plan-summary.txt"

echo
echo
echo "== run installer router-deploy dry-run wizard =="

WIZARD_OUT="$TMP_STATE/install-router-wizard"
WIZARD_LOG="$TMP_STATE/install-router-wizard.out"
ROUTER_WIZARD_WAN=eth0 ROUTER_WIZARD_LAN=eth1 \
  ./install.sh --mode router-deploy --wizard --dry-run --out-dir "$WIZARD_OUT" >"$WIZARD_LOG"

test -f "$WIZARD_OUT/interface-report.json"
test -f "$WIZARD_OUT/router-plan.json"
test -f "$WIZARD_OUT/router-plan-summary.txt"
test -f "$WIZARD_OUT/preview/MANIFEST.txt"
test -f "$WIZARD_OUT/preview/ROLLBACK-NOTES.txt"
test -f "$WIZARD_OUT/preview/VALIDATION-CHECKLIST.txt"
test -f "$WIZARD_OUT/preview/etc/systemd/network/20-lilhouse-lan.network"
test -f "$WIZARD_OUT/preview/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
test -f "$WIZARD_OUT/preview/etc/nftables.conf"
test -f "$WIZARD_OUT/preview/etc/lilhouse/pihole-dns-plan.env"
test -f "$WIZARD_OUT/preview/etc/lilhouse/pihole-dhcp-plan.env"
test -f "$WIZARD_OUT/preview/etc/unbound/unbound.conf.d/lilhouse.conf"
test -f "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-current-state.service"
test -f "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-current-state.timer"
test -f "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-storage-health.service"
test -f "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-storage-health.timer"

grep -q "LilHouse router deploy preview" "$WIZARD_OUT/preview/etc/systemd/network/20-lilhouse-lan.network"
grep -q "\[Match\]" "$WIZARD_OUT/preview/etc/systemd/network/20-lilhouse-lan.network"
grep -q "\[Network\]" "$WIZARD_OUT/preview/etc/systemd/network/20-lilhouse-lan.network"
grep -q "Address=10.23.0.1/24" "$WIZARD_OUT/preview/etc/systemd/network/20-lilhouse-lan.network"

grep -q "net.ipv4.ip_forward=1" "$WIZARD_OUT/preview/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
grep -q "net.ipv6.conf.all.forwarding=0" "$WIZARD_OUT/preview/etc/sysctl.d/90-lilhouse-router-forwarding.conf"

grep -q "table inet lilhouse_filter" "$WIZARD_OUT/preview/etc/nftables.conf"
grep -q "policy drop" "$WIZARD_OUT/preview/etc/nftables.conf"
grep -q "iifname \"eth1\" accept" "$WIZARD_OUT/preview/etc/nftables.conf"
grep -q "iifname \"eth1\" oifname \"eth0\" accept" "$WIZARD_OUT/preview/etc/nftables.conf"
grep -q "masquerade" "$WIZARD_OUT/preview/etc/nftables.conf"

grep -q "LILHOUSE_DNS_MODE=pihole-unbound" "$WIZARD_OUT/preview/etc/lilhouse/pihole-dns-plan.env"
grep -q "LILHOUSE_PIHOLE_UPSTREAM=127.0.0.1#5335" "$WIZARD_OUT/preview/etc/lilhouse/pihole-dns-plan.env"
grep -q "LILHOUSE_PIHOLE_INTERFACE=eth1" "$WIZARD_OUT/preview/etc/lilhouse/pihole-dns-plan.env"
grep -q "LILHOUSE_DHCP_PROVIDER=pihole-FTL" "$WIZARD_OUT/preview/etc/lilhouse/pihole-dhcp-plan.env"
grep -q "LILHOUSE_DHCP_INTERFACE=eth1" "$WIZARD_OUT/preview/etc/lilhouse/pihole-dhcp-plan.env"
grep -q "LILHOUSE_DHCP_ROUTER=10.23.0.1" "$WIZARD_OUT/preview/etc/lilhouse/pihole-dhcp-plan.env"
grep -q "LILHOUSE_DHCP_START=10.23.0.100" "$WIZARD_OUT/preview/etc/lilhouse/pihole-dhcp-plan.env"
grep -q "LILHOUSE_DHCP_END=10.23.0.200" "$WIZARD_OUT/preview/etc/lilhouse/pihole-dhcp-plan.env"
grep -q "interface: 127.0.0.1" "$WIZARD_OUT/preview/etc/unbound/unbound.conf.d/lilhouse.conf"
grep -q "port: 5335" "$WIZARD_OUT/preview/etc/unbound/unbound.conf.d/lilhouse.conf"
grep -q "edns-buffer-size: 1232" "$WIZARD_OUT/preview/etc/unbound/unbound.conf.d/lilhouse.conf"

grep -q "ExecStart=/usr/local/bin/lilhouse-current-state" "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-current-state.service"
grep -q "OnUnitActiveSec=1min" "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-current-state.timer"
grep -q "ExecStart=/usr/local/bin/lilhouse-storage-health" "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-storage-health.service"
grep -q "OnUnitActiveSec=15min" "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-storage-health.timer"
grep -q "WantedBy=timers.target" "$WIZARD_OUT/preview/etc/systemd/system/lilhouse-current-state.timer"

grep -q "LilHouse router deploy preview manifest" "$WIZARD_OUT/preview/MANIFEST.txt"
grep -q "No files here have been written to the live system" "$WIZARD_OUT/preview/MANIFEST.txt"
grep -q "WAN interface: eth0" "$WIZARD_OUT/preview/MANIFEST.txt"
grep -q "LAN interface: eth1" "$WIZARD_OUT/preview/MANIFEST.txt"
grep -q "LAN address: 10.23.0.1/24" "$WIZARD_OUT/preview/MANIFEST.txt"
grep -q "etc/nftables.conf" "$WIZARD_OUT/preview/MANIFEST.txt"
grep -q "etc/unbound/unbound.conf.d/lilhouse.conf" "$WIZARD_OUT/preview/MANIFEST.txt"
grep -q "ROLLBACK-NOTES.txt" "$WIZARD_OUT/preview/MANIFEST.txt"
grep -q "VALIDATION-CHECKLIST.txt" "$WIZARD_OUT/preview/MANIFEST.txt"

grep -q "LilHouse router deploy rollback preview" "$WIZARD_OUT/preview/ROLLBACK-NOTES.txt"
grep -q "Future apply mode must back up" "$WIZARD_OUT/preview/ROLLBACK-NOTES.txt"
grep -q "/etc/nftables.conf" "$WIZARD_OUT/preview/ROLLBACK-NOTES.txt"
grep -q "Do not enable apply mode" "$WIZARD_OUT/preview/ROLLBACK-NOTES.txt"

grep -q "LilHouse router deploy validation checklist" "$WIZARD_OUT/preview/VALIDATION-CHECKLIST.txt"
grep -q "WAN interface exists: eth0" "$WIZARD_OUT/preview/VALIDATION-CHECKLIST.txt"
grep -q "LAN interface exists: eth1" "$WIZARD_OUT/preview/VALIDATION-CHECKLIST.txt"
grep -q "nftables preview can be checked without applying" "$WIZARD_OUT/preview/VALIDATION-CHECKLIST.txt"
grep -q "current SSH/admin session is protected from lockout" "$WIZARD_OUT/preview/VALIDATION-CHECKLIST.txt"
grep -q "Apply mode must validate, back up, stage, test, and only then activate" "$WIZARD_OUT/preview/VALIDATION-CHECKLIST.txt"

grep -q "lan_static_address" "$WIZARD_OUT/router-plan-summary.txt"
grep -q "forwarding" "$WIZARD_OUT/router-plan-summary.txt"
grep -q "firewall_nat" "$WIZARD_OUT/router-plan-summary.txt"
grep -q "dns" "$WIZARD_OUT/router-plan-summary.txt"
grep -q "dhcp" "$WIZARD_OUT/router-plan-summary.txt"
grep -q "worker_timers" "$WIZARD_OUT/router-plan-summary.txt"
grep -q "No system changes" "$WIZARD_LOG"
grep -q "Preview validation passed." "$WIZARD_LOG"
"$REPO_DIR/bin/lilhouse-router-preview-validate" "$WIZARD_OUT/preview" >/dev/null

"$REPO_DIR/bin/lilhouse-router-backup-plan" >"$TMP_STATE/router-backup-plan.json"
python3 -m json.tool "$TMP_STATE/router-backup-plan.json" >/dev/null
grep -q '"schema": "lilhouse.router_backup_plan.v1"' "$TMP_STATE/router-backup-plan.json"
grep -q '"apply": false' "$TMP_STATE/router-backup-plan.json"
grep -q '"/etc/nftables.conf"' "$TMP_STATE/router-backup-plan.json"
grep -q '"/etc/pihole"' "$TMP_STATE/router-backup-plan.json"

"$REPO_DIR/bin/lilhouse-router-backup-dry-run" --root "$TMP_ROOT" >"$TMP_STATE/router-backup-dry-run.json"
python3 -m json.tool "$TMP_STATE/router-backup-dry-run.json" >/dev/null
grep -q '"schema": "lilhouse.router_backup_dry_run.v1"' "$TMP_STATE/router-backup-dry-run.json"
grep -q '"copies_files": false' "$TMP_STATE/router-backup-dry-run.json"
grep -q '"/etc/systemd/system/lilhouse-current-state.service"' "$TMP_STATE/router-backup-dry-run.json"

mkdir -p "$TMP_ROOT/etc/pihole" "$TMP_ROOT/etc/systemd/system" "$TMP_ROOT/etc/sysctl.d"
echo "# smoke nftables" > "$TMP_ROOT/etc/nftables.conf"
echo "net.ipv4.ip_forward=1" > "$TMP_ROOT/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
echo "# smoke pihole" > "$TMP_ROOT/etc/pihole/test.conf"
echo "# smoke current-state service" > "$TMP_ROOT/etc/systemd/system/lilhouse-current-state.service"

BACKUP_OUT="$TMP_STATE/router-backup-create"
"$REPO_DIR/bin/lilhouse-router-backup-create"   --root "$TMP_ROOT"   --backup-dir "$BACKUP_OUT"   --yes >"$TMP_STATE/router-backup-create.json"

python3 -m json.tool "$TMP_STATE/router-backup-create.json" >/dev/null
test -f "$BACKUP_OUT/backup-report.json"
test -f "$BACKUP_OUT/etc/nftables.conf"
test -f "$BACKUP_OUT/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
test -f "$BACKUP_OUT/etc/pihole/test.conf"
grep -q '"schema": "lilhouse.router_backup_create.v1"' "$TMP_STATE/router-backup-create.json"
grep -q '"apply": true' "$TMP_STATE/router-backup-create.json"
grep -q '"file_copied"' "$TMP_STATE/router-backup-create.json"

"$REPO_DIR/bin/lilhouse-router-backup-verify" "$BACKUP_OUT" >"$TMP_STATE/router-backup-verify.json"
python3 -m json.tool "$TMP_STATE/router-backup-verify.json" >/dev/null
grep -q '"schema": "lilhouse.router_backup_verify.v1"' "$TMP_STATE/router-backup-verify.json"
grep -q '"ok": true' "$TMP_STATE/router-backup-verify.json"
grep -q '"error_count": 0' "$TMP_STATE/router-backup-verify.json"

RESTORE_TARGET="$TMP_STATE/router-restore-target"
mkdir -p "$RESTORE_TARGET"
"$REPO_DIR/bin/lilhouse-router-restore-dry-run" "$BACKUP_OUT" --root "$RESTORE_TARGET" >"$TMP_STATE/router-restore-dry-run.json"
python3 -m json.tool "$TMP_STATE/router-restore-dry-run.json" >/dev/null
grep -q '"schema": "lilhouse.router_restore_dry_run.v1"' "$TMP_STATE/router-restore-dry-run.json"
grep -q '"apply": false' "$TMP_STATE/router-restore-dry-run.json"
grep -q '"copies_files": false' "$TMP_STATE/router-restore-dry-run.json"
python3 - "$TMP_STATE/router-backup-create.json" "$TMP_STATE/router-restore-dry-run.json" <<'PYJSON'
import json, sys
backup = json.load(open(sys.argv[1]))
restore = json.load(open(sys.argv[2]))
assert restore["summary"]["would_restore"] == backup["summary"]["copied"]
assert restore["summary"]["would_restore"] >= 4
PYJSON

RESTORE_CREATE_TARGET="$TMP_STATE/router-restore-create-target"
mkdir -p "$RESTORE_CREATE_TARGET"
"$REPO_DIR/bin/lilhouse-router-restore-create" "$BACKUP_OUT" --root "$RESTORE_CREATE_TARGET" --yes >"$TMP_STATE/router-restore-create.json"
python3 -m json.tool "$TMP_STATE/router-restore-create.json" >/dev/null
test -f "$RESTORE_CREATE_TARGET/restore-report.json"
test -f "$RESTORE_CREATE_TARGET/etc/nftables.conf"
test -f "$RESTORE_CREATE_TARGET/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
test -f "$RESTORE_CREATE_TARGET/etc/pihole/test.conf"
grep -q '"schema": "lilhouse.router_restore_create.v1"' "$TMP_STATE/router-restore-create.json"
grep -q '"ok": true' "$TMP_STATE/router-restore-create.json"
python3 - "$TMP_STATE/router-backup-create.json" "$TMP_STATE/router-restore-create.json" <<'PYJSON'
import json, sys
backup = json.load(open(sys.argv[1]))
restore = json.load(open(sys.argv[2]))
assert restore["summary"]["restored"] == backup["summary"]["copied"]
assert restore["summary"]["restored"] >= 4
assert restore["ok"] is True
PYJSON

SAFETY_RESTORE_TARGET="$TMP_STATE/router-safety-loop-restore-target"
SAFETY_BACKUP_OUT="$TMP_STATE/router-safety-loop-backup"
mkdir -p "$SAFETY_RESTORE_TARGET"

"$REPO_DIR/bin/lilhouse-router-safety-loop" \
  --root "$TMP_ROOT" \
  --backup-dir "$SAFETY_BACKUP_OUT" \
  --restore-root "$SAFETY_RESTORE_TARGET" \
  --yes >"$TMP_STATE/router-safety-loop.json"

python3 -m json.tool "$TMP_STATE/router-safety-loop.json" >/dev/null
test -f "$SAFETY_RESTORE_TARGET/restore-report.json"
test -f "$SAFETY_RESTORE_TARGET/etc/nftables.conf"
test -f "$SAFETY_RESTORE_TARGET/etc/pihole/test.conf"

python3 - "$TMP_STATE/router-safety-loop.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_safety_loop.v1"
assert data["ok"] is True
assert data["summary"]["backed_up"] >= 4
assert data["summary"]["backed_up"] == data["summary"]["verified"]
assert data["summary"]["backed_up"] == data["summary"]["would_restore"]
assert data["summary"]["backed_up"] == data["summary"]["restored"]
assert data["summary"]["restore_errors"] == 0
PYJSON

STAGE_TARGET="$TMP_STATE/router-stage-preview-target"
"$REPO_DIR/bin/lilhouse-router-stage-preview" "$WIZARD_OUT/preview" --target-root "$STAGE_TARGET" --yes >"$TMP_STATE/router-stage-preview.json"
python3 -m json.tool "$TMP_STATE/router-stage-preview.json" >/dev/null
test -f "$STAGE_TARGET/stage-preview-report.json"
test -f "$STAGE_TARGET/etc/nftables.conf"
test -f "$STAGE_TARGET/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
test -f "$STAGE_TARGET/etc/lilhouse/pihole-dns-plan.env"
test -f "$STAGE_TARGET/MANIFEST.txt"
grep -q '"schema": "lilhouse.router_stage_preview.v1"' "$TMP_STATE/router-stage-preview.json"
grep -q '"live_root_allowed": false' "$TMP_STATE/router-stage-preview.json"

"$REPO_DIR/bin/lilhouse-router-stage-validate" "$STAGE_TARGET" >"$TMP_STATE/router-stage-validate.json"
python3 -m json.tool "$TMP_STATE/router-stage-validate.json" >/dev/null
grep -q '"schema": "lilhouse.router_stage_validate.v1"' "$TMP_STATE/router-stage-validate.json"
grep -q '"apply": false' "$TMP_STATE/router-stage-validate.json"
grep -q '"live_root_allowed": false' "$TMP_STATE/router-stage-validate.json"
grep -q '"ok": true' "$TMP_STATE/router-stage-validate.json"
grep -q '"error_count": 0' "$TMP_STATE/router-stage-validate.json"

PREFLIGHT_OUT="$TMP_STATE/router-deploy-preflight"
PREFLIGHT_STAGE="$TMP_STATE/router-deploy-preflight-stage"
"$REPO_DIR/bin/lilhouse-router-deploy-preflight" \
  --out-dir "$PREFLIGHT_OUT" \
  --source-root "$TMP_ROOT" \
  --stage-root "$PREFLIGHT_STAGE" \
  --wan eth0 \
  --lan eth1 \
  --enable-cake \
  --enable-ipv6 >"$TMP_STATE/router-deploy-preflight.json"

python3 -m json.tool "$TMP_STATE/router-deploy-preflight.json" >/dev/null
test -f "$PREFLIGHT_OUT/deploy-preflight-report.json"
test -f "$PREFLIGHT_STAGE/etc/nftables.conf"
test -f "$PREFLIGHT_STAGE/etc/lilhouse/pihole-dns-plan.env"

python3 - "$TMP_STATE/router-deploy-preflight.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_deploy_preflight.v1"
assert data["apply"] is False
assert data["live_root_allowed"] is False
assert data["ok"] is True
assert data["summary"]["preview_validated"] is True
assert data["summary"]["safety_loop_ok"] is True
assert data["summary"]["stage_validate_ok"] is True
assert data["summary"]["stage_validate_errors"] == 0
assert data["summary"]["stage_preview_count"] >= 10
PYJSON

"$REPO_DIR/bin/lilhouse-router-apply-plan" "$PREFLIGHT_OUT/deploy-preflight-report.json" >"$TMP_STATE/router-apply-plan.json"
python3 -m json.tool "$TMP_STATE/router-apply-plan.json" >/dev/null

python3 - "$TMP_STATE/router-apply-plan.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_apply_plan.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["summary"]["requires_timed_rollback"] is True
assert data["summary"]["requires_fresh_backup"] is True
assert data["summary"]["requires_manual_confirmation"] is True
assert data["summary"]["safe_to_apply_now"] is False
assert data["summary"]["actions_planned"] >= 8
PYJSON

APPLY_DRY_TARGET="$TMP_STATE/router-apply-dry-run-target"
mkdir -p "$APPLY_DRY_TARGET"
"$REPO_DIR/bin/lilhouse-router-apply-dry-run" "$TMP_STATE/router-apply-plan.json" --target-root "$APPLY_DRY_TARGET" >"$TMP_STATE/router-apply-dry-run.json"
python3 -m json.tool "$TMP_STATE/router-apply-dry-run.json" >/dev/null

python3 - "$TMP_STATE/router-apply-dry-run.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_apply_dry_run.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["copies_files"] is False
assert data["live_root_allowed"] is False
assert data["ok"] is True
assert data["summary"]["safe_to_apply_now"] is False
assert data["would_copy_count"] >= 10
PYJSON

APPLY_CREATE_TARGET="$TMP_STATE/router-apply-create-target"
mkdir -p "$APPLY_CREATE_TARGET"
"$REPO_DIR/bin/lilhouse-router-apply-create" "$TMP_STATE/router-apply-dry-run.json" --target-root "$APPLY_CREATE_TARGET" --yes >"$TMP_STATE/router-apply-create.json"
python3 -m json.tool "$TMP_STATE/router-apply-create.json" >/dev/null
test -f "$APPLY_CREATE_TARGET/apply-create-report.json"
test -f "$APPLY_CREATE_TARGET/etc/nftables.conf"
test -f "$APPLY_CREATE_TARGET/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
test -f "$APPLY_CREATE_TARGET/etc/lilhouse/pihole-dns-plan.env"

python3 - "$TMP_STATE/router-apply-create.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_apply_create.v1"
assert data["apply"] is True
assert data["live_changes"] is False
assert data["live_root_allowed"] is False
assert data["ok"] is True
assert data["summary"]["safe_to_apply_live"] is False
assert data["copied_count"] >= 10
assert data["copied_count"] == data["summary"]["expected_copy_count"]
PYJSON

"$REPO_DIR/bin/lilhouse-router-apply-validate" "$APPLY_CREATE_TARGET" >"$TMP_STATE/router-apply-validate.json"
python3 -m json.tool "$TMP_STATE/router-apply-validate.json" >/dev/null

python3 - "$TMP_STATE/router-apply-validate.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_apply_validate.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["live_root_allowed"] is False
assert data["ok"] is True
assert data["summary"]["stage_validate_ok"] is True
assert data["summary"]["stage_validate_errors"] == 0
assert data["summary"]["missing_after_copy"] == 0
assert data["summary"]["copied_count"] == data["summary"]["expected_copy_count"]
assert data["summary"]["safe_to_apply_live"] is False
PYJSON

DRESS_OUT="$TMP_STATE/router-full-dress-rehearsal"
DRESS_STAGE="$TMP_STATE/router-full-dress-stage"
DRESS_APPLY="$TMP_STATE/router-full-dress-apply"
"$REPO_DIR/bin/lilhouse-router-full-dress-rehearsal" \
  --out-dir "$DRESS_OUT" \
  --source-root "$TMP_ROOT" \
  --stage-root "$DRESS_STAGE" \
  --apply-target-root "$DRESS_APPLY" \
  --wan eth0 \
  --lan eth1 \
  --enable-cake \
  --enable-ipv6 >"$TMP_STATE/router-full-dress-rehearsal.json"

python3 -m json.tool "$TMP_STATE/router-full-dress-rehearsal.json" >/dev/null
test -f "$DRESS_OUT/full-dress-rehearsal-report.json"
test -f "$DRESS_APPLY/apply-create-report.json"
test -f "$DRESS_APPLY/etc/nftables.conf"

python3 - "$TMP_STATE/router-full-dress-rehearsal.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_full_dress_rehearsal.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["live_root_allowed"] is False
assert data["ok"] is True
assert data["summary"]["preflight_ok"] is True
assert data["summary"]["apply_plan_ok"] is True
assert data["summary"]["apply_dry_run_ok"] is True
assert data["summary"]["apply_create_ok"] is True
assert data["summary"]["apply_validate_ok"] is True
assert data["summary"]["validated_missing_after_copy"] == 0
assert data["summary"]["safe_to_apply_live"] is False
PYJSON

"$REPO_DIR/bin/lilhouse-router-live-readiness" "$DRESS_OUT/full-dress-rehearsal-report.json" >"$TMP_STATE/router-live-readiness.json"
python3 -m json.tool "$TMP_STATE/router-live-readiness.json" >/dev/null

python3 - "$TMP_STATE/router-live-readiness.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_live_readiness.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["ready_for_live_apply"] is False
assert data["summary"]["non_live_pipeline_proven"] is True
assert data["summary"]["critical_blocker_count"] >= 1
assert data["summary"]["safe_to_apply_live"] is False
PYJSON

"$REPO_DIR/bin/lilhouse-router-timed-rollback-plan" \
  --backup-dir "$DRESS_OUT/preflight/backup" \
  --rollback-root / \
  --timeout-minutes 5 >"$TMP_STATE/router-timed-rollback-plan.json"

python3 -m json.tool "$TMP_STATE/router-timed-rollback-plan.json" >/dev/null

python3 - "$TMP_STATE/router-timed-rollback-plan.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_timed_rollback_plan.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["writes_files"] is False
assert data["ok"] is True
assert data["summary"]["requires_verified_backup"] is True
assert data["summary"]["requires_timer_arm_before_live_changes"] is True
assert data["summary"]["requires_health_check_cancel"] is True
assert data["summary"]["safe_to_apply_live"] is False
assert data["timeout_minutes"] == 5
PYJSON

ROLLBACK_UNIT_ROOT="$TMP_STATE/router-timed-rollback-units"
mkdir -p "$ROLLBACK_UNIT_ROOT"
"$REPO_DIR/bin/lilhouse-router-timed-rollback-create" "$TMP_STATE/router-timed-rollback-plan.json" --target-root "$ROLLBACK_UNIT_ROOT" --yes >"$TMP_STATE/router-timed-rollback-create.json"

python3 -m json.tool "$TMP_STATE/router-timed-rollback-create.json" >/dev/null
test -f "$ROLLBACK_UNIT_ROOT/timed-rollback-create-report.json"
test -f "$ROLLBACK_UNIT_ROOT/etc/systemd/system/lilhouse-router-rollback-guard.service"
test -f "$ROLLBACK_UNIT_ROOT/etc/systemd/system/lilhouse-router-rollback-guard.timer"

python3 - "$TMP_STATE/router-timed-rollback-create.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_timed_rollback_create.v1"
assert data["apply"] is True
assert data["live_changes"] is False
assert data["live_root_allowed"] is False
assert data["ok"] is True
assert data["written_count"] == 2
assert data["summary"]["requires_health_check_cancel"] is True
assert data["summary"]["safe_to_apply_live"] is False
PYJSON

"$REPO_DIR/bin/lilhouse-router-timed-rollback-validate" "$ROLLBACK_UNIT_ROOT" >"$TMP_STATE/router-timed-rollback-validate.json"
python3 -m json.tool "$TMP_STATE/router-timed-rollback-validate.json" >/dev/null

python3 - "$TMP_STATE/router-timed-rollback-validate.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_timed_rollback_validate.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["live_root_allowed"] is False
assert data["ok"] is True
assert data["error_count"] == 0
assert data["summary"]["checks_passed"] == data["summary"]["checks_total"]
assert data["summary"]["safe_to_apply_live"] is False
PYJSON

ROLLBACK_REHEARSAL_OUT="$TMP_STATE/router-timed-rollback-rehearsal"
ROLLBACK_REHEARSAL_UNITS="$TMP_STATE/router-timed-rollback-rehearsal-units"
"$REPO_DIR/bin/lilhouse-router-timed-rollback-rehearsal" \
  --out-dir "$ROLLBACK_REHEARSAL_OUT" \
  --source-root "$TMP_ROOT" \
  --unit-target-root "$ROLLBACK_REHEARSAL_UNITS" \
  --rollback-root / \
  --timeout-minutes 5 >"$TMP_STATE/router-timed-rollback-rehearsal.json"

python3 -m json.tool "$TMP_STATE/router-timed-rollback-rehearsal.json" >/dev/null
test -f "$ROLLBACK_REHEARSAL_OUT/timed-rollback-rehearsal-report.json"
test -f "$ROLLBACK_REHEARSAL_UNITS/timed-rollback-create-report.json"
test -f "$ROLLBACK_REHEARSAL_UNITS/etc/systemd/system/lilhouse-router-rollback-guard.service"
test -f "$ROLLBACK_REHEARSAL_UNITS/etc/systemd/system/lilhouse-router-rollback-guard.timer"

python3 - "$TMP_STATE/router-timed-rollback-rehearsal.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_timed_rollback_rehearsal.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["live_root_allowed"] is False
assert data["ok"] is True
assert data["summary"]["backup_verified"] is True
assert data["summary"]["rollback_plan_ok"] is True
assert data["summary"]["rollback_units_created"] is True
assert data["summary"]["rollback_units_validated"] is True
assert data["summary"]["rollback_checks_passed"] == data["summary"]["rollback_checks_total"]
assert data["summary"]["safe_to_apply_live"] is False
PYJSON

"$REPO_DIR/bin/lilhouse-router-live-confirmation-plan" \
  "$TMP_STATE/router-live-readiness.json" \
  --rollback-rehearsal-report "$ROLLBACK_REHEARSAL_OUT/timed-rollback-rehearsal-report.json" >"$TMP_STATE/router-live-confirmation-plan.json"

python3 -m json.tool "$TMP_STATE/router-live-confirmation-plan.json" >/dev/null

python3 - "$TMP_STATE/router-live-confirmation-plan.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_live_confirmation_plan.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["summary"]["confirmation_gate_defined"] is True
assert data["summary"]["ready_for_live_apply"] is False
assert data["summary"]["safe_to_apply_live"] is False
assert data["confirmation_policy"]["requires_exact_confirmation_phrase"] is True
assert data["confirmation_policy"]["reject_plain_yes"] is True
assert data["summary"]["checks_passed"] == data["summary"]["checks_total"]
PYJSON

set +e
"$REPO_DIR/bin/lilhouse-router-live-confirmation-check" "$TMP_STATE/router-live-confirmation-plan.json" --phrase "yes" >"$TMP_STATE/router-live-confirmation-check-bad.json"
BAD_CONFIRM_EXIT=$?
set -e
test "$BAD_CONFIRM_EXIT" -ne 0

"$REPO_DIR/bin/lilhouse-router-live-confirmation-check" \
  "$TMP_STATE/router-live-confirmation-plan.json" \
  --phrase "I have local console access and accept temporary network interruption" >"$TMP_STATE/router-live-confirmation-check-good.json"

python3 -m json.tool "$TMP_STATE/router-live-confirmation-check-good.json" >/dev/null

python3 - "$TMP_STATE/router-live-confirmation-check-good.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_live_confirmation_check.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["accepted"] is True
assert data["summary"]["confirmation_accepted"] is True
assert data["summary"]["ready_for_live_apply"] is False
assert data["summary"]["safe_to_apply_live"] is False
PYJSON

"$REPO_DIR/bin/lilhouse-router-post-apply-health-plan" \
  "$DRESS_OUT/apply-plan.json" \
  --lan-ip 10.23.0.1 \
  --dns-test-name example.com \
  --wan-test-ip 1.1.1.1 \
  --timeout-seconds 120 >"$TMP_STATE/router-post-apply-health-plan.json"

python3 -m json.tool "$TMP_STATE/router-post-apply-health-plan.json" >/dev/null

python3 - "$TMP_STATE/router-post-apply-health-plan.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_post_apply_health_plan.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["summary"]["requires_all_checks_pass"] is True
assert data["summary"]["rollback_cancel_allowed_only_after_pass"] is True
assert data["summary"]["safe_to_cancel_rollback_now"] is False
assert data["summary"]["safe_to_apply_live"] is False
assert data["summary"]["required_check_count"] >= 6
PYJSON

cat >"$TMP_STATE/router-post-apply-health-results-fail.json" <<'JSON'
{
  "local_admin_path": true,
  "lan_gateway_reachable": true,
  "dns_resolution": false,
  "wan_reachability": true,
  "dhcp_service_state": true,
  "firewall_service_state": true,
  "rollback_timer_state": true
}
JSON

cat >"$TMP_STATE/router-post-apply-health-results-pass.json" <<'JSON'
{
  "local_admin_path": true,
  "lan_gateway_reachable": true,
  "dns_resolution": true,
  "wan_reachability": true,
  "dhcp_service_state": true,
  "firewall_service_state": true,
  "rollback_timer_state": true
}
JSON

"$REPO_DIR/bin/lilhouse-router-post-apply-health-dry-run" \
  "$TMP_STATE/router-post-apply-health-plan.json" \
  --results "$TMP_STATE/router-post-apply-health-results-fail.json" >"$TMP_STATE/router-post-apply-health-dry-run-fail.json"

"$REPO_DIR/bin/lilhouse-router-post-apply-health-dry-run" \
  "$TMP_STATE/router-post-apply-health-plan.json" \
  --results "$TMP_STATE/router-post-apply-health-results-pass.json" >"$TMP_STATE/router-post-apply-health-dry-run-pass.json"

python3 -m json.tool "$TMP_STATE/router-post-apply-health-dry-run-fail.json" >/dev/null
python3 -m json.tool "$TMP_STATE/router-post-apply-health-dry-run-pass.json" >/dev/null

python3 - "$TMP_STATE/router-post-apply-health-dry-run-fail.json" "$TMP_STATE/router-post-apply-health-dry-run-pass.json" <<'PYJSON'
import json, sys
fail = json.load(open(sys.argv[1]))
passed = json.load(open(sys.argv[2]))

assert fail["schema"] == "lilhouse.router_post_apply_health_dry_run.v1"
assert fail["apply"] is False
assert fail["live_changes"] is False
assert fail["ok"] is True
assert fail["summary"]["all_required_checks_passed"] is False
assert fail["summary"]["rollback_cancel_allowed"] is False
assert fail["summary"]["safe_to_cancel_rollback_now"] is False

assert passed["schema"] == "lilhouse.router_post_apply_health_dry_run.v1"
assert passed["apply"] is False
assert passed["live_changes"] is False
assert passed["ok"] is True
assert passed["summary"]["all_required_checks_passed"] is True
assert passed["summary"]["rollback_cancel_allowed"] is True
assert passed["summary"]["safe_to_cancel_rollback_now"] is False
assert passed["summary"]["safe_to_apply_live"] is False
PYJSON

HEALTH_REHEARSAL_OUT="$TMP_STATE/router-post-apply-health-rehearsal"
"$REPO_DIR/bin/lilhouse-router-post-apply-health-rehearsal" \
  --out-dir "$HEALTH_REHEARSAL_OUT" \
  --apply-plan "$DRESS_OUT/apply-plan.json" \
  --lan-ip 10.23.0.1 \
  --dns-test-name example.com \
  --wan-test-ip 1.1.1.1 \
  --timeout-seconds 120 >"$TMP_STATE/router-post-apply-health-rehearsal.json"

python3 -m json.tool "$TMP_STATE/router-post-apply-health-rehearsal.json" >/dev/null
test -f "$HEALTH_REHEARSAL_OUT/post-apply-health-rehearsal-report.json"
test -f "$HEALTH_REHEARSAL_OUT/post-apply-health-plan.json"

python3 - "$TMP_STATE/router-post-apply-health-rehearsal.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_post_apply_health_rehearsal.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["summary"]["health_plan_ok"] is True
assert data["summary"]["failure_blocks_rollback_cancel"] is True
assert data["summary"]["all_pass_allows_rollback_cancel_in_theory"] is True
assert data["summary"]["safe_to_cancel_rollback_now"] is False
assert data["summary"]["safe_to_apply_live"] is False
PYJSON

"$REPO_DIR/bin/lilhouse-router-service-activation-plan" \
  "$DRESS_OUT/apply-plan.json" \
  --rollback-rehearsal-report "$ROLLBACK_REHEARSAL_OUT/timed-rollback-rehearsal-report.json" \
  --health-rehearsal-report "$HEALTH_REHEARSAL_OUT/post-apply-health-rehearsal-report.json" >"$TMP_STATE/router-service-activation-plan.json"

python3 -m json.tool "$TMP_STATE/router-service-activation-plan.json" >/dev/null

python3 - "$TMP_STATE/router-service-activation-plan.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_service_activation_plan.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["summary"]["checks_passed"] == data["summary"]["checks_total"]
assert data["summary"]["step_count"] >= 7
assert data["summary"]["rollback_armed_before_network_changes"] is True
assert data["summary"]["rollback_cancel_after_health_only"] is True
assert data["summary"]["safe_to_apply_live"] is False
PYJSON


cat >"$TMP_STATE/router-service-activation-results-fail.json" <<'JSON'
{
  "daemon_reload_before_enable": true,
  "arm_rollback_timer": true,
  "apply_forwarding_sysctl": true,
  "activate_firewall": false,
  "activate_networkd": true,
  "activate_lilhouse_timers": true,
  "run_post_apply_health": true,
  "cancel_rollback_only_after_health_pass": true
}
JSON

cat >"$TMP_STATE/router-service-activation-results-pass.json" <<'JSON'
{
  "daemon_reload_before_enable": true,
  "arm_rollback_timer": true,
  "apply_forwarding_sysctl": true,
  "activate_firewall": true,
  "activate_networkd": true,
  "activate_lilhouse_timers": true,
  "run_post_apply_health": true,
  "cancel_rollback_only_after_health_pass": true
}
JSON

"$REPO_DIR/bin/lilhouse-router-service-activation-dry-run" \
  "$TMP_STATE/router-service-activation-plan.json" \
  --results "$TMP_STATE/router-service-activation-results-fail.json" >"$TMP_STATE/router-service-activation-dry-run-fail.json"

"$REPO_DIR/bin/lilhouse-router-service-activation-dry-run" \
  "$TMP_STATE/router-service-activation-plan.json" \
  --results "$TMP_STATE/router-service-activation-results-pass.json" >"$TMP_STATE/router-service-activation-dry-run-pass.json"

python3 -m json.tool "$TMP_STATE/router-service-activation-dry-run-fail.json" >/dev/null
python3 -m json.tool "$TMP_STATE/router-service-activation-dry-run-pass.json" >/dev/null

python3 - "$TMP_STATE/router-service-activation-dry-run-fail.json" "$TMP_STATE/router-service-activation-dry-run-pass.json" <<'PYJSON'
import json, sys
fail = json.load(open(sys.argv[1]))
passed = json.load(open(sys.argv[2]))

assert fail["schema"] == "lilhouse.router_service_activation_dry_run.v1"
assert fail["apply"] is False
assert fail["live_changes"] is False
assert fail["ok"] is True
assert fail["summary"]["all_steps_passed"] is False
assert fail["summary"]["failed_step_count"] >= 1
assert fail["summary"]["blocked_step_count"] >= 1
assert fail["summary"]["rollback_cancel_allowed_by_sequence"] is False

assert passed["schema"] == "lilhouse.router_service_activation_dry_run.v1"
assert passed["apply"] is False
assert passed["live_changes"] is False
assert passed["ok"] is True
assert passed["summary"]["all_steps_passed"] is True
assert passed["summary"]["rollback_cancel_allowed_by_sequence"] is True
assert passed["summary"]["safe_to_cancel_rollback_now"] is False
assert passed["summary"]["safe_to_apply_live"] is False
PYJSON


SERVICE_REHEARSAL_OUT="$TMP_STATE/router-service-activation-rehearsal"
"$REPO_DIR/bin/lilhouse-router-service-activation-rehearsal" \
  --out-dir "$SERVICE_REHEARSAL_OUT" \
  --apply-plan "$DRESS_OUT/apply-plan.json" \
  --rollback-rehearsal-report "$ROLLBACK_REHEARSAL_OUT/timed-rollback-rehearsal-report.json" \
  --health-rehearsal-report "$HEALTH_REHEARSAL_OUT/post-apply-health-rehearsal-report.json" >"$TMP_STATE/router-service-activation-rehearsal.json"

python3 -m json.tool "$TMP_STATE/router-service-activation-rehearsal.json" >/dev/null
test -f "$SERVICE_REHEARSAL_OUT/service-activation-rehearsal-report.json"
test -f "$SERVICE_REHEARSAL_OUT/service-activation-plan.json"

python3 - "$TMP_STATE/router-service-activation-rehearsal.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_service_activation_rehearsal.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["summary"]["service_plan_ok"] is True
assert data["summary"]["failure_blocks_sequence"] is True
assert data["summary"]["failure_blocks_rollback_cancel"] is True
assert data["summary"]["all_pass_allows_rollback_cancel_by_sequence"] is True
assert data["summary"]["safe_to_cancel_rollback_now"] is False
assert data["summary"]["safe_to_apply_live"] is False
PYJSON


"$REPO_DIR/bin/lilhouse-router-live-readiness-review" \
  "$DRESS_OUT/full-dress-rehearsal-report.json" \
  --rollback-rehearsal-report "$ROLLBACK_REHEARSAL_OUT/timed-rollback-rehearsal-report.json" \
  --confirmation-plan-report "$TMP_STATE/router-live-confirmation-plan.json" \
  --confirmation-check-report "$TMP_STATE/router-live-confirmation-check-good.json" \
  --health-rehearsal-report "$HEALTH_REHEARSAL_OUT/post-apply-health-rehearsal-report.json" \
  --service-rehearsal-report "$SERVICE_REHEARSAL_OUT/service-activation-rehearsal-report.json" >"$TMP_STATE/router-live-readiness-review.json"

python3 -m json.tool "$TMP_STATE/router-live-readiness-review.json" >/dev/null

python3 - "$TMP_STATE/router-live-readiness-review.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_live_readiness_review.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["ready_for_live_apply"] is False
assert data["summary"]["checks_passed"] == data["summary"]["checks_total"]
assert data["summary"]["non_live_pipeline_proven"] is True
assert data["summary"]["rollback_rehearsal_proven"] is True
assert data["summary"]["confirmation_gate_proven"] is True
assert data["summary"]["health_rehearsal_proven"] is True
assert data["summary"]["service_rehearsal_proven"] is True
assert data["summary"]["critical_blocker_count"] >= 1
assert data["summary"]["safe_to_apply_live"] is False
PYJSON


RESTORE_GUARD_SOURCE="$TMP_STATE/router-restore-guard-source"
RESTORE_GUARD_BACKUP="$TMP_STATE/router-restore-guard-backup"
RESTORE_GUARD_FAKE_ROOT="$TMP_STATE/router-restore-guard-fake-root"

mkdir -p "$RESTORE_GUARD_SOURCE/etc/pihole" "$RESTORE_GUARD_SOURCE/etc/systemd/system" "$RESTORE_GUARD_SOURCE/etc/sysctl.d"
echo "# fake nftables" > "$RESTORE_GUARD_SOURCE/etc/nftables.conf"
echo "net.ipv4.ip_forward=1" > "$RESTORE_GUARD_SOURCE/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
echo "# fake pihole" > "$RESTORE_GUARD_SOURCE/etc/pihole/test.conf"
echo "# fake current-state service" > "$RESTORE_GUARD_SOURCE/etc/systemd/system/lilhouse-current-state.service"

"$REPO_DIR/bin/lilhouse-router-backup-create" \
  --root "$RESTORE_GUARD_SOURCE" \
  --backup-dir "$RESTORE_GUARD_BACKUP" \
  --yes >"$TMP_STATE/router-restore-guard-backup.json"

set +e
"$REPO_DIR/bin/lilhouse-router-restore-create" "$RESTORE_GUARD_BACKUP" --root / --yes >"$TMP_STATE/router-restore-live-root-refuse.json" 2>"$TMP_STATE/router-restore-live-root-refuse.err"
RESTORE_LIVE_ROOT_EXIT=$?
set -e
test "$RESTORE_LIVE_ROOT_EXIT" -eq 2
grep -q "refusing to restore into live / without --allow-live-root" "$TMP_STATE/router-restore-live-root-refuse.err"

"$REPO_DIR/bin/lilhouse-router-restore-create" "$RESTORE_GUARD_BACKUP" --root "$RESTORE_GUARD_FAKE_ROOT" --yes >"$TMP_STATE/router-restore-guard-fake-root.json"
python3 -m json.tool "$TMP_STATE/router-restore-guard-fake-root.json" >/dev/null


"$REPO_DIR/bin/lilhouse-router-health-probe-plan" \
  "$HEALTH_REHEARSAL_OUT/post-apply-health-rehearsal-report.json" \
  --lan-ip 10.23.0.1 \
  --dns-test-name example.com \
  --wan-test-ip 1.1.1.1 \
  --timeout-seconds 120 >"$TMP_STATE/router-health-probe-plan.json"

python3 -m json.tool "$TMP_STATE/router-health-probe-plan.json" >/dev/null

python3 - "$TMP_STATE/router-health-probe-plan.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_health_probe_plan.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["runs_probes"] is False
assert data["ok"] is True
assert data["summary"]["probe_count"] >= 7
assert data["summary"]["requires_all_probes_pass"] is True
assert data["summary"]["rollback_cancel_allowed_only_after_pass"] is True
assert data["summary"]["safe_to_cancel_rollback_now"] is False
assert data["summary"]["safe_to_apply_live"] is False
PYJSON


cat >"$TMP_STATE/router-health-probe-results-fail.json" <<'JSON'
{
  "local_admin_path": true,
  "lan_gateway_reachable": true,
  "dns_resolution": false,
  "wan_reachability": true,
  "dhcp_service_state": true,
  "firewall_service_state": true,
  "rollback_timer_state": true
}
JSON

cat >"$TMP_STATE/router-health-probe-results-pass.json" <<'JSON'
{
  "local_admin_path": true,
  "lan_gateway_reachable": true,
  "dns_resolution": true,
  "wan_reachability": true,
  "dhcp_service_state": true,
  "firewall_service_state": true,
  "rollback_timer_state": true
}
JSON

"$REPO_DIR/bin/lilhouse-router-health-probe-dry-run" \
  "$TMP_STATE/router-health-probe-plan.json" \
  --results "$TMP_STATE/router-health-probe-results-fail.json" >"$TMP_STATE/router-health-probe-dry-run-fail.json"

"$REPO_DIR/bin/lilhouse-router-health-probe-dry-run" \
  "$TMP_STATE/router-health-probe-plan.json" \
  --results "$TMP_STATE/router-health-probe-results-pass.json" >"$TMP_STATE/router-health-probe-dry-run-pass.json"

python3 -m json.tool "$TMP_STATE/router-health-probe-dry-run-fail.json" >/dev/null
python3 -m json.tool "$TMP_STATE/router-health-probe-dry-run-pass.json" >/dev/null

python3 - "$TMP_STATE/router-health-probe-dry-run-fail.json" "$TMP_STATE/router-health-probe-dry-run-pass.json" <<'PYJSON'
import json, sys
fail = json.load(open(sys.argv[1]))
passed = json.load(open(sys.argv[2]))

assert fail["schema"] == "lilhouse.router_health_probe_dry_run.v1"
assert fail["apply"] is False
assert fail["live_changes"] is False
assert fail["runs_probes"] is False
assert fail["ok"] is True
assert fail["summary"]["all_required_probes_passed"] is False
assert fail["summary"]["rollback_cancel_allowed_by_probes"] is False

assert passed["schema"] == "lilhouse.router_health_probe_dry_run.v1"
assert passed["apply"] is False
assert passed["live_changes"] is False
assert passed["runs_probes"] is False
assert passed["ok"] is True
assert passed["summary"]["all_required_probes_passed"] is True
assert passed["summary"]["rollback_cancel_allowed_by_probes"] is True
assert passed["summary"]["safe_to_cancel_rollback_now"] is False
assert passed["summary"]["safe_to_apply_live"] is False
PYJSON


HEALTH_PROBE_REHEARSAL_OUT="$TMP_STATE/router-health-probe-rehearsal"
"$REPO_DIR/bin/lilhouse-router-health-probe-rehearsal" \
  --out-dir "$HEALTH_PROBE_REHEARSAL_OUT" \
  --health-rehearsal-report "$HEALTH_REHEARSAL_OUT/post-apply-health-rehearsal-report.json" \
  --lan-ip 10.23.0.1 \
  --dns-test-name example.com \
  --wan-test-ip 1.1.1.1 \
  --timeout-seconds 120 >"$TMP_STATE/router-health-probe-rehearsal.json"

python3 -m json.tool "$TMP_STATE/router-health-probe-rehearsal.json" >/dev/null
test -f "$HEALTH_PROBE_REHEARSAL_OUT/health-probe-rehearsal-report.json"
test -f "$HEALTH_PROBE_REHEARSAL_OUT/health-probe-plan.json"

python3 - "$TMP_STATE/router-health-probe-rehearsal.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_health_probe_rehearsal.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["runs_probes"] is False
assert data["ok"] is True
assert data["summary"]["health_probe_plan_ok"] is True
assert data["summary"]["failure_blocks_rollback_cancel"] is True
assert data["summary"]["all_pass_allows_rollback_cancel_by_probes"] is True
assert data["summary"]["safe_to_cancel_rollback_now"] is False
assert data["summary"]["safe_to_apply_live"] is False
PYJSON


"$REPO_DIR/bin/lilhouse-router-live-readiness-review" \
  "$DRESS_OUT/full-dress-rehearsal-report.json" \
  --rollback-rehearsal-report "$ROLLBACK_REHEARSAL_OUT/timed-rollback-rehearsal-report.json" \
  --confirmation-plan-report "$TMP_STATE/router-live-confirmation-plan.json" \
  --confirmation-check-report "$TMP_STATE/router-live-confirmation-check-good.json" \
  --health-rehearsal-report "$HEALTH_REHEARSAL_OUT/post-apply-health-rehearsal-report.json" \
  --service-rehearsal-report "$SERVICE_REHEARSAL_OUT/service-activation-rehearsal-report.json" \
  --health-probe-rehearsal-report "$HEALTH_PROBE_REHEARSAL_OUT/health-probe-rehearsal-report.json" >"$TMP_STATE/router-live-readiness-review-with-health-probe.json"

python3 -m json.tool "$TMP_STATE/router-live-readiness-review-with-health-probe.json" >/dev/null

python3 - "$TMP_STATE/router-live-readiness-review-with-health-probe.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_live_readiness_review.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["ok"] is True
assert data["ready_for_live_apply"] is False
assert data["summary"]["non_live_pipeline_proven"] is True
assert data["summary"]["health_probe_rehearsal_proven"] is True
assert data["summary"]["safe_to_apply_live"] is False
assert data["summary"]["critical_blocker_count"] == 1
assert data["summary"]["high_blocker_count"] >= 3
assert data["summary"]["guarded_blocker_count"] >= 1
assert data["summary"]["proven_blocker_count"] >= 2
assert data["summary"]["only_remaining_critical"] == ["live_apply_root_copy_executor"]

blockers = {item["id"]: item for item in data["remaining_blockers"]}
assert blockers["real_health_probe_executor"]["status"] == "probe_rehearsal_proven"
assert blockers["real_health_probe_executor"]["severity"] == "high"
assert blockers["real_service_activation_executor"]["status"] == "service_rehearsal_proven"
assert blockers["real_service_activation_executor"]["severity"] == "high"
PYJSON


"$REPO_DIR/bin/lilhouse-router-live-apply-executor-plan" \
  "$TMP_STATE/router-live-readiness-review-with-health-probe.json" \
  --confirmation-check-report "$TMP_STATE/router-live-confirmation-check-good.json" >"$TMP_STATE/router-live-apply-executor-plan-no-allow.json"

"$REPO_DIR/bin/lilhouse-router-live-apply-executor-plan" \
  "$TMP_STATE/router-live-readiness-review-with-health-probe.json" \
  --confirmation-check-report "$TMP_STATE/router-live-confirmation-check-good.json" \
  --allow-live-root >"$TMP_STATE/router-live-apply-executor-plan-allow.json"

python3 -m json.tool "$TMP_STATE/router-live-apply-executor-plan-no-allow.json" >/dev/null
python3 -m json.tool "$TMP_STATE/router-live-apply-executor-plan-allow.json" >/dev/null

python3 - "$TMP_STATE/router-live-apply-executor-plan-no-allow.json" "$TMP_STATE/router-live-apply-executor-plan-allow.json" <<'PYJSON'
import json, sys
no_allow = json.load(open(sys.argv[1]))
allow = json.load(open(sys.argv[2]))

assert no_allow["schema"] == "lilhouse.router_live_apply_executor_plan.v1"
assert no_allow["apply"] is False
assert no_allow["live_changes"] is False
assert no_allow["copies_files"] is False
assert no_allow["runs_services"] is False
assert no_allow["ok"] is True
assert no_allow["summary"]["allow_live_root_supplied"] is False
assert no_allow["summary"]["gates_passed"] == no_allow["summary"]["gate_count"] - 1
assert no_allow["summary"]["safe_to_apply_live"] is False

no_allow_gates = {item["id"]: item for item in no_allow["gates"]}
assert no_allow_gates["live_root_explicitly_allowed"]["ok"] is False

assert allow["schema"] == "lilhouse.router_live_apply_executor_plan.v1"
assert allow["apply"] is False
assert allow["live_changes"] is False
assert allow["copies_files"] is False
assert allow["runs_services"] is False
assert allow["ok"] is True
assert allow["summary"]["allow_live_root_supplied"] is True
assert allow["summary"]["gates_passed"] == allow["summary"]["gate_count"]
assert allow["summary"]["executor_policy_defined"] is True
assert allow["summary"]["safe_to_apply_live"] is False

allow_gates = {item["id"]: item for item in allow["gates"]}
assert allow_gates["live_root_explicitly_allowed"]["ok"] is True
PYJSON


"$REPO_DIR/bin/lilhouse-router-final-deploy-runbook" \
  "$TMP_STATE/router-live-apply-executor-plan-allow.json" \
  --out "$TMP_STATE/router-final-deploy-runbook-written.json" >"$TMP_STATE/router-final-deploy-runbook.json"

python3 -m json.tool "$TMP_STATE/router-final-deploy-runbook.json" >/dev/null
python3 -m json.tool "$TMP_STATE/router-final-deploy-runbook-written.json" >/dev/null

python3 - "$TMP_STATE/router-final-deploy-runbook.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_final_deploy_runbook.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["copies_files"] is False
assert data["runs_services"] is False
assert data["ok"] is True
assert data["summary"]["has_live_change_steps"] is True
assert data["summary"]["live_change_steps_are_not_implemented"] is True
assert data["summary"]["rollback_required_before_live_changes"] is True
assert data["summary"]["health_required_before_rollback_cancel"] is True
assert data["summary"]["safe_to_apply_live"] is False
PYJSON


RC_SOURCE="$TMP_STATE/router-rc-source"
RC_STAGE="$TMP_STATE/router-rc-stage"
RC_APPLY="$TMP_STATE/router-rc-apply"
RC_UNITS="$TMP_STATE/router-rc-units"
RC_OUT="$TMP_STATE/router-rc-out"

mkdir -p "$RC_SOURCE/etc/pihole" "$RC_SOURCE/etc/systemd/system" "$RC_SOURCE/etc/sysctl.d"
echo "# fake nftables" > "$RC_SOURCE/etc/nftables.conf"
echo "net.ipv4.ip_forward=1" > "$RC_SOURCE/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
echo "# fake pihole" > "$RC_SOURCE/etc/pihole/test.conf"
echo "# fake current-state service" > "$RC_SOURCE/etc/systemd/system/lilhouse-current-state.service"

"$REPO_DIR/bin/lilhouse-router-release-candidate" \
  --out-dir "$RC_OUT" \
  --source-root "$RC_SOURCE" \
  --stage-root "$RC_STAGE" \
  --apply-target-root "$RC_APPLY" \
  --unit-target-root "$RC_UNITS" \
  --wan eth0 \
  --lan eth1 \
  --lan-ip 10.23.0.1 \
  --dns-test-name example.com \
  --wan-test-ip 1.1.1.1 \
  --timeout-seconds 120 \
  --rollback-timeout-minutes 5 \
  --enable-cake \
  --enable-ipv6 >"$TMP_STATE/router-release-candidate.json"

python3 -m json.tool "$TMP_STATE/router-release-candidate.json" >/dev/null
test -f "$RC_OUT/release-candidate-report.json"
test -f "$RC_OUT/final-deploy-runbook.json"
test -f "$RC_OUT/live-apply-executor-plan.json"
test -f "$RC_OUT/live-readiness-review.json"

python3 - "$TMP_STATE/router-release-candidate.json" <<'PYJSON'
import json, sys
data = json.load(open(sys.argv[1]))
assert data["schema"] == "lilhouse.router_release_candidate.v1"
assert data["apply"] is False
assert data["live_changes"] is False
assert data["copies_files"] is False
assert data["runs_services"] is False
assert data["ok"] is True
assert data["summary"]["checks_passed"] == data["summary"]["checks_total"]
assert data["summary"]["artifact_count"] >= 10
assert data["summary"]["non_live_pipeline_proven"] is True
assert data["summary"]["ready_for_live_apply"] is False
assert data["summary"]["safe_to_apply_live"] is False
PYJSON


"$REPO_DIR/bin/lilhouse-router-release-candidate-summary" \
  "$RC_OUT/release-candidate-report.json" >"$TMP_STATE/router-release-candidate-summary.txt"

"$REPO_DIR/bin/lilhouse-router-release-candidate-summary" \
  "$RC_OUT/release-candidate-report.json" \
  --json >"$TMP_STATE/router-release-candidate-summary-with-json.txt"

grep -q "LilHouse Router Release Candidate" "$TMP_STATE/router-release-candidate-summary.txt"
grep -q "Status: PASS" "$TMP_STATE/router-release-candidate-summary.txt"
grep -q "Checks: 12/12" "$TMP_STATE/router-release-candidate-summary.txt"
grep -q "Safe to apply live: NO" "$TMP_STATE/router-release-candidate-summary.txt"
grep -q "Ready for live apply: NO" "$TMP_STATE/router-release-candidate-summary.txt"

python3 - "$TMP_STATE/router-release-candidate-summary-with-json.txt" <<'PYJSON'
import json, sys
text = open(sys.argv[1]).read()
start = text.rfind('\n{')
if start == -1:
    raise SystemExit("summary JSON object not found")
data = json.loads(text[start + 1:])
assert data["schema"] == "lilhouse.router_release_candidate_summary.v1"
assert data["ok"] is True
assert data["checks_passed"] == data["checks_total"]
assert data["non_live_pipeline_proven"] is True
assert data["ready_for_live_apply"] is False
assert data["safe_to_apply_live"] is False
assert data["runbook"]
assert data["readiness_review"]
assert data["executor_plan"]
PYJSON

CAKE_WIZARD_OUT="$TMP_STATE/install-router-wizard-cake"
"$REPO_DIR/bin/lilhouse-router-wizard" \
  --out-dir "$CAKE_WIZARD_OUT" \
  --wan eth0 \
  --lan eth1 \
  --enable-cake >/dev/null

test -f "$CAKE_WIZARD_OUT/preview/etc/lilhouse/cake.env"
grep -q "LILHOUSE_CAKE_ENABLED=true" "$CAKE_WIZARD_OUT/preview/etc/lilhouse/cake.env"
grep -q "LILHOUSE_CAKE_WAN=eth0" "$CAKE_WIZARD_OUT/preview/etc/lilhouse/cake.env"
grep -q "LILHOUSE_CAKE_IFB=ifb0" "$CAKE_WIZARD_OUT/preview/etc/lilhouse/cake.env"
grep -q "LILHOUSE_CAKE_QDISC=cake" "$CAKE_WIZARD_OUT/preview/etc/lilhouse/cake.env"
"$REPO_DIR/bin/lilhouse-router-preview-validate" "$CAKE_WIZARD_OUT/preview" >/dev/null

IPV6_WIZARD_OUT="$TMP_STATE/install-router-wizard-ipv6"
"$REPO_DIR/bin/lilhouse-router-wizard" \
  --out-dir "$IPV6_WIZARD_OUT" \
  --wan eth0 \
  --lan eth1 \
  --enable-ipv6 >/dev/null

test -f "$IPV6_WIZARD_OUT/preview/etc/lilhouse/ipv6-plan.env"
grep -q "net.ipv6.conf.all.forwarding=1" "$IPV6_WIZARD_OUT/preview/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
grep -q "LILHOUSE_IPV6_ENABLED=true" "$IPV6_WIZARD_OUT/preview/etc/lilhouse/ipv6-plan.env"
grep -q "LILHOUSE_IPV6_NAT66=false" "$IPV6_WIZARD_OUT/preview/etc/lilhouse/ipv6-plan.env"
grep -q "LILHOUSE_IPV6_INBOUND_SSH=explicit_opt_in_only" "$IPV6_WIZARD_OUT/preview/etc/lilhouse/ipv6-plan.env"
"$REPO_DIR/bin/lilhouse-router-preview-validate" "$IPV6_WIZARD_OUT/preview" >/dev/null

FULL_WIZARD_OUT="$TMP_STATE/install-router-wizard-full"
"$REPO_DIR/bin/lilhouse-router-wizard" \
  --out-dir "$FULL_WIZARD_OUT" \
  --wan eth0 \
  --lan eth1 \
  --enable-cake \
  --enable-ipv6 >"$TMP_STATE/install-router-wizard-full.out"

grep -q "Preview validation passed." "$TMP_STATE/install-router-wizard-full.out"
test -f "$FULL_WIZARD_OUT/preview/etc/lilhouse/cake.env"
test -f "$FULL_WIZARD_OUT/preview/etc/lilhouse/ipv6-plan.env"
grep -q "Enable CAKE: 1" "$FULL_WIZARD_OUT/preview/MANIFEST.txt"
grep -q "Enable IPv6: 1" "$FULL_WIZARD_OUT/preview/MANIFEST.txt"
"$REPO_DIR/bin/lilhouse-router-preview-validate" "$FULL_WIZARD_OUT/preview" >/dev/null


echo
echo "== run read-only live health probe command in safe test mode =="

HEALTH_PROBE_RUN_JSON="$TMP_STATE/health-probe-run.json"
set +e
"$REPO_DIR/bin/lilhouse-router-health-probe-run" >"$TMP_STATE/health-probe-run-refusal.json"
REFUSAL_RC=$?
set -e
test "$REFUSAL_RC" -eq 2

"$REPO_DIR/bin/lilhouse-router-health-probe-run" \
  --allow-live-probes \
  --wan lo \
  --lan lo \
  --lan-ip 127.0.0.1 \
  --dns-test-name localhost \
  --wan-test-ip 127.0.0.1 \
  --timeout-seconds 1 \
  --service systemd-networkd \
  --out "$HEALTH_PROBE_RUN_JSON" >/dev/null

python3 - "$HEALTH_PROBE_RUN_JSON" <<'PYJSON'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
assert report["schema"] == "lilhouse.router_health_probe_run.v1"
assert report["safety"]["apply"] is False
assert report["safety"]["live_changes"] is False
assert report["safety"]["copies_files"] is False
assert report["safety"]["runs_services"] is False
assert report["safety"]["writes_config"] is False
assert report["safety"]["reads_live_state"] is True
assert report["summary"]["safe_to_apply_live"] is False
assert report["summary"]["safe_to_cancel_rollback"] is False
PYJSON


echo
echo "== run live preflight command against safe reports =="

LIVE_PREFLIGHT_RC="$TMP_STATE/live-preflight-release-candidate.json"
cat > "$LIVE_PREFLIGHT_RC" <<'JSON'
{
  "schema": "lilhouse.router_release_candidate.v1",
  "ok": true,
  "summary": {
    "checks_passed": 12,
    "checks_total": 12,
    "non_live_pipeline_proven": true,
    "ready_for_live_apply": false,
    "safe_to_apply_live": false
  },
  "safety": {
    "apply": false,
    "live_changes": false,
    "copies_files": false,
    "runs_services": false
  }
}
JSON

LIVE_PREFLIGHT_JSON="$TMP_STATE/live-preflight.json"

"$REPO_DIR/bin/lilhouse-router-live-preflight" \
  --health-probe-report "$HEALTH_PROBE_RUN_JSON" \
  --release-candidate-report "$LIVE_PREFLIGHT_RC" \
  --recovery-ack "I have local console access and accept temporary network interruption" \
  --out "$LIVE_PREFLIGHT_JSON" >/dev/null

python3 - "$LIVE_PREFLIGHT_JSON" <<'PYJSON'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
assert report["schema"] == "lilhouse.router_live_preflight.v1"
assert report["ok"] is True
assert report["safety"]["apply"] is False
assert report["safety"]["live_changes"] is False
assert report["safety"]["copies_files"] is False
assert report["safety"]["runs_services"] is False
assert report["safety"]["writes_config"] is False
assert report["summary"]["ready_for_live_backup"] is True
assert report["summary"]["ready_for_live_apply"] is False
assert report["summary"]["safe_to_apply_live"] is False
assert report["summary"]["next_gate"] == "live-backup"
PYJSON

echo "Smoke test passed."
