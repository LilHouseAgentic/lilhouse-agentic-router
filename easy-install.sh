#!/usr/bin/env bash
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

MODE=""
YES=0
THROWAWAY_VM=0
WAN=""
LAN=""
WORK_DIR="/tmp/lilhouse-first-install"
OUT=""
CAKE=""
AI_AGENT=""
MOBILE_ALERTS=""

VM_BYPASS_KEY="I understand VM NIC bypass is not valid for live router approval"
LIVE_OPERATOR_PHRASE="I understand this may temporarily interrupt my network"

usage() {
  cat <<EOF
LilHouse Router easy installer

Interactive public first-run:
  ./easy-install.sh

Safe VM/customer simulation:
  ./easy-install.sh --vm --yes

Full throwaway VM install test:
  ./easy-install.sh --vm-live --yes --i-am-in-a-throwaway-vm

Options:
  --wizard          Run guided first-run wizard
  --vm              Run VM first-install simulation only
  --vm-live         Actually install/activate into / on a disposable VM
  --i-am-in-a-throwaway-vm
                    Required with --vm-live
  --yes             Non-interactive confirmation
  --wan IFACE       WAN interface
  --lan IFACE       LAN interface
  --cake yes|no     Enable CAKE/SQM in generated plan
  --ai yes|no       Enable local agent/AI planning in generated plan
  --mobile-alerts yes|no
                    Enable mobile push alert config in generated plan
  --work-dir DIR    Work/report directory, default: /tmp/lilhouse-first-install
  --out FILE        Write final JSON report to FILE

Safety:
  --vm is safe simulation only.
  --vm-live really installs/activates into / and is only for disposable VMs.
  Real router installs remain separate and guarded.
EOF
}

is_tty() {
  [ -t 0 ] && [ -t 1 ]
}

ask_default() {
  prompt="$1"
  default="$2"
  var=""
  printf "%s [%s]: " "$prompt" "$default" >&2
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
      *) echo "Please answer yes or no." >&2 ;;
    esac
  done
}

detect_interfaces() {
  echo
  echo "Detected network interfaces:"
  ip -br link | awk '{print "  " $1 "  " $2}' || true
  echo
}

install_base_prereqs() {
  echo
  echo "Installing base prerequisites..."

  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y \
      ca-certificates \
      curl \
      iproute2 \
      nftables \
      procps \
      python3 \
      systemd
  else
    echo "No apt-get found; skipping package install."
  fi
}

install_lilhouse_core() {
  echo
  echo "Installing LilHouse core files..."

  "$REPO_DIR/install.sh" \
    --mode observe-only \
    --no-systemd
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
        "vm_simulation": mode == "vm",
        "throwaway_vm_live_install": mode == "vm-live",
        "real_router_live_install": False,
        "vm_nic_bypass_valid_for_live": False,
    },
    "work_dir": work_dir,
}
Path(path).parent.mkdir(parents=True, exist_ok=True)
Path(path).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

print_result() {
  report="$1"
  answers="$2"
  python3 - "$report" "$answers" <<'PY'
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
print(f"schema={report.get('schema')}")
print(f"mode={answers.get('mode')}")
for key in [
    "vm_bundle_complete",
    "deployment_chain_simulated_complete",
    "ready_for_live_apply",
    "safe_to_apply_live",
    "valid_for_live_router_approval",
]:
    if key in summary:
        print(f"{key}={summary.get(key)}")
for key in [
    "vm_only",
    "vm_nic_bypass_valid_for_live",
    "live_changes",
    "apply",
    "plan_only",
]:
    if key in safety:
        print(f"{key}={safety.get(key)}")

appliance = report.get("appliance_prep", {})
if appliance:
    app_summary = report.get("summary", {})
    print()
    print("Appliance prep:")
    print(f"  appliance_prep_ok={app_summary.get('appliance_prep_ok')}")
    print(f"  appliance_cake_active={app_summary.get('appliance_cake_active')}")
    print(f"  appliance_dns_active={app_summary.get('appliance_dns_active')}")
    print(f"  appliance_web_lan_bound={app_summary.get('appliance_web_lan_bound')}")
    print(f"  appliance_web_wildcard_disabled={app_summary.get('appliance_web_wildcard_disabled')}")
    print(f"  appliance_firewall_active={app_summary.get('appliance_firewall_active')}")
    print(f"  appliance_firewall_hardened={app_summary.get('appliance_firewall_hardened')}")
    print(f"  appliance_telemetry_active={app_summary.get('appliance_telemetry_active')}")

print()
print("Selected features:")
for name, enabled in answers.get("features", {}).items():
    print(f"  {name}={enabled}")
print()
print(f"answers={sys.argv[2]}")
print(f"report={sys.argv[1]}")
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
    --vm-live)
      MODE="vm-live"
      shift
      ;;
    --i-am-in-a-throwaway-vm)
      THROWAWAY_VM=1
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

  detect_interfaces

  echo "Install target:"
  echo "  1) VM / first-install simulation"
  echo "  2) Full throwaway VM install test"
  echo "  3) Real router dry-run only - not exposed yet"
  echo
  choice="$(ask_default "Choose mode" "1")"
  case "$choice" in
    1) MODE="vm" ;;
    2)
      MODE="vm-live"
      THROWAWAY_VM=1
      ;;
    3)
      echo "Real router dry-run mode will be added after VM-live install testing."
      MODE="vm"
      ;;
    *)
      echo "Unknown choice. Using VM/simulation mode."
      MODE="vm"
      ;;
  esac

