#!/usr/bin/env bash
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

MODE=""
YES=0
WAN=""
LAN=""
WORK_DIR="/tmp/lilhouse-first-install"
OUT=""
CAKE=""
AI_AGENT=""
MOBILE_ALERTS=""

VM_BYPASS_KEY="I understand VM NIC bypass is not valid for live router approval"

usage() {
  cat <<EOF
LilHouse Router easy installer

Interactive public first-run:
  ./easy-install.sh

Non-interactive VM/customer-simulation mode:
  ./easy-install.sh --vm --yes

Options:
  --wizard          Run guided first-run wizard
  --vm              Run VM first-install acceptance mode
  --yes             Non-interactive confirmation
  --wan IFACE       WAN interface
  --lan IFACE       LAN interface
  --cake yes|no     Enable CAKE/SQM in generated plan
  --ai yes|no       Enable local agent/AI planning in generated plan
  --mobile-alerts yes|no Enable mobile push alert config in generated plan
  --work-dir DIR    Work/report directory, default: /tmp/lilhouse-first-install
  --out FILE        Write final JSON report to FILE

Safety:
  This installer defaults to dry-run / simulation.
  VM mode is for first-install testing only.
  VM NIC bypass is not valid for live router approval.
  This command does not execute live router deployment.
EOF
}

is_tty() {
  [ -t 0 ] && [ -t 1 ]
}

ask_default() {
  prompt="$1"
  default="$2"
  var=""
  printf "%s [%s]: " "$prompt" "$default"
  read -r var || var=""
  if [ -z "$var" ]; then
    var="$default"
  fi
  printf "%s" "$var"
}

ask_yes_no() {
  prompt="$1"
  default="$2"
  while true; do
    ans="$(ask_default "$prompt" "$default")"
    case "$ans" in
      y|Y|yes|YES|Yes) printf "yes"; return 0 ;;
      n|N|no|NO|No) printf "no"; return 0 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

detect_interfaces() {
  echo
  echo "Detected network interfaces:"
  ip -br link | awk '{print "  " $1 "  " $2}' || true
  echo
}

write_answers_json() {
  answers="$1"
  python3 - "$answers" "$MODE" "$WAN" "$LAN" "$CAKE" "$AI_AGENT" "$MOBILE_ALERTS" "$WORK_DIR" <<'PY'
import json
import sys
from pathlib import Path
from datetime import datetime, timezone

path, mode, wan, lan, cake, ai_agent, mobile_alerts, work_dir = sys.argv[1:]
data = {
    "schema": "lilhouse.easy_install_answers.v1",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "mode": mode,
    "wan": wan,
    "lan": lan,
    "features": {
        "cake": cake == "yes",
        "ai_agent": ai_agent == "yes",
        "mobile_alerts": mobile_alerts == "yes",
    },
    "safety": {
        "live_apply": False,
        "dry_run_first": True,
        "vm_nic_bypass_valid_for_live": False,
    },
    "work_dir": work_dir,
}
Path(path).parent.mkdir(parents=True, exist_ok=True)
Path(path).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(path)
PY
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --wizard)
      MODE="wizard"
      shift
      ;;
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
    --cake)
      CAKE="${2:?missing value for --cake}"
      shift 2
      ;;
    --ai)
      AI_AGENT="${2:?missing value for --ai}"
      shift 2
      ;;
    --mobile-alerts)
      MOBILE_ALERTS="${2:?missing value for --mobile-alerts}"
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

if [ -z "$MODE" ]; then
  if is_tty; then
    MODE="wizard"
  else
    echo "ERROR: no mode supplied and not running interactively" >&2
    usage >&2
    exit 2
  fi
fi

