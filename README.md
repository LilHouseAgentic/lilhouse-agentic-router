# LilHouse Agentic Router

LilHouse Agentic Router is an alpha-stage Debian router appliance installer and safety framework.

It builds a small home-router stack around Pi-hole + Unbound DNS, nftables firewalling/NAT, CAKE/SQM traffic shaping, observe-only LilHouse telemetry workers, and a guarded install flow with backup, rollback guard, post-apply health checks, and readiness reporting.

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

Do **not** run the full throwaway VM installer on a real live router.

The full install mode is for disposable VM testing only. Real-router mode is still dry-run / preview only until the live-production guardrails are completed.

For Jordy's current live Pi router: use this repo as source/dev/test material only. Do not run the appliance installer or uninstaller on the live Pi.

## Quick alpha VM test

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
