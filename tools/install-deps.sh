#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y bash coreutils util-linux binwalk p7zip-full \
  squashfs-tools gzip xz-utils tar grep sed awk dos2unix
