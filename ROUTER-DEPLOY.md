# LilHouse Router Deploy Pipeline

This repository provides a non-live, safety-first router deployment pipeline.

It can generate, validate, rehearse, bundle, and summarize a router deployment package without touching the live root filesystem, starting services, changing firewall state, or modifying the active network.

## Current status

Latest safe milestone:

v0.2.54-release-candidate-summary

## What is safe now

The current pipeline safely supports preview generation, validation, backup and restore rehearsal, fake-root staging, fake-root apply, rollback rehearsal, confirmation checks, health rehearsal, service activation rehearsal, live readiness review, release candidate bundles, and release candidate summaries.

## What is still intentionally blocked

The current project does not perform live apply.

It does not copy staged files into /, start or restart live services, activate nftables, activate systemd-networkd, change Pi-hole, Unbound, CAKE, DHCP, DNS, or firewall state, cancel rollback timers, or declare live apply safe.

Even when all non-live gates pass, the system still reports:

ready_for_live_apply: false
safe_to_apply_live: false

## Generate a release candidate bundle

Use fake roots only. Example:

TMP_SOURCE="$(mktemp -d /tmp/lilhouse-rc-source.XXXXXX)"
TMP_STAGE="$(mktemp -d /tmp/lilhouse-rc-stage.XXXXXX)"
TMP_APPLY="$(mktemp -d /tmp/lilhouse-rc-apply.XXXXXX)"
TMP_UNITS="$(mktemp -d /tmp/lilhouse-rc-units.XXXXXX)"
TMP_RC="$(mktemp -d /tmp/lilhouse-rc-out.XXXXXX)"

mkdir -p "$TMP_SOURCE/etc/pihole" "$TMP_SOURCE/etc/systemd/system" "$TMP_SOURCE/etc/sysctl.d"
echo "# fake nftables" > "$TMP_SOURCE/etc/nftables.conf"
echo "net.ipv4.ip_forward=1" > "$TMP_SOURCE/etc/sysctl.d/90-lilhouse-router-forwarding.conf"
echo "# fake pihole" > "$TMP_SOURCE/etc/pihole/test.conf"
echo "# fake current-state service" > "$TMP_SOURCE/etc/systemd/system/lilhouse-current-state.service"

./bin/lilhouse-router-release-candidate \
  --out-dir "$TMP_RC" \
  --source-root "$TMP_SOURCE" \
  --stage-root "$TMP_STAGE" \
  --apply-target-root "$TMP_APPLY" \
  --unit-target-root "$TMP_UNITS" \
  --wan eth0 \
  --lan eth1 \
  --lan-ip 10.23.0.1 \
  --dns-test-name example.com \
  --wan-test-ip 1.1.1.1 \
  --timeout-seconds 120 \
  --rollback-timeout-minutes 5 \
  --enable-cake \
  --enable-ipv6

## Summarize a release candidate

./bin/lilhouse-router-release-candidate-summary "$TMP_RC/release-candidate-report.json"

Expected result:

LilHouse Router Release Candidate
Status: PASS
Checks: 12/12
Artifacts: 11
Non-live pipeline proven: YES

Apply: NO
Live changes: NO
Copies files: NO
Runs services: NO
Ready for live apply: NO
Safe to apply live: NO

## Important generated artifacts

The release candidate bundle includes release-candidate-report.json, full-dress-rehearsal.json, timed-rollback-rehearsal.json, live-confirmation-plan.json, live-confirmation-check.json, post-apply-health-rehearsal.json, service-activation-rehearsal.json, health-probe-rehearsal.json, live-readiness-review.json, live-apply-executor-plan.json, and final-deploy-runbook.json.

## Current live-readiness meaning

The readiness review currently proves the non-live system, but still keeps live apply blocked.

The remaining critical blocker is live_apply_root_copy_executor.

This is intentional.

A future live executor must still be designed separately and must require a fresh release candidate, verified backup, rollback guard armed before live changes, exact confirmation phrase, local console or physical recovery access, read-only live health probes, service activation in rehearsed order, and rollback cancellation only after all health checks pass.

## Safety rule

Do not run any future live apply command over SSH without confirmed local console or physical recovery access.
