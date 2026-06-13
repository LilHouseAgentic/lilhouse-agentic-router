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
./bin/lilhouse-router-appliance-uninstall --yes --allow-live-root || true
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
