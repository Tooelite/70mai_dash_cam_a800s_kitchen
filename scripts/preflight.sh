#!/usr/bin/env bash
set -euo pipefail
export PATH="/sbin:/usr/sbin:$PATH"

echo "== kitchen preflight =="
./tools/check-deps.sh

# Loop-Modul laden (idempotent)
if ! lsmod | grep -q "^loop"; then
  command -v modprobe >/dev/null 2>&1 && sudo modprobe loop || true
fi

echo "Preflight OK"
