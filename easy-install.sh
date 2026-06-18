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
LAN_CIDR=""
LAN_IP=""
LAN_NET=""
DHCP_START=""
DHCP_END=""
CAKE=""
CAKE_PROFILE=""
CAKE_DOWN=""
CAKE_UP=""
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
  --lan-cidr CIDR   LAN gateway CIDR, bypasses Auto LAN subnet picker
  --dhcp-start IP    DHCP start, default 192.168.2.100
  --dhcp-end IP      DHCP end, default 192.168.2.200
  --cake yes|no     Enable CAKE/SQM in generated plan
  --cake-profile NAME
                    CAKE profile: conservative, fast, satellite, custom
  --cake-down RATE  CAKE download rate, for example 100mbit
  --cake-up RATE    CAKE upload rate, for example 20mbit
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

iface_exists() {
  ip link show "$1" >/dev/null 2>&1
}

normalise_mbit() {
  value="$1"
  value="${value%mbit}"
  value="${value%Mbit}"
  value="${value%mbps}"
  value="${value%Mbps}"
  printf "%smbit" "$value"
}

set_lan_from_cidr() {
  LAN_CIDR="$1"
  LAN_IP="${LAN_CIDR%/*}"
  LAN_NET="$(python3 -c 'import ipaddress,sys; print(ipaddress.ip_interface(sys.argv[1]).network)' "$LAN_CIDR")"

  prefix="$(python3 -c 'import ipaddress,sys; i=ipaddress.ip_interface(sys.argv[1]); print(".".join(str(i.ip).split(".")[:3]))' "$LAN_CIDR")"
  DHCP_START="${DHCP_START:-${prefix}.100}"
  DHCP_END="${DHCP_END:-${prefix}.200}"
}

set_lan_defaults() {
  set_lan_from_cidr "${LAN_CIDR:-192.168.2.1/24}"
}

detect_wan_ipv4_cidr() {
  ip -4 -o addr show dev "$1" scope global 2>/dev/null | awk '{print $4; exit}'
}

networks_overlap() {
  python3 - "$1" "$2" <<'PY_NET'
import ipaddress
import sys
a = ipaddress.ip_interface(sys.argv[1]).network
b = ipaddress.ip_interface(sys.argv[2]).network
sys.exit(0 if a.overlaps(b) else 1)
PY_NET
}

validate_192168_24_cidr() {
  python3 - "$1" <<'PY_LAN_VALIDATE'
import ipaddress
import sys

try:
    iface = ipaddress.ip_interface(sys.argv[1])
except Exception:
    sys.exit(1)

allowed = ipaddress.ip_network("192.168.0.0/16")
if iface.version != 4:
    sys.exit(1)
if iface.network.prefixlen != 24:
    sys.exit(1)
if iface.ip not in allowed:
    sys.exit(1)

sys.exit(0)
PY_LAN_VALIDATE
}

auto_lan_cidr() {
  wan_cidr="$1"
  for candidate in \
    "192.168.2.1/24" \
    "192.168.50.1/24" \
    "192.168.88.1/24" \
    "192.168.100.1/24" \
    "192.168.10.1/24" \
    "192.168.20.1/24"
  do
    if [ -z "$wan_cidr" ] || ! networks_overlap "$wan_cidr" "$candidate"; then
      printf "%s" "$candidate"
      return 0
    fi
  done

  printf "%s" "192.168.50.1/24"
}

