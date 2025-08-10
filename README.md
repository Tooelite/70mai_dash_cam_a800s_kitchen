# 70mai A800S Firmware Kitchen (English)

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

Linux or **Windows 10/11 with WSL2 (Ubuntu)**.

**Tools (install on Ubuntu/WSL):**
```bash
sudo apt-get update
sudo apt-get install -y bash coreutils util-linux binwalk p7zip-full   squashfs-tools gzip xz-utils tar grep sed awk dos2unix
```

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

## Helper scripts

Create `tools/check-deps.sh` to validate your environment:

```bash
#!/usr/bin/env bash
set -euo pipefail
req=(bash coreutils awk sed grep dd losetup binwalk 7z unsquashfs mksquashfs)
miss=()
for c in "${req[@]}"; do
  if ! command -v "$c" >/dev/null 2>&1; then miss+=("$c"); fi
done
if ((${#miss[@]})); then
  echo "Missing: ${miss[*]}" >&2
  exit 1
fi
echo "All required tools found."
```

Create `tools/install-deps.sh` (Ubuntu/WSL):

```bash
#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y bash coreutils util-linux binwalk p7zip-full   squashfs-tools gzip xz-utils tar grep sed awk dos2unix
```

> Make both scripts executable: `chmod +x tools/*.sh`

---

## Contributing

- Keep English docs clear and technical; prefer accuracy over brevity.  
- If you change script behavior, update the README accordingly.  
- Do **not** add a new license without upstream consent.

---

## License

The upstream repository does **not** include a license (all rights reserved by default).  
This fork keeps the original licensing situation. Do not reuse code outside GitHub without explicit permission.
