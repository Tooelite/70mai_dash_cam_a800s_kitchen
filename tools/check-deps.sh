#!/usr/bin/env bash
set -euo pipefail

# Muss vorhanden sein:
req=(bash awk sed grep dd losetup mount umount gzip xz tar cpio binwalk 7z unsquashfs mksquashfs)
miss=()
for c in "${req[@]}"; do command -v "$c" >/dev/null 2>&1 || miss+=("$c"); done
if ((${#miss[@]})); then
  echo "Missing tools: ${miss[*]}" >&2
  echo "Run: ./tools/install-deps.sh" >&2
  exit 1
fi

# LittleFS (mind. eines):
if ! command -v lfs >/dev/null 2>&1 && ! command -v littlefs-fuse >/dev/null 2>&1; then
  echo "Missing LittleFS userspace tool (install littlefs-fuse or build './lfs')." >&2
  exit 1
fi

# sbin im PATH + loop-modul
case ":$PATH:" in *:/sbin:*|*:/usr/sbin:* ) :;; *) echo "WARN: add /sbin:/usr/sbin to PATH";; esac
lsmod | grep -q "^loop" || echo "INFO: 'loop' kernel module not loaded (modprobe loop)"

echo "All required tools present."
