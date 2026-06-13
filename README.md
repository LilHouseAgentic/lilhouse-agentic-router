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

## Public alpha quickstart

LilHouse Agentic Router is currently a public alpha for fresh Debian test routers, spare machines, or disposable VMs. Do not run the full router installer on a production router unless you are prepared for network interruption and have a recovery path.

### Fresh install

```bash
git clone https://github.com/LilHouseAgentic/lilhouse-agentic-router.git
cd lilhouse-agentic-router
./easy-install.sh
```

The easy installer will guide you through:

- install mode
- WAN/LAN interface selection
- WAN/LAN subnet conflict detection
- CAKE/SQM profile selection
- final router health checks

### After install

Check router health:

```bash
sudo lilhouse-router-status
```

Change CAKE/SQM speeds later without reinstalling:

```bash
sudo lilhouse-cake-set --down 220 --up 30
```

Use a preset CAKE profile:

```bash
sudo lilhouse-cake-set --profile conservative
sudo lilhouse-cake-set --profile fast
sudo lilhouse-cake-set --profile satellite
```

### CAKE/SQM profiles

The installer currently offers:

- Conservative: `100mbit` down / `20mbit` up
- Fast: `300mbit` down / `40mbit` up
- Satellite / variable: `150mbit` down / `20mbit` up
- Custom: user-provided download/upload values

### WAN/LAN subnet conflict protection

The default LilHouse LAN is:

```text
192.168.2.1/24
DHCP: 192.168.2.100-192.168.2.200
```

If the upstream WAN network overlaps the default LilHouse LAN, the installer warns you and offers a safer alternate LAN such as:

```text
192.168.50.1/24
DHCP: 192.168.50.100-192.168.50.200
```

This helps avoid broken routing when the upstream modem/router is already using the same subnet.

### Useful commands

```bash
sudo lilhouse-router-status
sudo lilhouse-cake-set --down 220 --up 30
sudo systemctl status lilhouse-cake.service --no-pager
sudo systemctl status pihole-FTL --no-pager
sudo systemctl status unbound --no-pager
```

### Current alpha scope

The `v0.3.x` series focuses on safe installation, router defaults, status reporting, manual CAKE tuning, and public-alpha usability.

Automatic self-healing, speedtest-based CAKE tuning, push alerts, and read-only router diagnosis are planned for later alpha releases.
