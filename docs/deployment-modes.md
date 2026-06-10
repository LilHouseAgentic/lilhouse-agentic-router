# Deployment Modes

LilHouse Agentic Router has two major deployment modes.

## Observe-only mode

Observe-only mode is the safe default.

It installs monitoring, status, and worker tools without changing router behaviour.

It may collect state, write JSON reports, write ledgers, run read-only workers, print summaries, and run safe systemd timers.

It must not change interfaces, firewall rules, DNS services, NAT, DHCP, CAKE/SQM, packages, or reboot the system.

Current installer behaviour is observe-only.

## Router-deploy mode

Router-deploy mode is planned.

It will turn a fresh Debian Raspberry Pi into a working LilHouse router.

It may configure WAN, LAN, static LAN IP, DHCP, Pi-hole, Unbound, forwarding, firewall/NAT, CAKE/SQM, systemd services, and worker timers.

Router-deploy mode must ask for WAN/LAN interfaces, show a plan before applying, back up changed files, avoid overwriting unknown setups, and support dry-run testing where practical.

Target command: sudo ./install.sh --mode router-deploy --wizard

## Future install flow

Install Debian, clone LilHouse, run the wizard, select WAN/LAN, confirm the generated router plan, plug WAN/LAN in, and configure optional extras later.
