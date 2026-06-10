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
test -x "$TMP_ROOT/usr/local/bin/lilhouse-router-plan"
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

"$REPO_DIR/bin/lilhouse-router-plan" \
  --wan wan0 \
  --lan lan0 \
  --lan-ip 10.23.0.1 \
  --subnet 10.23.0.0/24 \
  --dhcp-start 10.23.0.100 \
  --dhcp-end 10.23.0.200 \
  --output "$TMP_STATE/router-plan.json" >/dev/null

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
test -s "$TMP_STATE/router-plan.json"

echo
echo "Smoke test passed."
