# LilHouse Agentic Router Alpha Runbook

This runbook describes the current alpha validation flow.

## Scope

This runbook is for disposable VM testing only.

Do not use this runbook to install onto the live Pi router or any machine currently carrying the home network.

## Alpha definition

A build is alpha-ready when:

- smoke test passes
- audit passes
- full throwaway VM install completes
- appliance prep report is green
- alpha readiness checker returns ok=true
- WAN admin ports are not explicitly allowed
- Pi-hole web is LAN-bound
- CAKE is active
- DNS is active
- firewall is hardened
- telemetry timers are active

## Build package on source/dev machine

From the Pi/source repo:

    cd ~
    tar czf /tmp/lilhouse-agentic-router-alpha.tgz lilhouse-agentic-router

    cd /tmp
    python3 -m http.server 8785 --bind 192.168.2.1

Use a new port if the old server is still running.

## Fetch on disposable VM

On the VM:

    cd /tmp
    wget -O lilhouse-agentic-router-alpha.tgz http://192.168.2.1:8785/lilhouse-agentic-router-alpha.tgz

    cd ~
    test ! -e lilhouse-agentic-router || mv lilhouse-agentic-router lilhouse-agentic-router.old
    tar xzf /tmp/lilhouse-agentic-router-alpha.tgz
    cd ~/lilhouse-agentic-router

## Run full throwaway VM install

    ./easy-install.sh

Select:

    2) Full throwaway VM install test

Typical Hyper-V VM values:

    WAN interface [eth0]:
    LAN interface [eth1]:
    Configure mobile push alerts now? [no]:
    Continue and install into / on this disposable VM? [no]: yes

## Verify appliance prep

    ./bin/lilhouse-router-appliance-prep-report --report /tmp/lilhouse-first-install/vm-live-install-report.json --wan eth0 --lan eth1

Expected summary values:

    appliance_prep_ok=true
    appliance_cake_active=true
    appliance_dns_active=true
    appliance_web_lan_bound=true
    appliance_web_wildcard_disabled=true
    appliance_firewall_hardened=true
    appliance_telemetry_active=true

## Verify alpha readiness

    ./bin/lilhouse-router-alpha-readiness --report /tmp/lilhouse-first-install/vm-live-install-report.json

Expected:

    failure_count=0
    failures=[]
    ok=true
    status=alpha-ready

## Verify firewall state

    nft list ruleset

Expected firewall properties:

- table inet lilhouse_filter exists
- input chain policy is drop
- LAN interface is accepted
- established/related traffic is accepted
- LAN-to-WAN forward is accepted
- WAN admin ports are not explicitly accepted
- table ip lilhouse_nat exists
- NAT masquerade exists for LAN subnet out WAN

## Verify Pi-hole web bind

    pihole-FTL --config webserver.port
    ss -lntup | grep -E ':(80|443)\b' || true

Expected:

    192.168.2.1:80o,192.168.2.1:443os

Pi-hole web should listen on 192.168.2.1:80 and 192.168.2.1:443, not wildcard 0.0.0.0:80 or 0.0.0.0:443.

## Verify networkd LAN config

    cat /etc/systemd/network/20-lilhouse-lan.network
    grep -Rni 'IPForward' /etc/systemd/network || echo "no deprecated IPForward syntax"
    grep -RniE 'IPv4Forwarding|IPv6Forwarding' /etc/systemd/network

Expected:

    [Network]
    Address=192.168.2.1/24
    IPv4Forwarding=yes
    IPv6Forwarding=yes
    IPv6AcceptRA=no

## Verify services

    systemctl is-active systemd-networkd
    systemctl is-active nftables
    systemctl is-active unbound
    systemctl is-active pihole-FTL
    systemctl is-active lilhouse-cake.service
    systemctl is-active lilhouse-current-state.timer
    systemctl is-active lilhouse-storage-health.timer

Expected: all active.

## Clean reinstall/reset testing

Use only on the disposable VM:

    sudo ./bin/lilhouse-router-appliance-uninstall --yes --i-am-in-a-throwaway-vm

Then rerun ./easy-install.sh.

## WAN SSH note

Clean alpha blocks WAN-side SSH.

That is intentional.

During VM development, deleting or reloading nftables can block new SSH sessions from the Windows host to the VM NAT address. Use the Hyper-V console for clean firewall tests.

Do not ship a WAN SSH helper in alpha.

## Alpha fail conditions

Alpha readiness must fail if:

- WAN SSH/admin port is explicitly accepted
- Pi-hole web is wildcard-bound
- nftables hardening is missing
- CAKE is missing/inactive
- Unbound or Pi-hole is inactive
- telemetry timers are inactive
- stale/old VM report data is reused
- deprecated networkd IPForward= returns

## Release candidate checklist

Before tagging an alpha release:

    ./tests/smoke-test.sh
    ./scripts/audit-secrets.sh
    git status
    git log --oneline --decorate --max-count=20

Then run the disposable VM reinstall and readiness check.
