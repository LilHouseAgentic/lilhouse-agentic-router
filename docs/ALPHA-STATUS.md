# Alpha Status

Current alpha milestone:

    v0.2.96-live-preview-networkd-forwarding

## Proven in VM

- disposable Debian VM full install
- Pi-hole + Unbound required DNS stack
- Pi-hole web LAN bind
- nftables WAN hardening
- CAKE required runtime
- LilHouse observe-only core telemetry timers
- guarded live chain
- rollback guard and cancel
- post-apply health gate
- alpha readiness checker

## Clean alpha output

Expected alpha readiness:

    failure_count=0
    failures=[]
    ok=true
    status=alpha-ready

## Not yet production-ready

- no real-router one-click live install
- no public WAN SSH helper
- no production migration assistant yet
- docs still expanding
- UI/dashboard not part of alpha scope