choose_lan_subnet_interactive() {
  WAN_IPV4_CIDR="$(detect_wan_ipv4_cidr "$WAN" || true)"
  auto_cidr="$(auto_lan_cidr "$WAN_IPV4_CIDR")"

  while true; do
    DHCP_START=""
    DHCP_END=""

    echo
    echo "LAN subnet:"
    if [ -n "$WAN_IPV4_CIDR" ]; then
      echo "  detected WAN IPv4: $WAN_IPV4_CIDR"
    else
      echo "  detected WAN IPv4: unknown"
    fi
    echo "  auto choice:       $auto_cidr"
    echo
    echo "  1) Auto  [default]"
    echo "     Prefer 192.168.2.0/24 unless WAN/upstream already uses it."
    echo "  2) 192.168.2.1/24"
    echo "  3) 192.168.50.1/24"
    echo "  4) 192.168.88.1/24"
    echo "  5) 192.168.100.1/24"
    echo "  6) Custom 192.168.x.1/24"
    echo

    lan_choice="$(ask_default "Choose LAN subnet" "1")"

    case "$lan_choice" in
      ""|1)
        set_lan_from_cidr "$auto_cidr"
        ;;
      2)
        set_lan_from_cidr "192.168.2.1/24"
        ;;
      3)
        set_lan_from_cidr "192.168.50.1/24"
        ;;
      4)
        set_lan_from_cidr "192.168.88.1/24"
        ;;
      5)
        set_lan_from_cidr "192.168.100.1/24"
        ;;
      6)
        custom_lan="$(ask_default "Custom LAN gateway CIDR" "$auto_cidr")"
        if ! validate_192168_24_cidr "$custom_lan"; then
          echo
          echo "ERROR: custom LAN must be a 192.168.x.1/24-style IPv4 CIDR."
          echo "Example: 192.168.60.1/24"
          continue
        fi
        set_lan_from_cidr "$custom_lan"
        ;;
      *)
        echo "Unknown choice. Using Auto."
        set_lan_from_cidr "$auto_cidr"
        ;;
    esac

    if [ -n "$WAN_IPV4_CIDR" ] && networks_overlap "$WAN_IPV4_CIDR" "$LAN_CIDR"; then
      echo
      echo "ERROR: WAN/upstream and LAN overlap."
      echo "  WAN/upstream: $WAN_IPV4_CIDR"
      echo "  chosen LAN:   $LAN_NET"
      echo
      echo "Choose another 192.168.x.0/24 LAN subnet."
      continue
    fi

    break
  done
}

set_cake_profile_defaults() {
  CAKE_PROFILE="${CAKE_PROFILE:-conservative}"

  case "$CAKE_PROFILE" in
    conservative)
      CAKE_DOWN="${CAKE_DOWN:-100mbit}"
      CAKE_UP="${CAKE_UP:-20mbit}"
      ;;
    fast)
      CAKE_DOWN="${CAKE_DOWN:-300mbit}"
      CAKE_UP="${CAKE_UP:-40mbit}"
      ;;
    satellite)
      CAKE_DOWN="${CAKE_DOWN:-150mbit}"
      CAKE_UP="${CAKE_UP:-20mbit}"
      ;;
    custom)
      CAKE_DOWN="${CAKE_DOWN:-100mbit}"
      CAKE_UP="${CAKE_UP:-20mbit}"
      ;;
    *)
      echo "Unknown CAKE profile: $CAKE_PROFILE" >&2
      echo "Use: conservative, fast, satellite, or custom" >&2
      exit 2
      ;;
  esac
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
  python3 - "$answers" "$MODE" "$WAN" "$LAN" "$LAN_CIDR" "$LAN_IP" "$LAN_NET" "$DHCP_START" "$DHCP_END" "$CAKE" "$CAKE_PROFILE" "$CAKE_DOWN" "$CAKE_UP" "$AI_AGENT" "$MOBILE_ALERTS" "$WORK_DIR" <<'PY'
import json
import sys
from pathlib import Path
from datetime import datetime, timezone

