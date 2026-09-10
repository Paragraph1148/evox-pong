# 3. The device: unlocking, flashing, and always getting back

## What Pong actually is, partition-wise

Verified from `device_nothing_Pong/BoardConfig.mk`:

- **A/B (seamless) device with Virtual A/B OTA**, gz compression, `android_t_baseline`
- **Dynamic partitions** inside a 7.5 GB `super`: `system system_ext product vendor odm vendor_dlkm`
- **Dedicated slotted `recovery` partition** (100 MB) — alongside `boot`, `dtbo`, `vendor_boot`
- **AVB enabled** (`BOARD_AVB_ENABLE := true`, vbmeta flags 3)
- **GKI kernel** (`BOARD_USES_GENERIC_KERNEL_IMAGE := true`), 5.10.246

The A/B layout is your friend. There are two complete copies of the OS, and the bootloader will
fall back to the other slot after repeated boot failures. A bad flash is usually a slot switch
away from recovery, not a brick.

```bash
fastboot getvar current-slot
fastboot --set-active=a      # or b — the manual escape hatch
```

## Boot modes

- **Recovery:** powered off, hold **Volume Up + Power**
- **Bootloader / fastboot:** powered off, hold **Volume Down + Power**

Learn these by muscle memory before you need them at 1 a.m.

---

## Unlocking the bootloader

This **erases all data**. Do it once, at the start, with backups already taken.

```bash
# On the phone: Settings → About → tap Build number 7×
#   → Developer options → enable "OEM unlocking" AND "USB debugging"
adb reboot bootloader
fastboot flashing unlock          # confirm on the device screen with volume/power
```

The phone factory-resets and will now show an "unlocked bootloader" warning at every boot.
That warning is permanent and normal.

### What unlocking costs you — read this properly

This is the part that matters most for a daily driver, and it is not reversible while unlocked:

**Widevine drops from L1 to L3.** Netflix, Prime Video, Disney+ and similar lose HD/FHD playback
and fall back to 480p. There is a community project (`Ubuntuify/nothing-widevine`) that
reprovisions the TEE to restore L1 on Nothing phones; treat it as unsupported, verify it still
works for A17 before relying on it, and do not let it be the reason you unlock.

**Play Integrity loses device attestation.** Basic integrity can often be satisfied; `DEVICE`
and `STRONG` integrity cannot, because they are hardware-backed and keyed to a locked bootloader.
Evolution X does spoof the build fingerprint (`vendor_evolution` `cnb` carries
*"Spoof BuildFingerprint as Pixel Canary"*), which helps with some checks and **does not** produce
a genuine hardware attestation.

**Concretely: expect some banking and payment apps to refuse to run.** If you depend on UPI apps,
a banking app, or a government/ID app that enforces device integrity, test *your specific apps*
before you commit. This is the single most common reason people regret unlocking a daily driver —
much more than any ROM bug. If a must-have app hard-fails, the honest answer is that this device
should not be your unlocked daily driver.

**On relocking with custom AVB keys:** technically possible on some Qualcomm devices
(`fastboot flash avb_custom_key`). A key mismatch on a locked bootloader is one of the few ways to
produce a genuine hard brick. Do not attempt it on the phone you depend on.

---

## Installing an Evolution X build

Evolution X's own recovery is required. **You may not substitute TWRP/OrangeFox/PBRP** — that is
an explicit project rule, and their OTA/installer expects their recovery. Pong's declared
initial-installation image list is exactly one image: `recovery`.

Coming from stock:

```bash
adb reboot bootloader
fastboot flash recovery recovery.img       # slotted; flash to both slots if you like:
# fastboot flash recovery_a recovery.img && fastboot flash recovery_b recovery.img
fastboot reboot recovery
```

Then in EvoX recovery:

1. **Factory reset → Format data/factory reset** (required coming from stock or across major
   Android versions — encryption metadata changes)
2. **Apply update → Apply from ADB**
3. On the host: `adb sideload EvolutionX-...-Pong-....zip`
4. Reboot

For a later update of the same build line, sideload the new zip without formatting data.

### Firmware matters

The device tree pins a firmware level — currently `Pong_B4.1-260618-1026`. The blobs and the
ROM are built against that. Running a much older Nothing OS firmware under a newer ROM causes
exactly the sort of subtle instability (modem drops, camera failures, random reboots) that is
miserable to debug. **Update to the matching stock Nothing OS build first, then flash.**

Note that this ceiling is now permanent: Nothing OS 4.0 / Android 16 is Pong's last OS upgrade,
with security patches to 2027. Your A17 build will always be running on A16-era firmware.

---

## Your recovery drill

Practise this *before* you need it, as Phase 0 says. Deliberately break the phone and fix it.

**If a build bootloops:**
```bash
fastboot getvar current-slot
fastboot --set-active=<other slot>     # boot the previous, working OS
```

**If both slots are bad:** boot to EvoX recovery (Vol Up + Power), format data, sideload your
known-good 11.9 zip.

**If recovery itself is broken:** boot to fastboot (Vol Down + Power) and reflash `recovery.img`.
Fastboot survives almost everything short of a corrupted bootloader.

**If everything is broken:** flash the stock Nothing firmware package you saved in Phase 0.

Keep these on your laptop, permanently, in one folder: stock firmware, EvoX 11.9 zip, its
`recovery.img`, and `platform-tools`. Not in cloud storage you might not be able to reach from a
phone-less situation.
