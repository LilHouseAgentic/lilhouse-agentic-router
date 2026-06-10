#!/usr/bin/env bash
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

MODE=""
YES=0
WAN="eth0"
LAN="eth1"
WORK_DIR="/tmp/lilhouse-first-install"
OUT=""

usage() {
  cat <<EOF
LilHouse Router easy installer

VM/customer-simulation mode:
  ./easy-install.sh --vm --yes

Options:
  --vm              Run VM first-install acceptance mode
  --yes             Required confirmation
  --wan IFACE       WAN interface name for generated preview, default: eth0
  --lan IFACE       LAN interface name for generated preview, default: eth1
  --work-dir DIR    Work/report directory, default: /tmp/lilhouse-first-install
  --out FILE        Write final JSON report to FILE

Notes:
  VM mode is for first-install testing only.
  VM NIC bypass is not valid for live router approval.
  This command does not execute live router deployment.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --vm)
      MODE="vm"
      shift
      ;;
    --yes)
      YES=1
      shift
      ;;
    --wan)
      WAN="${2:?missing value for --wan}"
      shift 2
      ;;
    --lan)
      LAN="${2:?missing value for --lan}"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="${2:?missing value for --work-dir}"
      shift 2
      ;;
    --out)
      OUT="${2:?missing value for --out}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$MODE" != "vm" ]; then
  echo "ERROR: easy installer currently supports only --vm first-install acceptance mode" >&2
  echo "Real live install remains intentionally separate and guarded." >&2
  usage >&2
  exit 2
fi

if [ "$YES" -ne 1 ]; then
  echo "ERROR: refusing to run easy installer without --yes" >&2
  exit 2
fi

BUNDLE="$REPO_DIR/bin/lilhouse-router-vm-readiness-bundle"
if [ ! -x "$BUNDLE" ]; then
  echo "ERROR: missing executable: $BUNDLE" >&2
  exit 2
fi

mkdir -p "$WORK_DIR"

if [ -z "$OUT" ]; then
  OUT="$WORK_DIR/easy-install-report.json"
fi

VM_BYPASS_KEY="I understand VM NIC bypass is not valid for live router approval"

echo "LilHouse easy installer"
echo "mode=vm-first-install-acceptance"
echo "repo=$REPO_DIR"
echo "work_dir=$WORK_DIR"
echo "wan=$WAN"
echo "lan=$LAN"
echo
echo "Running VM readiness bundle..."

"$BUNDLE" \
  --work-dir "$WORK_DIR/vm-readiness-bundle" \
  --wan "$WAN" \
  --lan "$LAN" \
  --vm-nic-bypass-key "$VM_BYPASS_KEY" \
  --yes \
  --out "$OUT" >/tmp/lilhouse-easy-install-last.json

python3 - "$OUT" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
summary = report.get("summary", {})
safety = report.get("safety", {})

print()
print("=== LilHouse easy installer result ===")
print(f"ok={report.get('ok')}")
print(f"vm_bundle_complete={summary.get('vm_bundle_complete')}")
print(f"valid_for_live_router_approval={summary.get('valid_for_live_router_approval')}")
print(f"ready_for_live_apply={summary.get('ready_for_live_apply')}")
print(f"safe_to_apply_live={summary.get('safe_to_apply_live')}")
print(f"vm_only={safety.get('vm_only')}")
print(f"vm_nic_bypass_valid_for_live={safety.get('vm_nic_bypass_valid_for_live')}")
print()
print(f"report={sys.argv[1]}")
PY
