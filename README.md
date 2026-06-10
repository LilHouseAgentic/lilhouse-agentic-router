# LilHouse Agentic Router

LilHouse Agentic Router turns a Raspberry Pi router into a self-monitoring, permission-gated, agentic NetOps appliance.

It uses a crew of small workers to observe the network, collect telemetry, detect patterns, produce reports, and propose safe improvements.

Optional AI workers can draft upgrade plans, but risky actions are gated through approvals and safety checks.

## Status

Early public packaging work.

This repository is being extracted from a live Raspberry Pi router prototype.

## What it does

- Monitors WAN health, latency, packet loss, and route state
- Tracks CAKE/SQM health and bandwidth behaviour
- Watches DNS services such as Pi-hole and Unbound
- Checks Docker container health
- Detects interface drops, errors, and link changes
- Watches storage, mounts, logs, and system resources
- Provides a portable storage health worker
- Maintains event, action, and proposal ledgers
- Supports permission-gated upgrade proposals
- Supports optional AI planning with bring-your-own API key

## What it is not

This is not a finished commercial router firmware.

This is not an unchecked self-modifying router.

This is not designed to blindly apply AI-generated commands.

## Modes

- Observe mode: collect telemetry and reports only
- Propose mode: suggest actions, but do not apply them
- Agentic mode: optional AI proposal/planning workers with approval gates

## Safety model

- Workers are read-only by default
- AI is optional
- Generated plans are proposals, not commands
- Destructive actions are disabled by default
- Approved actions pass through a safety gate
- Notifications are rate-limited
- Only the highest active brain should notify the user

## Hardware target

- Raspberry Pi 5
- Raspberry Pi OS / Debian Bookworm
- WAN on one Ethernet interface
- LAN on another Ethernet interface
- CAKE/SQM
- Pi-hole / Unbound
- Optional Docker monitoring
- Optional Starlink monitoring

## License

MIT
