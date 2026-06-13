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
rm -rf lilhouse-agentic-router
git clone https://github.com/LilHouseAgentic/lilhouse-agentic-router.git
cd lilhouse-agentic-router
./bin/lilhouse-router-appliance-uninstall --yes --allow-live-root || true
rm -rf /tmp/lilhouse-first-install
./easy-install.sh
'
```

Choose option:

```text
2
```

Confirm the detected WAN and LAN interfaces.

A working install should give clients on the LAN side:

- IP from 10.23.0.100-10.23.0.200
- gateway 10.23.0.1
- DNS 10.23.0.1
- internet routed through the Debian router
