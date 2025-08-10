# 70mai A800S (DR2800) Firmware Kitchen (English version)

This repository provides a small set of shell scripts to **unpack, patch and repack** a 70mai A800S (DR2800) firmware image.

> Upstream (Russian): boba-nopasaran-dr2800/Kitchen  
> This fork adds English documentation and Windows/WSL guidance.

---

## Supported target

- 70mai **A800S** (internal codename **DR2800**)

> Other models are untested. Flashing images intended for a different model can brick your device.

---

## Repository layout

```
0.0.0_example/
  origin/   # put the original firmware file(s) here
  work/     # working directory created by the scripts
  out/      # final patched firmware(s)
1mount.sh   # stage 1: unpack/mount/extract parts from origin
3patch.sh   # stage 2: apply your modifications
6pack.sh    # stage 3: repack/assemble final image(s)
7zip.sh     # helper for (re)packing archives/containers
dr2800      # board/profile marker used by the scripts (TBD: describe usage precisely)
README.md
```

---

## Prerequisites

Tested on **Debian 13** and **Windows 10/11 WSL2 (Ubuntu)**.

Install base tools:
```bash
sudo apt-get update
sudo apt-get install -y   bash util-linux grep sed gawk tar gzip xz-utils cpio   p7zip-full binwalk squashfs-tools dos2unix   build-essential pkg-config libfuse-dev
```