WAN_DEFAULT="eth0"
LAN_DEFAULT="eth1"
IFACE_DETECT="$REPO_DIR/bin/lilhouse-router-interface-detect"

if [ -x "$IFACE_DETECT" ]; then
  DETECT_OUT="$("$IFACE_DETECT" --shell 2>/dev/null || true)"

  while IFS='=' read -r key value; do
    value="${value#\'}"
    value="${value%\'}"
    case "$key" in
      LILHOUSE_WAN_GUESS) LILHOUSE_WAN_GUESS="$value" ;;
      LILHOUSE_LAN_GUESS) LILHOUSE_LAN_GUESS="$value" ;;
      LILHOUSE_IFACE_DETECT_OK) LILHOUSE_IFACE_DETECT_OK="$value" ;;
    esac
  done <<EOF_DETECT
$DETECT_OUT
EOF_DETECT

  if [ "${LILHOUSE_IFACE_DETECT_OK:-no}" = "yes" ]; then
    WAN_DEFAULT="${LILHOUSE_WAN_GUESS:-$WAN_DEFAULT}"
    LAN_DEFAULT="${LILHOUSE_LAN_GUESS:-$LAN_DEFAULT}"

    echo
    echo "Auto-detected likely router layout:"
    echo "  WAN guess: $WAN_DEFAULT"
    echo "  LAN guess: $LAN_DEFAULT"
    echo "You can override these if they are wrong."
  fi
fi

WAN="$(ask_default "WAN interface" "${WAN:-$WAN_DEFAULT}")"
LAN="$(ask_default "LAN interface" "${LAN:-$LAN_DEFAULT}")"
  CAKE="yes"
  AI_AGENT="yes"
  MOBILE_ALERTS="$(ask_yes_no "Configure mobile push alerts now? You can choose no and set them up after install." "${MOBILE_ALERTS:-no}")"

  echo
  echo "Summary:"
  echo "  mode=$MODE"
  echo "  wan=$WAN"
  echo "  lan=$LAN"
  echo "  appliance_stack=full_required"
  echo "  cake=required"
  echo "  dns=required_pihole_unbound"
  echo "  ai_agent=required_core_agent"
  echo "  mobile_alerts=$MOBILE_ALERTS"
  echo "  work_dir=$WORK_DIR"
  echo

  if [ "$MODE" = "vm-live" ]; then
    confirm="$(ask_yes_no "Continue and install into / on this disposable VM?" "no")"
  else
    confirm="$(ask_yes_no "Continue with safe dry-run/simulation?" "yes")"
  fi

  if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 2
  fi

  YES=1
fi

if [ "$MODE" != "vm" ] && [ "$MODE" != "vm-live" ]; then
  echo "ERROR: easy installer currently supports --vm and --vm-live only" >&2
  exit 2
fi

if [ "$YES" -ne 1 ]; then
  echo "ERROR: refusing to run easy installer without --yes or interactive confirmation" >&2
  exit 2
fi

