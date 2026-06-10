#!/usr/bin/env bash
set -euo pipefail

: "${LILHOUSE_CONFIG:=/etc/lilhouse/lilhouse.toml}"
: "${LILHOUSE_STATE_DIR:=/var/lib/lilhouse}"
: "${LILHOUSE_RUNTIME_DIR:=/run/lilhouse}"
: "${LILHOUSE_LOG_DIR:=/var/log/lilhouse}"

lilhouse_ensure_dirs() {
  mkdir -p "$LILHOUSE_STATE_DIR" "$LILHOUSE_RUNTIME_DIR" "$LILHOUSE_LOG_DIR"
}

lilhouse_json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n"))[1:-1])'
}

lilhouse_now_iso() {
  date -Is
}