path, mode, wan, lan, lan_cidr, lan_ip, lan_net, dhcp_start, dhcp_end, cake, cake_profile, cake_down, cake_up, ai_agent, mobile_alerts, work_dir = sys.argv[1:]
data = {
    "schema": "lilhouse.easy_install_answers.v1",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "mode": mode,
    "wan": wan,
    "lan": lan,
    "lan_cidr": lan_cidr,
    "lan_ip": lan_ip,
    "lan_net": lan_net,
    "dhcp_start": dhcp_start,
    "dhcp_end": dhcp_end,
    "features": {
        "cake": cake == "yes",
        "cake_profile": cake_profile,
        "cake_down": cake_down,
        "cake_up": cake_up,
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

print_result() {
  report="$1"
  answers="$2"

  python3 - "$report" "$answers" <<'PY_CLEAN_RESULT'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
answers = json.loads(Path(sys.argv[2]).read_text())
summary = report.get("summary", {})
features = answers.get("features", {})
mode = answers.get("mode")
wan = answers.get("wan")
lan = answers.get("lan")

print()
print("======================================")
print(" LilHouse install complete")
print("======================================")
print()
display_mode = "full-install" if mode == "vm-live" else "dry-run" if mode == "vm" else mode
print(f"Mode: {display_mode}")
print(f"WAN:  {wan}")
print(f"LAN:  {lan}")
print(f"LAN gateway: {answers.get('lan_ip', '192.168.2.1')}")
print(f"LAN subnet:  {answers.get('lan_net', '192.168.2.0/24')}")
print(f"DHCP range:  {answers.get('dhcp_start', '192.168.2.100')}-{answers.get('dhcp_end', '192.168.2.200')}")
print(f"DNS:         {answers.get('lan_ip', '192.168.2.1')}")
print()
print("Features:")
print(f"  CAKE/SQM:        {'yes' if features.get('cake') else 'no'}")
print(f"  CAKE profile:    {features.get('cake_profile', 'conservative')}")
print(f"  CAKE rates:      {features.get('cake_down', '100mbit')} down / {features.get('cake_up', '20mbit')} up")
print(f"  Core agent:      {'yes' if features.get('ai_agent') else 'no'}")
print(f"  Mobile alerts:   {'yes' if features.get('mobile_alerts') else 'no'}")
print()
if summary:
    print("Deployment:")
    for label, key in [
        ("appliance prep", "appliance_prep_ok"),
        ("DNS active", "appliance_dns_active"),
        ("CAKE active", "appliance_cake_active"),
        ("firewall active", "appliance_firewall_active"),
        ("telemetry active", "appliance_telemetry_active"),
        ("guarded chain", "live_orchestrator_complete"),
        ("safe to leave live", "safe_to_leave_live_state"),
    ]:
        if key in summary:
            print(f"  {'✓' if summary.get(key) else '✗'} {label}")
PY_CLEAN_RESULT

  if [ "${MODE:-}" = "vm-live" ]; then
    echo
    echo "Final checks:"

    if "$REPO_DIR/bin/lilhouse-router-alpha-readiness" --report "$report" >/tmp/lilhouse-alpha-readiness-last.json 2>/tmp/lilhouse-alpha-readiness-last.err; then
      echo "  ✓ Alpha readiness"
    else
      echo "  ✗ Alpha readiness"
      cat /tmp/lilhouse-alpha-readiness-last.err 2>/dev/null || true
    fi

    dhcp_active="$(pihole-FTL --config dhcp.active 2>/dev/null || true)"
    dhcp_start="$(pihole-FTL --config dhcp.start 2>/dev/null || true)"
    dhcp_end="$(pihole-FTL --config dhcp.end 2>/dev/null || true)"
    dhcp_router="$(pihole-FTL --config dhcp.router 2>/dev/null || true)"
    if [ "$dhcp_active" = "true" ]; then
      echo "  ✓ DHCP active ($dhcp_start-$dhcp_end, router $dhcp_router)"
    else
      echo "  ✗ DHCP active"
    fi

    if ss -lunp 2>/dev/null | grep -q ':67'; then
      echo "  ✓ DHCP listener on UDP :67"
    else
      echo "  ✗ DHCP listener on UDP :67"
    fi

    if [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 0)" = "1" ]; then
      echo "  ✓ IPv4 forwarding"
    else
      echo "  ✗ IPv4 forwarding"
    fi

    NFT_CMD=nft
    nft_rules="$("$NFT_CMD" list ruleset 2>/dev/null || true)"
    if printf "%s\n" "$nft_rules" | awk -v net="$LAN_NET" 'index($0, net) && /masquerade/ {found=1} END{exit !found}'; then
      echo "  ✓ NAT masquerade"
    else
      echo "  ✗ NAT masquerade"
    fi

    for svc in systemd-networkd nftables unbound pihole-FTL lilhouse-cake.service lilhouse-current-state.timer lilhouse-storage-health.timer; do
      if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "  ✓ $svc"
      else
        echo "  ✗ $svc"
      fi
    done

    echo
    echo "Next step: plug a device into the LAN side."
    echo "It should receive an address in $LAN_NET with gateway/DNS $LAN_IP."
    echo
    echo "Later, check router health with: sudo lilhouse-router-status"
    echo "Check LilHouse storage usage with: sudo lilhouse-storage-status"
    echo "To change CAKE speeds later: sudo lilhouse-cake-set --down 250 --up 35"
  fi

  echo
  echo "Reports:"
  echo "  answers: $answers"
  echo "  report:  $report"
  echo "  logs:    ${LOG_DIR:-$WORK_DIR/logs}"
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
    --lan-cidr)
      LAN_CIDR="${2:?missing value for --lan-cidr}"
      shift 2
      ;;
    --dhcp-start)
      DHCP_START="${2:?missing value for --dhcp-start}"
      shift 2
      ;;
    --dhcp-end)
      DHCP_END="${2:?missing value for --dhcp-end}"
      shift 2
      ;;
    --cake)
      CAKE="${2:?missing value for --cake}"
      shift 2
      ;;
    --cake-profile)
      CAKE_PROFILE="${2:?missing value for --cake-profile}"
      shift 2
      ;;
    --cake-down)
      CAKE_DOWN="${2:?missing value for --cake-down}"
      shift 2
      ;;
    --cake-up)
      CAKE_UP="${2:?missing value for --cake-up}"
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
  echo " LilHouse Agentic Router Installer"
  echo "======================================"
  echo
  echo "Fresh Debian + two wired NICs = smart home router."
  echo

  detect_interfaces

  echo "Install mode:"
  echo "  1) Full router install on this machine/test router  [default]"
  echo "  2) Dry-run simulation only"
  echo
  choice="$(ask_default "Choose mode" "1")"
  case "$choice" in
    ""|1)
      MODE="vm-live"
      THROWAWAY_VM=1
      ;;
    2)
      MODE="vm"
      ;;
    *)
      echo "Unknown choice. Using full router install."
      MODE="vm-live"
      THROWAWAY_VM=1
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
    echo "Network layout:"
    echo "  WAN: $WAN_DEFAULT  [detected]"
    echo "  LAN: $LAN_DEFAULT  [detected]"
    echo "Press Enter to accept, or type a different interface."
  fi