if [ "$MODE" = "wizard" ]; then
  if ! is_tty; then
    echo "ERROR: --wizard requires an interactive terminal" >&2
    exit 2
  fi

  echo
  echo "======================================"
  echo " LilHouse Router first-run installer"
  echo "======================================"
  echo
  echo "This will NOT apply live router changes."
  echo "It creates a dry-run/simulation report first."
  echo

  detect_interfaces

  echo "Install target:"
  echo "  1) VM / first-install simulation"
  echo "  2) Real router dry-run only"
  echo
  choice="$(ask_default "Choose mode" "1")"
  case "$choice" in
    1) MODE="vm" ;;
    2)
      echo "Real router dry-run mode will be added next."
      echo "For now, using VM/simulation mode so this remains safe."
      MODE="vm"
      ;;
    *)
      echo "Unknown choice. Using VM/simulation mode."
      MODE="vm"
      ;;
  esac

  WAN="$(ask_default "WAN interface" "${WAN:-eth0}")"
  LAN="$(ask_default "LAN interface" "${LAN:-eth1}")"
  CAKE="$(ask_yes_no "Enable CAKE/SQM in generated plan?" "${CAKE:-yes}")"
  AI_AGENT="$(ask_yes_no "Enable local AI/agent planning in generated plan?" "${AI_AGENT:-yes}")"
  MOBILE_ALERTS="$(ask_yes_no "Enable mobile push alerts in generated plan?" "${MOBILE_ALERTS:-no}")"

  echo
  echo "Summary:"
  echo "  mode=$MODE"
  echo "  wan=$WAN"
  echo "  lan=$LAN"
  echo "  cake=$CAKE"
  echo "  ai_agent=$AI_AGENT"
  echo "  mobile_alerts=$MOBILE_ALERTS"
  echo "  work_dir=$WORK_DIR"
  echo
  confirm="$(ask_yes_no "Continue with safe dry-run/simulation?" "yes")"
  if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 2
  fi
  YES=1
fi

if [ "$MODE" != "vm" ]; then
  echo "ERROR: easy installer currently only executes VM/simulation mode" >&2
  echo "Real router dry-run and live install remain intentionally separate and guarded." >&2
  exit 2
fi

if [ "$YES" -ne 1 ]; then
  echo "ERROR: refusing to run easy installer without --yes or interactive confirmation" >&2
  exit 2
fi

WAN="${WAN:-eth0}"
LAN="${LAN:-eth1}"
CAKE="${CAKE:-yes}"
AI_AGENT="${AI_AGENT:-yes}"
MOBILE_ALERTS="${MOBILE_ALERTS:-no}"

BUNDLE="$REPO_DIR/bin/lilhouse-router-vm-readiness-bundle"
if [ ! -x "$BUNDLE" ]; then
  echo "ERROR: missing executable: $BUNDLE" >&2
  exit 2
fi

mkdir -p "$WORK_DIR"

if [ -z "$OUT" ]; then
  OUT="$WORK_DIR/easy-install-report.json"
fi

ANSWERS="$WORK_DIR/easy-install-answers.json"
write_answers_json "$ANSWERS" >/dev/null

echo
echo "LilHouse easy installer"
echo "mode=vm-first-install-acceptance"
echo "repo=$REPO_DIR"
echo "work_dir=$WORK_DIR"
echo "wan=$WAN"
echo "lan=$LAN"
echo "cake=$CAKE"
echo "ai_agent=$AI_AGENT"
echo "mobile_alerts=$MOBILE_ALERTS"
echo
echo "Running VM readiness bundle..."

"$BUNDLE" \
  --work-dir "$WORK_DIR/vm-readiness-bundle" \
  --wan "$WAN" \
  --lan "$LAN" \
  --vm-nic-bypass-key "$VM_BYPASS_KEY" \
  --yes \
  --out "$OUT" >/tmp/lilhouse-easy-install-last.json

python3 - "$OUT" "$ANSWERS" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
answers = json.loads(Path(sys.argv[2]).read_text())
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
print("Selected features:")
for name, enabled in answers.get("features", {}).items():
    print(f"  {name}={enabled}")
print()
print(f"answers={sys.argv[2]}")
print(f"report={sys.argv[1]}")
PY
