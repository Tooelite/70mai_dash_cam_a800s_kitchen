#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
  bash util-linux grep sed gawk tar gzip xz-utils cpio \
  p7zip-full binwalk squashfs-tools dos2unix \
  build-essential pkg-config libfuse-dev  # FUSE2 (für littlefs-fuse)

# Optional (je nach Kitchen):
# sudo apt-get install -y xdelta3 u-boot-tools openssl libarchive-zip-perl