fi

WAN="$(ask_default "WAN interface" "${WAN:-$WAN_DEFAULT}")"
while ! iface_exists "$WAN"; do
  echo "WAN interface not found: $WAN"
  WAN="$(ask_default "WAN interface" "$WAN_DEFAULT")"
done

LAN="$(ask_default "LAN interface" "${LAN:-$LAN_DEFAULT}")"
while ! iface_exists "$LAN"; do
  echo "LAN interface not found: $LAN"
  LAN="$(ask_default "LAN interface" "$LAN_DEFAULT")"
done

if [ "$WAN" = "$LAN" ]; then
  echo "ERROR: WAN and LAN cannot be the same interface." >&2
  exit 2
fi

  WAN_IPV4_CIDR="$(detect_wan_ipv4_cidr "$WAN" || true)"

  if [ -n "$LAN_CIDR" ]; then
    set_lan_defaults
    if [ -n "$WAN_IPV4_CIDR" ] && networks_overlap "$WAN_IPV4_CIDR" "$LAN_CIDR"; then
      echo
      echo "ERROR: WAN/upstream and configured LAN overlap."
      echo "  WAN/upstream: $WAN_IPV4_CIDR"
      echo "  configured LAN: $LAN_NET"
      echo
      echo "Choose a different --lan-cidr."
      exit 2
    fi
  else
    choose_lan_subnet_interactive
  fi

  CAKE="yes"

  echo
  echo "CAKE/SQM profile:"
  echo "  1) Conservative / works almost anywhere  [default]"
  echo "     100 down / 20 up"
  echo "  2) Fast home connection"
  echo "     300 down / 40 up"
  echo "  3) Satellite / variable connection"
  echo "     150 down / 20 up"
  echo "  4) Custom"
  echo
  cake_choice="$(ask_default "Choose CAKE profile" "1")"
  case "$cake_choice" in
    ""|1)
      CAKE_PROFILE="conservative"
      CAKE_DOWN="100mbit"
      CAKE_UP="20mbit"
      ;;
    2)
      CAKE_PROFILE="fast"
      CAKE_DOWN="300mbit"
      CAKE_UP="40mbit"
      ;;
    3)
      CAKE_PROFILE="satellite"
      CAKE_DOWN="150mbit"
      CAKE_UP="20mbit"
      ;;
    4)
      CAKE_PROFILE="custom"
      custom_down="$(ask_default "Download speed for CAKE in Mbit" "100")"
      custom_up="$(ask_default "Upload speed for CAKE in Mbit" "20")"
      CAKE_DOWN="$(normalise_mbit "$custom_down")"
      CAKE_UP="$(normalise_mbit "$custom_up")"
      ;;
    *)
      echo "Unknown choice. Using Conservative."
      CAKE_PROFILE="conservative"
      CAKE_DOWN="100mbit"
      CAKE_UP="20mbit"
      ;;
  esac

  AI_AGENT="yes"
  MOBILE_ALERTS="$(ask_yes_no "Configure mobile push alerts now? You can choose no and set them up after install." "${MOBILE_ALERTS:-no}")"

  echo
  echo "Install summary:"
  if [ "$MODE" = "vm-live" ]; then DISPLAY_MODE="full-install"; else DISPLAY_MODE="dry-run"; fi
  echo "  mode=$DISPLAY_MODE"
  echo "  wan=$WAN"
  echo "  lan=$LAN"
  echo "  lan_gateway=$LAN_IP"
  echo "  lan_subnet=$LAN_NET"
  echo "  dhcp_range=$DHCP_START-$DHCP_END"
  echo "  dns=Pi-hole + Unbound"
  echo "  firewall=nftables NAT"
  echo "  sqm=CAKE ($CAKE_PROFILE, $CAKE_DOWN down / $CAKE_UP up)"
  echo "  work_dir=$WORK_DIR"
  echo

  if [ "$MODE" = "vm-live" ]; then
    confirm="$(ask_yes_no "Continue with router install?" "yes")"
  else
    confirm="$(ask_yes_no "Continue with dry-run simulation?" "yes")"
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
set_lan_defaults
CAKE="${CAKE:-yes}"
set_cake_profile_defaults
AI_AGENT="${AI_AGENT:-yes}"
MOBILE_ALERTS="${MOBILE_ALERTS:-no}"