if [ "$MODE" = "vm-live" ] && [ "$THROWAWAY_VM" -ne 1 ]; then
  echo "ERROR: --vm-live requires --i-am-in-a-throwaway-vm" >&2
  exit 2
fi

WAN="${WAN:-eth0}"
LAN="${LAN:-eth1}"
CAKE="${CAKE:-yes}"
AI_AGENT="${AI_AGENT:-yes}"
MOBILE_ALERTS="${MOBILE_ALERTS:-no}"

BUNDLE="$REPO_DIR/bin/lilhouse-router-vm-readiness-bundle"
LIVE_ORCH="$REPO_DIR/bin/lilhouse-router-live-orchestrator"
APPLIANCE_PREP_REPORTER="$REPO_DIR/bin/lilhouse-router-appliance-prep-report"
APPLIANCE_INSTALL="$REPO_DIR/bin/lilhouse-router-appliance-install"

test -x "$BUNDLE" || { echo "ERROR: missing executable: $BUNDLE" >&2; exit 2; }
test -x "$LIVE_ORCH" || { echo "ERROR: missing executable: $LIVE_ORCH" >&2; exit 2; }

mkdir -p "$WORK_DIR"

if [ -z "$OUT" ]; then
  if [ "$MODE" = "vm-live" ]; then
    OUT="$WORK_DIR/vm-live-install-report.json"
  else
    OUT="$WORK_DIR/easy-install-report.json"
  fi
fi

ANSWERS="$WORK_DIR/easy-install-answers.json"
write_answers_json "$ANSWERS"

echo
echo "LilHouse easy installer"
echo "mode=$MODE"
echo "repo=$REPO_DIR"
echo "work_dir=$WORK_DIR"
echo "wan=$WAN"
echo "lan=$LAN"
echo "cake=$CAKE"
echo "ai_agent=$AI_AGENT"
echo "mobile_alerts=$MOBILE_ALERTS"

if [ "$MODE" = "vm" ]; then
  echo
  echo "Running VM readiness bundle..."

  "$BUNDLE" \
    --work-dir "$WORK_DIR/vm-readiness-bundle" \
    --wan "$WAN" \
    --lan "$LAN" \
    --vm-nic-bypass-key "$VM_BYPASS_KEY" \
    --yes \
    --out "$OUT" >/tmp/lilhouse-easy-install-last.json

  print_result "$OUT" "$ANSWERS"
  exit 0
fi

echo
echo "WARNING: --vm-live installs/activates into / on this disposable VM."

echo
echo "Resetting VM-live work reports..."
rm -rf "$WORK_DIR/vm-live-prep" "$WORK_DIR/vm-live-work" "$WORK_DIR/vm-live-backup"
rm -f "$WORK_DIR/vm-live-install-report.json"

echo
echo "Step 1/3: preparing full LilHouse appliance stack..."
"$APPLIANCE_INSTALL" \
  --prepare-only \
  --yes \
  --wan "$WAN" \
  --lan "$LAN"

echo
echo "Step 2/3: generating VM preview/preflight..."
PREP_WORK="$WORK_DIR/vm-live-prep"
PREP_REPORT="$WORK_DIR/vm-live-prep-report.json"

"$BUNDLE" \
  --work-dir "$PREP_WORK" \
  --wan "$WAN" \
  --lan "$LAN" \
  --vm-nic-bypass-key "$VM_BYPASS_KEY" \
  --yes \
  --out "$PREP_REPORT" >/tmp/lilhouse-easy-install-vm-live-prep-last.json

echo
echo "Step 3/3: executing guarded live chain against / on throwaway VM..."

"$LIVE_ORCH" \
  --preflight-report "$PREP_WORK/vm-preflight.json" \
  --preview-dir "$PREP_WORK/wizard/preview" \
  --backup-dir "$WORK_DIR/vm-live-backup" \
  --work-dir "$WORK_DIR/vm-live-work" \
  --target-root "/" \
  --execute \
  --yes \
  --allow-live-root \
  --operator-phrase "$LIVE_OPERATOR_PHRASE" \
  --out "$OUT"

"$APPLIANCE_PREP_REPORTER" --report "$OUT" --wan "$WAN" --lan "$LAN"
print_result "$OUT" "$ANSWERS"
