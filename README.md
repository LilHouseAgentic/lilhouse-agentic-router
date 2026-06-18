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
```

## Useful commands

```bash
sudo lilhouse-router-status
sudo lilhouse-client-readiness
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

## Intellectual property

The software code in this repository is released under the MIT License. See [LICENSE](LICENSE).

Copyright notices and attribution are documented in [NOTICE](NOTICE).

The MIT License grants rights to use, copy, modify, distribute, and sell copies of
the software, subject to the license terms. It does not grant ownership of the
LilHouse project name, branding, logos, or marks.

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
