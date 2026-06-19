# Fresh install

LilHouse Agentic Router turns a fresh Debian machine into a smart home router.

You need:

- a fresh Debian install
- two wired NICs
- one NIC connected to internet / modem / Starlink / upstream router
- one NIC connected to your LAN switch or test client

The installer auto-detects the likely WAN and LAN interfaces, asks you to confirm them, then installs:

- Pi-hole DNS and DHCP
- Unbound recursive DNS
- nftables firewall and NAT
- CAKE/SQM
- health checks and telemetry
- rollback-guarded live apply flow

## One copy-paste install

Alpha warning: use a spare machine, disposable VM, or test router first.

```bash
sudo bash -lc 'set -euo pipefail
apt update
apt install -y git ca-certificates curl
cd /root
REPO_URL="https://github.com/LilHouseAgentic/lilhouse-agentic-router.git"
REPO_DIR="/root/lilhouse-agentic-router"
if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  git fetch --all --tags
  git reset --hard origin/main
  git clean -fdx
else
  git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi
./bin/lilhouse-router-appliance-uninstall --yes --i-am-in-a-throwaway-vm || true
./easy-install.sh
'
```

Choose option:

```text
2
```

Confirm the detected WAN and LAN interfaces.

A working install should give clients on the LAN side:

- IP from 192.168.2.100-192.168.2.200
- gateway 192.168.2.1
- DNS 192.168.2.1
- internet routed through the Debian router

## LAN subnet picker

The easy installer uses an Auto LAN subnet picker.

Auto prefers:

```text
192.168.2.0/24
```

If the WAN/upstream network already overlaps that subnet, the installer automatically chooses another advertised `192.168.x.0/24` LAN subnet such as `192.168.50.0/24`.

Only `192.168.x.0/24` choices are advertised in the interactive menu. Custom interactive choices must be `192.168.x.1/24` style gateway CIDRs.

## Router-deploy apply mode

On a fresh Debian router host with explicit WAN and LAN interfaces:

```bash
sudo ./install.sh --mode router-deploy --wan eth0 --lan eth1 --yes
```

This path delegates to the LilHouse appliance installer and applies the core router services instead of stopping at a dry-run preview.

Use the dry-run wizard first when unsure:

```bash
./install.sh --mode router-deploy --wizard --dry-run --wan eth0 --lan eth1
```

## Router-deploy verification

Router-deploy runs verification after appliance install. Manual verification is also available:

```bash
sudo lilhouse-router-deploy-verify --yes
```

Verification checks LAN config, forwarding, nftables forwarding/NAT, Pi-hole DHCP, Unbound, and DNS response on the LAN IP.
