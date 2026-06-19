# LilHouse deployment modes

LilHouse has two install modes.

## Observe-only

Observe-only installs LilHouse tools, status commands, storage tools, and agent-readable diagnostics without turning the host into a router.

```bash
sudo ./install.sh --mode observe-only
```

## Router-deploy

Router-deploy turns a fresh Debian host into a LilHouse router.

```bash
sudo ./install.sh --mode router-deploy --wan eth0 --lan eth1 --yes
```

Router-deploy configures LAN addressing, IPv4 forwarding, nftables firewall/NAT, Pi-hole DHCP/DNS, Unbound, CAKE/SQM, and LilHouse timers.

Use explicit interfaces. WAN is the upstream/internet side. LAN is the client side.

## Router-deploy dry-run

Dry-run generates a preview and does not install router services.

```bash
./install.sh --mode router-deploy --wizard --dry-run --wan eth0 --lan eth1
```

Use dry-run to inspect the chosen interfaces and generated router configuration before running router-deploy.

## Router-deploy verification

Router-deploy runs verification after appliance install. Manual verification is also available:

```bash
sudo lilhouse-router-deploy-verify --yes
```

Verification checks LAN config, forwarding, nftables forwarding/NAT, Pi-hole DHCP, Unbound, and DNS response on the LAN IP.
