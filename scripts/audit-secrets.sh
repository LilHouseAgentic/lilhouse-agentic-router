#!/usr/bin/env bash
set -euo pipefail

echo "== LilHouse repo audit =="

FAIL=0

UNINSTALLER="bin/lilhouse-router-appliance-uninstall"
if [ -f "$UNINSTALLER" ]; then
  if grep -q -- "--i-am-in-a-throwaway-vm" "$UNINSTALLER" \
    && grep -q -- "refusing appliance uninstall" "$UNINSTALLER" \
    && grep -q -- "rm -rf" "$UNINSTALLER"
  then
    echo "throwaway uninstaller safety gate present"
  else
    echo "ERROR: throwaway uninstaller is missing expected safety gates"
    FAIL=1
  fi
fi

APPLIANCE_INSTALLER="bin/lilhouse-router-appliance-install"
if [ -f "$APPLIANCE_INSTALLER" ]; then
  if grep -q -- "Preparing base nftables ruleset" "$APPLIANCE_INSTALLER" \
    && grep -q -- "flush ruleset" "$APPLIANCE_INSTALLER" \
    && grep -q -- "systemctl enable --now nftables" "$APPLIANCE_INSTALLER"
  then
    echo "appliance installer base nftables safety block present"
  else
    echo "ERROR: appliance installer is missing expected base nftables safety block"
    FAIL=1
  fi
fi

EASY_INSTALLER="easy-install.sh"
if [ -f "$EASY_INSTALLER" ]; then
  if grep -q -- 'Resetting VM-live work reports' "$EASY_INSTALLER" \
    && grep -q -- 'rm -rf "$WORK_DIR/vm-live-prep" "$WORK_DIR/vm-live-work" "$WORK_DIR/vm-live-backup"' "$EASY_INSTALLER" \
    && grep -q -- 'WARNING: --vm-live installs/activates into / on this disposable VM.' "$EASY_INSTALLER"
  then
    echo "easy installer VM-live report cleanup safety block present"
  else
    echo "ERROR: easy installer is missing expected VM-live report cleanup safety block"
    FAIL=1
  fi
fi

COMMON_EXCLUDES=(
  --exclude-dir=.git
  --exclude-dir=import-review
  --exclude-dir=state-test
  --exclude-dir=runtime-test
  --exclude-dir=logs-test
  --exclude-dir=repo-staging
  --exclude='.env.example'
  --exclude='.gitignore'
  --exclude='audit-secrets.sh'
  --exclude='*.md'
)

echo
echo "== check for likely secrets =="
if grep -RniE \
  'api_key|token|secret|password|pushover|openai|bearer|authorization|icloud|gmail|webhook|private_key' \
  . \
  "${COMMON_EXCLUDES[@]}" \
  --exclude='lilhouse-router-appliance-uninstall' \
  --exclude='lilhouse-router-appliance-install'
then
  FAIL=1
else
  echo "none found"
fi

echo
echo "== check for local/private machine paths and identifiers =="
if grep -RniE \
  '2406:|fd[0-9a-f]|/mnt/das|/srv/starlink-health|/srv/lilhouse-autonomy|/home/pi|/home/pi5|raspberrypi|Gremlin|Maleny|Jordy|jortay|icloud' \
  . \
  "${COMMON_EXCLUDES[@]}"
then
  FAIL=1
else
  echo "none found"
fi

echo
echo "== check for risky command patterns =="
if grep -RniE \
  'mkfs|dd |reboot|shutdown|iptables|nft |apt |curl .*sh|wget .*sh|eval ' \
  . \
  "${COMMON_EXCLUDES[@]}" \
  --exclude='lilhouse-router-appliance-uninstall' \
  --exclude='lilhouse-router-appliance-install'
then
  FAIL=1
else
  echo "none found"
fi

echo
echo "== check for unexpected rm -rf =="
if grep -RniE 'rm -rf' . \
  --exclude-dir=.git \
  --exclude-dir=import-review \
  --exclude='audit-secrets.sh' \
  --exclude='smoke-test.sh' \
  --exclude='lilhouse-router-appliance-uninstall' \
  --exclude='easy-install.sh'
then
  FAIL=1
else
  echo "none found"
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "Audit passed."
else
  echo "Audit found items to review."
  exit 1
fi
