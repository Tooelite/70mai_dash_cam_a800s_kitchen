#!/usr/bin/env bash
set -euo pipefail
req=(bash coreutils awk sed grep dd losetup binwalk 7z unsquashfs mksquashfs xz gzip)
miss=()
for c in "${req[@]}"; do
  if ! command -v "$c" >/dev/null 2>&1; then miss+=("$c"); fi
done
if ((${#miss[@]})); then
  echo "Missing tools: ${miss[*]}" >&2
  exit 1
fi
echo "All required tools found."
