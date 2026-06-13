# LilHouse Agentic Router

Turn a fresh Debian machine with two wired NICs into a smart home router with one copy-paste install.

LilHouse Agentic Router is an alpha router appliance that installs Pi-hole, Unbound, nftables, CAKE/SQM, health checks, telemetry, and a guarded live apply flow.

Start here:

- [Fresh install guide](docs/FRESH-INSTALL.md)

Alpha warning: test on a spare machine, disposable VM, or test machine first.

## Current status

**Status: ALPHA**

The current alpha path has been proven in a disposable Debian VM using the full throwaway install flow.

This is not production-polished yet. It is a working, safety-gated appliance foundation for testing, review, and controlled iteration.

## Alpha proof

The alpha VM path verifies:

- full appliance preparation
- Pi-hole + Unbound DNS
- Pi-hole web UI bound to the LAN address
- nftables WAN hardening
- LAN-to-WAN NAT
- CAKE runtime installed and active
- LilHouse telemetry timers active
- guarded live chain completion
- rollback guard/cancel path
- alpha readiness checker returning ok=true

## Default security posture

The default appliance firewall posture is:

- WAN inbound policy: drop
- LAN interface: trusted/admin side
- LAN-to-WAN forwarding: allowed
- NAT masquerade: enabled
- WAN admin ports: not explicitly allowed
- Pi-hole web: LAN-bound, not wildcard web exposed

SSH from the WAN side is intentionally not enabled by default.

## Important warning

This is alpha software. Test it first on a disposable VM, spare PC, or fresh Debian test router.

The installer changes network configuration, DNS, DHCP, firewall rules, NAT, and routing on the target machine.

Do not run it on your current live router unless you are intentionally replacing that router and are prepared to recover or reinstall it.

## Quick alpha install test

On a disposable Debian VM:

    ./easy-install.sh

Choose:

    2) Full throwaway VM install test

Typical VM answers:

    WAN interface [eth0]:
    LAN interface [eth1]:
    Configure mobile push alerts now? [no]:
    Continue and install into / on this disposable VM? [no]: yes

After install:

    ./bin/lilhouse-router-appliance-prep-report --report /tmp/lilhouse-first-install/vm-live-install-report.json --wan eth0 --lan eth1
    ./bin/lilhouse-router-alpha-readiness --report /tmp/lilhouse-first-install/vm-live-install-report.json

Expected alpha result:

    failure_count=0
    failures=[]
    ok=true
    status=alpha-ready

## Key scripts

- easy-install.sh — first-run installer / VM test entrypoint
- bin/lilhouse-router-appliance-install — installs the required appliance stack
- bin/lilhouse-router-appliance-uninstall — throwaway VM reset/uninstall helper
- bin/lilhouse-router-appliance-prep-report — runtime appliance proof report
- bin/lilhouse-router-alpha-readiness — alpha readiness checker
- bin/lilhouse-router-live-orchestrator — guarded live chain executor
- scripts/audit-secrets.sh — repo safety/secret/risky-pattern audit
- tests/smoke-test.sh — broad repo smoke test

## Development checks

Before committing:

    ./tests/smoke-test.sh
    ./scripts/audit-secrets.sh

Both should pass.

## Known limitations

This alpha is not yet a one-click production router installer.

Known limitations:

- real-router live apply remains intentionally restricted
- WAN SSH is blocked by default
- no public alpha helper opens WAN SSH
- dynamic CAKE tuning is not yet part of the alpha installer path
- full recovery/rollback has been VM-proven, but not production-certified
- UI/dashboard polish is not part of alpha scope yet
- docs are still being expanded

## Version milestone

The core appliance alpha path was proven at:

    v0.2.96-live-preview-networkd-forwarding

Next presentation milestone:

    v0.3.0-alpha
