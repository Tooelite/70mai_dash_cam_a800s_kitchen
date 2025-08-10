#!/usr/bin/env bash
export PATH="/sbin:/usr/sbin:$PATH"
export LANG=C

fail() { echo "ERROR: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Missing tool: $1"; }

# Required tools
need gzip
need cpio
need unsquashfs
need binwalk || true

safe_umount() {
  local mnt="$1"
  fusermount3 -u "$mnt" 2>/dev/null || fusermount -u "$mnt" 2>/dev/null || true
  umount "$mnt" 2>/dev/null || true
}

cleanup() { safe_umount "0.0.0_example/proj/misc.dir" || true; }
trap cleanup EXIT

bindir="$(dirname "$(realpath "$0")")"
imagename="FW_DR2800.bin"

mkdir -p "0.0.0_example/proj"
pushd "0.0.0_example/proj" >/dev/null

# Pre-clean
safe_umount "misc.dir"
rm -rf rootfs.es rootfs.es.gz rootfs.dir customer.es customer.dir misc.es misc.dir || true

# Origin file check
[ -f "$bindir/0.0.0_example/origin/$imagename" ] || \
  [ -f "$bindir/../origin/$imagename" ] || \
  [ -f "../origin/$imagename" ] || fail "Missing origin image '$imagename'"

origin="../origin/$imagename"
[ -f "$origin" ] || origin="$bindir/0.0.0_example/origin/$imagename"

[ -x "$bindir/dr2800" ] || fail "Extractor '$bindir/dr2800' not found/executable"

echo ">> Extracting blobs from: $origin"
"$bindir/dr2800" e "$origin" rootfs.es customer.es misc.es

echo ">> Ungzip rootfs.es..."
mv rootfs.es rootfs.es.gz
gzip -d rootfs.es  # trailing garbage warning is normal

echo ">> Uncpio rootfs.es..."
mkdir -p rootfs.dir
pushd rootfs.dir >/dev/null
cpio -id < ../rootfs.es
popd >/dev/null

echo ">> Extract customer (squashfs)..."
mkdir -p customer.dir
unsquashfs -f -d customer.dir customer.es

echo ">> Mount misc (LittleFS)..."
mkdir -p misc.dir
lfs --block_size=131072 --block_cycles=500 --read_size=2048 --prog_size=2048 \
    --cache_size=131072 --block_count=11 --lookahead_size=8 \
    misc.es misc.dir 2>misc.dir.mount.log

if mountpoint -q misc.dir; then
    echo "MOUNTED"
else
    echo "ERROR: misc.dir not mounted" >&2
    echo "---- misc.dir.mount.log ----" >&2
    sed -n '1,50p' misc.dir.mount.log >&2
    exit 1
fi

# Optional content preview
ls -la misc.dir | head
find misc.dir -maxdepth 2 -type f -printf '%p\t%k KB\n' | head

popd >/dev/null
echo "== DONE: unpack/mount complete =="
