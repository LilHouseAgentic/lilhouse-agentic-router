# LilHouse Agentic Router

Turn a fresh Debian machine with two wired network ports into a smart home router.

LilHouse Agentic Router installs and wires together:

* Pi-hole for DNS and DHCP
* Unbound for local recursive DNS
* nftables for firewalling and NAT
* CAKE/SQM for latency-friendly traffic shaping
* router health checks
* client readiness checks
* storage safety tools
* read-only agent readiness/status tools

The project is currently a public alpha. It is intended for fresh Debian test routers, spare machines, Raspberry Pi-style router builds, and disposable VMs.

Do not run the full router installer on your current live router unless you are intentionally replacing it and have a recovery path.

## What LilHouse does

LilHouse turns this:

```text
internet / modem / Starlink
        |
   Debian machine
   with two NICs
        |
  LAN switch / Wi-Fi AP / client devices
```

into this:

```text
WAN side:
  upstream internet connection

LAN side:
  DHCP
  DNS
  gateway
  NAT
  firewall
  CAKE/SQM
  router health checks
```

After install, client devices should receive an IP address from the LilHouse LAN range and use the LilHouse router as gateway and DNS.

## Hardware needed

Minimum test setup:

* Fresh Debian install
* Two wired network interfaces
* One interface connected to upstream internet
* One interface connected to a LAN device, switch, or access point

Typical examples:

* Raspberry Pi 5 with built-in Ethernet plus USB Ethernet
* Small Debian mini PC with two Ethernet ports
* Disposable Debian VM for testing

## Quick start

Clone the repo:

```bash
git clone https://github.com/LilHouseAgentic/lilhouse-agentic-router.git
cd lilhouse-agentic-router
```

Run the installer:

```bash
./easy-install.sh
```

The installer will guide you through:

* install mode
* WAN/LAN interface selection
* LAN subnet selection
* DHCP range
* CAKE/SQM profile
* mobile alert choice
* final install plan
* post-install health checks

## Default network

Default LilHouse LAN:

```text
Gateway/DNS:  192.168.2.1
Subnet:       192.168.2.0/24
DHCP range:   192.168.2.100-192.168.2.200
```

If the upstream/WAN network already uses `192.168.2.0/24`, the installer can choose a safer alternate LAN such as:

```text
Gateway/DNS:  192.168.50.1
Subnet:       192.168.50.0/24
DHCP range:   192.168.50.100-192.168.50.200
```

This avoids WAN/LAN subnet overlap, which is a common cause of broken routing.

## CAKE/SQM profiles

The installer currently offers:

* Conservative: `100mbit` down / `20mbit` up
* Fast: `300mbit` down / `40mbit` up
* Satellite / variable: `150mbit` down / `20mbit` up
* Custom: user-provided download/upload values

After install, CAKE rates can be changed without reinstalling:

```bash
sudo lilhouse-cake-set --down 220 --up 30
```

Or with a preset:

```bash
sudo lilhouse-cake-set --profile conservative
sudo lilhouse-cake-set --profile fast
sudo lilhouse-cake-set --profile satellite
```

## After install

Check router health:

```bash
sudo lilhouse-router-status
```

Check whether the LAN/client side is ready:

```bash
sudo lilhouse-client-readiness
```

Expected fresh-install result before a LAN client is plugged in:

```text
Status: client-ready-waiting-for-device
Notes: router side looks ready; waiting for a LAN device lease
```

After a LAN device receives DHCP, the status should become:

```text
Status: client-ready-with-lease
```

Check the read-only agent status report:

```bash
lilhouse-agent-status
lilhouse-agent-propose
lilhouse-agent-proposal-review
sudo lilhouse-agent-propose --write-proposal --yes
```

## Useful commands

```bash
sudo lilhouse-router-status
sudo lilhouse-client-readiness
sudo lilhouse-router-doctor
sudo lilhouse-cake-set --down 220 --up 30
sudo lilhouse-storage-status
sudo lilhouse-storage-maintenance --dry-run
lilhouse-agent-readiness --check
lilhouse-agent-status
```

## Safety model

LilHouse is alpha software, but the install path is designed to be explicit and reviewable.

The installer shows a plan before applying changes. It configures router services only after confirmation.

Default security posture:

* WAN inbound traffic is blocked by default
* LAN side is trusted/admin side
* LAN-to-WAN forwarding is allowed
* NAT masquerade is enabled
* Pi-hole web UI is bound to the LAN side
* WAN SSH is not opened by default

Agent-related tools are currently read-only status/readiness helpers. They do not autonomously change router settings.

## Intellectual property and commercial use

LilHouse Agentic Router is source-available for personal, educational, evaluation, research, and non-commercial home-lab use.

Commercial use requires prior written permission from the project owner. This includes selling the software, selling modified versions, bundling it with paid hardware or services, offering managed/hosted/consulting services based on it, or rebranding it commercially.

See [LICENSE](LICENSE) for the full license terms.

Previous public releases up to and including `v0.5.6-alpha-ip-rights-notice` were published under the MIT License. Those older releases remain governed by the license terms that applied to them at the time of release.

Copyright notices and attribution are documented in [NOTICE](NOTICE).

Commercial licensing information is documented in [COMMERCIAL-LICENSING.md](COMMERCIAL-LICENSING.md).

Project names and branding are covered separately in [TRADEMARKS.md](TRADEMARKS.md).

## Current alpha scope

Current alpha focus:

* Fresh Debian router install
* Pi-hole + Unbound DNS/DHCP
* nftables firewall/NAT
* CAKE/SQM setup and manual tuning
* WAN/LAN subnet conflict protection
* router health checks
* client readiness checks
* storage safety tools
* read-only agent readiness/status foundation
* installer polish for public testing

Not yet included:

* automatic agent-driven router changes
* dynamic CAKE speed tuning
* production-certified rollback
* polished web UI/dashboard
* WAN SSH helper

## Documentation

Start here:

* [Fresh install guide](docs/FRESH-INSTALL.md)
* [Safety model](docs/safety-model.md)
* [Architecture](docs/architecture.md)
* [Storage policy](docs/storage-policy.md)
* [Agent operating model](docs/agent-operating-model.md)
* [Roadmap](docs/roadmap.md)

## Development checks

Before committing:

```bash
tests/smoke-test.sh
scripts/audit-secrets.sh
```

Both should pass.

## Router-deploy apply mode

On a fresh Debian router host with explicit WAN and LAN interfaces:

```bash
sudo ./install.sh --mode router-deploy --wan eth0 --lan eth1 --yes
```

This delegates to the LilHouse appliance installer and configures LAN addressing, forwarding, nftables NAT, Pi-hole DHCP/DNS, Unbound, CAKE/SQM, and health timers.

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
