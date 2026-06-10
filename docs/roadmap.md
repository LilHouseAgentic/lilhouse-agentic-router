# LilHouse Agentic Router Roadmap

LilHouse Agentic Router is intended to become a deployable Raspberry Pi router appliance.

Long-term goal:

Fresh Debian install on a Raspberry Pi + LilHouse installer + WAN/LAN plugged in = working enterprise-style home router.

## Phase 0: Repository foundation

README, license, config examples, installer, uninstaller, fake-root install, smoke test, safety audit, and ignored runtime files.

## Phase 1: Observe-only core

Read-only analytics, current-state collection, status output, storage health, event/action ledgers, and safe systemd timers.

## Phase 2: Router foundation

WAN setup, LAN setup, static LAN IP, IPv4 forwarding, IPv6 forwarding where available, firewall/NAT, DHCP, Pi-hole, Unbound, and DNS routing.

This phase must support dry-run, backups, rollback where practical, and explicit confirmation before changing a live router.

## Phase 3: Router performance services

CAKE/SQM, WAN health, DNS performance, interface health, Docker health, storage health, and log retention.

## Phase 4: Agentic layer

Workers, proposals, approval gates, action ledgers, brain loop, notification gate, optional local AI, and optional external AI API.

The agentic layer must propose risky changes instead of silently applying them.

## Phase 5: Deployment wizard

The wizard should turn a fresh Debian Pi into a LilHouse router by asking for WAN, LAN, subnet, router IP, DHCP range, DNS mode, Pi-hole, Unbound, firewall, CAKE, Pushover, SSH, and AI options.

Target command: sudo ./install.sh --mode router-deploy --wizard

## Phase 6: Optional integrations

Pushover, Home Assistant, Grafana, Prometheus, Docker app hooks, SSH helpers, local AI, hosted AI APIs, Starlink telemetry, and custom user workers.