> `libfuse-dev` is required to build **littlefs-fuse** (the `lfs` userspace tool).
> Ensure `/sbin:/usr/sbin` are in your `PATH` (for `losetup`/`mount`):
```bash
echo 'export PATH="/sbin:/usr/sbin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Optional (useful for analysis/edge cases):
```bash
sudo apt-get install -y sleuthkit fdisk parted qemu-utils
# depending on your kitchen:
sudo apt-get install -y xdelta3 u-boot-tools openssl libarchive-zip-perl
```

After cloning:
```bash
chmod +x tools/*.sh || true
./tools/check-deps.sh
```

### LittleFS Support (misc.es Mount)

The `misc.es` partition on the A800S firmware is formatted with **LittleFS**.  
You need a userspace tool to mount it — either:

- **`lfs`** binary (standalone LittleFS tool, as used in this repo), or  
- **`littlefs-fuse`** (FUSE-based mount helper)

### Option 1 — Using provided `lfs` binary

If you already have the `lfs` binary built (e.g., from `littlefs-fuse` sources), simply copy it to a location in your `$PATH`:

```bash
sudo cp lfs /usr/local/bin/
sudo chmod +x /usr/local/bin/lfs
```

After this, `1mount.sh` will detect and use it automatically.

---

### Option 2 — Building from `littlefs-fuse` source

Install build dependencies:

```bash
sudo apt-get update
sudo apt-get install -y build-essential pkg-config libfuse-dev
```

Clone and build:

```bash
git clone https://github.com/osamy/littlefs-fuse.git
cd littlefs-fuse
make
```

This produces a binary named `lfs` in the repo root. Install it:

```bash
sudo cp lfs /usr/local/bin/
sudo chmod +x /usr/local/bin/lfs
```

### Notes

- The kitchen expects **LittleFS** for `misc.es`. Build or install a userspace tool:
  - Build `lfs` from `littlefs-fuse` with `libfuse-dev` (FUSE2) and copy to `/usr/local/bin/`.
  - Or install `littlefs-fuse` if your distro provides a package.
- `1mount.sh` will prefer `lfs` and fall back to `littlefs-fuse` if present.

---

### Mount behavior

- `1mount.sh` will mount `misc.es` using `lfs` with the following parameters:

```
block_size=131072
block_cycles=500
read_size=2048
prog_size=2048
cache_size=131072
block_count=11
lookahead_size=8
```

- Debug output from `lfs` is redirected to `misc.dir.mount.log`.
- To unmount manually:

```bash
fusermount3 -u misc.dir 2>/dev/null || fusermount -u misc.dir
```
---

**Optional (handy for analysis/edge cases):**
```bash
sudo apt-get install -y sleuthkit fdisk parted qemu-utils
```

> **TBD:** If the scripts call additional tools (e.g. `crc32`, `mkimage` for U-Boot, `openssl`), add them here.  
> After cloning, run `./tools/check-deps.sh` (see below) to verify your environment.

---

## Quick start

1. Place the **original firmware file(s)** into:
   ```
   0.0.0_example/origin/
   ```
2. Change into the example directory:
   ```bash
   cd 0.0.0_example
   ```
3. Run the stages from the repo root **in order**:
   ```bash
   ../1mount.sh
   ../3patch.sh
   ../6pack.sh
   ```
4. Find results in:
   ```
   0.0.0_example/out/
   ```

---

## Windows usage (WSL2)

1. Install **WSL2** with Ubuntu from the Microsoft Store.  
2. Clone the repo inside your Windows user folder.  
3. Open **Ubuntu (WSL)** and run the commands above.  
4. Optional: use the PowerShell wrapper:

Create `tools/wsl-run.ps1` with:
```powershell
Param([string]$ExampleDir = "0.0.0_example")
$ErrorActionPreference = "Stop"
wsl bash -lc "cd '$ExampleDir' && ../1mount.sh"
wsl bash -lc "cd '$ExampleDir' && ../3patch.sh"
wsl bash -lc "cd '$ExampleDir' && ../6pack.sh"
Write-Host "Done. Check '$ExampleDir/out'."
```

---

## What each stage does (high level)

- **`1mount.sh`**  
  Detects/extracts partitions or embedded file systems from the original image into `work/`.  
  Typical formats the kitchen deals with: **squashfs**, archives, kernel/ramdisk blobs.  
  > **TBD:** Document exact inputs (filenames, expected extensions) and the structure created in `work/`.

- **`3patch.sh`**  
  Applies your modifications (file replacements, config tweaks, scripted edits) on the unpacked tree.  
  > **TBD:** List supported patch points (e.g., rootfs overlay dir, config paths), and how to drop your own changes.

- **`6pack.sh`**  
  Reassembles the firmware, updates container(s)/checksums, writes final artifacts to `out/`.  
  > **TBD:** Document which checksums/headers are recalculated, and any constraints on size/offsets.

- **`7zip.sh`** (helper)  
  Convenience wrapper for (re)packing archives used by the above stages.

---

## Verifying outputs

Before flashing on device:

- **File integrity:** run `sha256sum` on produced files and keep a copy of sums.
- **Container sanity:** `binwalk -E <file>` should list expected sections; `unsquashfs -s <rootfs.squashfs>` prints metadata.
- **Size/offset constraints:** if the vendor image has fixed offsets, ensure the repacked parts **do not exceed** original sizes.
- **Signatures:** Some firmware bundles are **digitally signed**. Without the vendor’s private key, a modified bundle may be rejected.  
  - If repacking succeeds but the device refuses to flash, assume **signature enforcement** and stop.

---

## Known limitations / safety

- This kitchen does **not** bypass vendor signatures.  
- Do **not** flash if you are unsure your target is **A800S/DR2800**.  
- Always keep a copy of the **original** image in `origin/` and offline.
- You assume all risk; a failed flash can brick the device.

---

## Troubleshooting

- **Tool not found / command not found**  
  → Run `sudo apt-get install ...` as in *Prerequisites*. On macOS, use Homebrew equivalents (not officially supported).

- **binwalk finds nothing / high-entropy blocks only**  
  → The image could be encrypted/signed; repacking will likely fail on device.

- **Repack succeeds, device refuses update**  
  → Signature/CRC mismatch. Check whether the scripts update CRCs; if vendor signatures are used, repacking won’t help.

- **Permission denied when mounting (WSL)**  
  → Re-run with `sudo`. Ensure you’re operating on **files**, not physical devices.

---

## Obtaining modded firmware

https://4pda.to/forum/index.php?showtopic=994524&st=10540#entry115644824  
or  
https://4pda.to/forum/index.php?showtopic=994524

---

## Installing new firmware

Put firmware file FW_DR2800.bin and a FORCEUPD.txt textfile on SD card root. Power up your device. Wait till reboot.

---

## Base Mod Changelog this repo is based on 

### 2025-05-06

#### System
- **FTP enabled**
- **Telnet enabled**
- LAN addressing changed from `192.168.1.0/24` to `192.168.10.0/24`
- Wi-Fi SSID changed (independent of frequency band)
- Wi-Fi password set to constant: `00045242`
- Default settings adjusted
- FTP access to:
  - Russian voice pack: `/customize/audios/rus`
  - Logos: `/customize/logo`
- Time/date synchronization with GPS  
  *Note:* Hour is not set because the dashcam has no timezone awareness.
- `init.d` support (via FTP at `/customize/init.d`)
- `/customize` directory synchronized with SD card  
  The system still uses `/customize`, but it is synced to the SD card.  
  You can edit files on the SD card; inserting a blank SD card will not break the system — it will behave as if the previous SD card were still present.

#### Recorder / Storage
- Reserved space for **Normal + Lapse + Parking** increased from **80% to 85%**
- Reserved space for **Event** decreased from **16% to 10%**
- Added script to delete videos older than **7 days** and trim *Normal* to keep **5% free space**
- Video bitrate increased from **30 Mb/s to 50 Mb/s**
- `minQP` lowered from **20 to 16**
- Sensor parameters exposed for modification (via FTP or SD card at `/customize/iqfile`)

#### Localization
- Studio voiceover by **Olga Smotrova**
- ADAS voice phrases replaced with beeps
- Emergency recording phrases replaced with tones
- Some images translated
- Minor fixes to hyphenation and abbreviations

---

## Useful links

> Optional SD autorun (from older custom builds)  
> Some A800S custom firmware variants (e.g. 350d’s builds) support executing autorun_*.sh from the SD card on boot.  
> This base does not document SD-autorun; use init.d and /customize instead. If you need SD-autorun, port the hook from earlier builds (check rcS/init.d).
* https://github.com/350d/70Mai_A800S_Firmware

---

## Contributing

- Keep English docs clear and technical; prefer accuracy over brevity.  
- If you change script behavior, update the README accordingly.  
- Do **not** add a new license without upstream consent.

---

## License

The upstream repository does **not** include a license (all rights reserved by default).  
This fork keeps the original licensing situation. Do not reuse code outside GitHub without explicit permission.