if ! iface_exists "$WAN"; then
  echo "ERROR: WAN interface not found: $WAN" >&2
  exit 2
fi
if ! iface_exists "$LAN"; then
  echo "ERROR: LAN interface not found: $LAN" >&2
  exit 2
fi
if [ "$WAN" = "$LAN" ]; then
  echo "ERROR: WAN and LAN cannot be the same interface." >&2
  exit 2
fi

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

LOG_DIR="$WORK_DIR/logs"
mkdir -p "$LOG_DIR"

run_logged() {
  label="$1"
  logfile="$2"
  shift 2

  echo "  • $label..."
  if "$@" >"$logfile" 2>&1; then
    echo "    ✓ done"
  else
    echo "    ✗ failed"
    echo
    echo "Last log lines from $logfile:"
    tail -80 "$logfile" 2>/dev/null || true
    exit 1
  fi
}

echo
echo "======================================"
echo " LilHouse Agentic Router Installer"
echo "======================================"
echo
if [ "$MODE" = "vm-live" ]; then DISPLAY_MODE="full-install"; else DISPLAY_MODE="dry-run"; fi
echo "Mode:       $DISPLAY_MODE"
echo "WAN:        $WAN"
echo "LAN:        $LAN"
echo "Gateway:    $LAN_IP"
echo "Subnet:     $LAN_NET"
echo "DHCP:       $DHCP_START-$DHCP_END"
echo "CAKE:       $CAKE_PROFILE ($CAKE_DOWN down / $CAKE_UP up)"
echo "Work dir:   $WORK_DIR"
echo "Logs:       $LOG_DIR"
echo

if [ "$MODE" = "vm" ]; then
  echo "Running dry-run simulation..."
  run_logged "Building VM readiness bundle" "$LOG_DIR/01-vm-readiness-bundle.log" \
    "$BUNDLE" \
    --work-dir "$WORK_DIR/vm-readiness-bundle" \
    --wan "$WAN" \
    --lan "$LAN" \
    --vm-nic-bypass-key "$VM_BYPASS_KEY" \
    --yes \
    --out "$OUT"

  print_result "$OUT" "$ANSWERS"
  exit 0
fi

echo "Installing..."
# Audit safety marker: WARNING: --vm-live installs/activates into / on this disposable VM.
echo "Detailed logs are saved if anything fails. Final checks will show whether the install was successful."
echo

echo "Resetting VM-live work reports..."
rm -rf "$WORK_DIR/vm-live-prep" "$WORK_DIR/vm-live-work" "$WORK_DIR/vm-live-backup"
rm -f "$WORK_DIR/vm-live-install-report.json"

run_logged "Installing packages, DNS/DHCP, firewall, CAKE and telemetry" "$LOG_DIR/01-appliance-install.log" \
  "$APPLIANCE_INSTALL" \
  --prepare-only \
  --yes \
  --wan "$WAN" \
  --lan "$LAN" \
  --lan-cidr "$LAN_CIDR" \
  --dhcp-start "$DHCP_START" \
  --dhcp-end "$DHCP_END" \
  --cake-down "$CAKE_DOWN" \
  --cake-up "$CAKE_UP"

PREP_WORK="$WORK_DIR/vm-live-prep"
PREP_REPORT="$WORK_DIR/vm-live-prep-report.json"

run_logged "Building install preview and preflight checks" "$LOG_DIR/02-preflight.log" \
  "$BUNDLE" \
  --work-dir "$PREP_WORK" \
  --wan "$WAN" \
  --lan "$LAN" \
  --vm-nic-bypass-key "$VM_BYPASS_KEY" \
  --yes \
  --out "$PREP_REPORT"

run_logged "Applying guarded live configuration" "$LOG_DIR/03-live-orchestrator.log" \
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

run_logged "Running final appliance checks" "$LOG_DIR/04-appliance-prep-report.log" \
  "$APPLIANCE_PREP_REPORTER" --report "$OUT" --wan "$WAN" --lan "$LAN"

print_result "$OUT" "$ANSWERS"
