# 2. The bring-up plan

Five phases. Do not skip Phase 1 — it is the one that saves you weeks.

---

## Phase 0 — Safety net (before touching anything)

You cannot debug a bring-up on a phone you are afraid to brick. Buy back your courage first:

1. Download the **stock Nothing OS 4.0 (B4.x) fastboot/OTA package** for Pong and keep it offline.
2. Download the current **EvoX 11.9 zip + its `recovery.img`** and keep those offline too.
   That is your known-good rollback, and it is the build you keep daily-driving.
3. Practise the full recovery path once, deliberately: flash recovery, sideload 11.9, boot.
   See [`03-device-and-recovery.md`](03-device-and-recovery.md).
4. Back up everything on the phone. A bring-up formats `/data` more than once.

Only after you have restored the phone from a deliberately broken state should you move on.

---

## Phase 1 — Build 11.9 (Android 16) unmodified, and boot it

**Do not start with Android 17.** Build the thing that is already known to work, exactly as the
maintainer builds it, and flash it.

```bash
cd ~/android/evox
source build/envsetup.sh
brunch Pong          # = breakfast Pong (lunch lineage_Pong-<release>-userdebug) + mka evolution
```

`breakfast Pong` runs roomservice, which reads `evolution.dependencies` from the device tree and
auto-clones the kernel, blobs, Glyph app and Dolby HAL. If that step fails, your problem is
network or manifest, not the port — fix it here where the answer is known.

This phase proves five things at once, none of which you want to be debugging simultaneously with
an Android 17 bug:

- your toolchain and Fedora deps are correct
- 16 GB of RAM can actually finish a build of this size
- your disk budget was right
- your signing keys and zip generation work
- your flash/recovery loop works and the phone boots your own build

**Only when a self-built 11.9 boots and behaves should you continue.** If you never get here,
you have learned something cheaply and lost nothing.

---

## Phase 2 — Cut real `cnb` branches

Today Pong's `cnb` branches are empty placeholders (see the README table). You will create the
real ones. Fork these to your own GitHub, since you cannot push to `Evolution-X-Devices`:

| Repo | Today | What you do |
|---|---|---|
| `device_nothing_Pong` | `cnb` is 28 commits *behind* `bka` | Branch `cnb` fresh **from `bka`**, not from the existing `cnb` |
| `kernel_nothing_sm8475` | `cnb` SHA == `bka` SHA | Branch from `bka`; expect real work here |
| `kernel_nothing_sm8475-devicetrees` | `lineage-23.2` only | New branch from `lineage-23.2` |
| `kernel_nothing_sm8475-modules` | `lineage-23.2` only | New branch from `lineage-23.2` |
| `proprietary_vendor_nothing_Pong` (GitLab) | `lineage-23.2` only | New branch; blobs stay B4.x — Nothing ships no A17 firmware |
| `packages_apps_ParanoidGlyph` | `cnb` behind `bka` | Branch from `bka` |
| `hardware_dolby` | Pong points at `NullDebris` `lunaris` (no A17 branch) | **Repoint to `Evolution-X-Devices/hardware_dolby` `cnb-aospa`** — that fork already has A17 branches |

Then re-init the tree on the Android 17 manifest and point `evolution.dependencies` at your forks:

```bash
repo init --depth=1 --partial-clone --clone-filter=blob:limit=10M \
  -u https://github.com/Evolution-X/manifest -b cnb -g default,-mips,-darwin,-notdefault
repo sync -c -j4 --no-clone-bundle --no-tags --optimized-fetch --prune
```

The `cnb` manifest is real and current: 1031 projects, default revision `lineage-24.0`,
AOSP tag `android-17.0.0_r1`, and only a couple of stragglers still pinned to `lineage-23.2`.
`vendor_evolution` `cnb` was last touched **2026-09-09** (12.2 uprev). The base is alive.

---

## Phase 3 — The actual Android 17 work

Nobody has done this for Pong, so here is the next best thing: the **real commit list from the
one device that completed the 11.x → 12.x jump** (`marble` / `sm8450-common`, 196 commits,
merged 2026-09-02). Strip the device-specific tuning and this is the shape of the work.

### The work items, in the order they will bite you

**1. Product initialisation.** `Pong: Initialize for Evolution X 12.x+` — bump product makefiles,
`evolution.dependencies` to `cnb`, drop stale overrides. On marble this also meant
`libinit: Drop fingerprint override` — A17 changed fingerprint spoofing handling.

**2. VINTF / FCM target level.** The framework compatibility matrix level must be raised for A17.
Nothing Phone (1)'s WIP A17 branch shows exactly this (`Set FCM level to 7`). Get this wrong and
`vintf` refuses to boot the vendor image.

**3. SELinux policy — expect the largest single chunk.** marble needed new/updated rules across
`hal_camera_default.te`, `hal_nfc.te`, `hal_power.te`, `hal_wifi.te`, `init.te`, `rild.te`,
`system_server.te`, `property.te`, `property_contexts`, `diag_router.te`, `dontaudit.te`, plus
`sepolicy/private/compat/202404/202404.ignore.cil`. A17 adds neverallows; your A16 blobs will
violate them.

**4. Blob compatibility patching.** A17 bumps library sonames; old blobs link against the old ones.
The upstream pattern is literal ELF patching, e.g. *"Patch libaudiocloudctrl to depend on
libtinyxml2-v34.so"*. Pong's tree already does this for `libtinyxml2-v34.so` and `libprotobuf` on
`lineage-23.2` — expect a new round for A17.

**5. QSSI system-stack blobs.** marble pulled *"WFD system stack from LA.QSSI.17.0.r1-06700-qssi.0"*.
Qualcomm's A17 QSSI release provides system-side blobs that work with your A16 vendor image. This
is the standard trick for exactly your situation — old vendor, new framework.

**6. Kernel.** Pong is on **5.10.246** GKI. It does not need to move to run A17, but it needs
rebuilding with the A17 toolchain (marble: *"Use Clang r563880c for kernel build"*) and may need
backports. This is the item with the most uncertainty — treat it as the main technical risk and
probe it early.

**7. Soong namespace churn.** `power-libperfmgr: Update included soong namespaces` — build-system
plumbing that breaks loudly and fixes easily.

**8. Nothing-specific glue.** Pong's tree carries `nothing-fwk`, the Glyph interface, and
`ParanoidGlyph`. None have A17 work. Nothing Phone (1)'s branch shows the pattern
(`update nt-fwk path`, `Move to Nothing fingerprint AIDL`). Budget real time here — this is the
part no other device's port can hand you.

### The debugging loop

Your first build will not boot. That is normal and not a setback. Work it in this order:

```bash
# Bootloop diagnosis — the kernel log from the previous boot survives a reboot
adb shell su -c 'cat /sys/fs/pstore/console-ramoops' > last_kmsg.txt
# or from EvoX recovery (adb works there):
adb shell dmesg > dmesg.txt

# SELinux denials — the single most common cause of a non-booting bring-up
grep -i 'avc: denied' dmesg.txt | sort -u
```

To separate "SELinux is blocking me" from "something is genuinely broken", build once with
`androidboot.selinux=permissive` (or `setenforce 0`). **If it boots permissive, your remaining
work is policy, not code.** Never ship or daily-drive a permissive build — fix the denials, then
re-enforce. A permissive Android build has effectively no app sandboxing.

Beyond boot, `logcat -b all` and `dmesg -w` are your tools; work one subsystem at a time
(display → touch → RIL → audio → camera → Glyph) and commit each fix separately with a clear
message. Small, atomic, well-titled commits are also exactly what a maintainership application is
judged on.

---

## Phase 4 — Validation before it becomes your daily driver

You said you cannot afford mistakes on a daily driver. This checklist is how you honour that.
Run **every** item on the A17 build while still keeping 11.9 flashable, for at least a week:

**Cannot-compromise (a failure here means do not daily-drive):**
- [ ] Calls in and out, both SIMs, speaker + earpiece + Bluetooth routing
- [ ] SMS/MMS send and receive; OTP messages arrive reliably
- [ ] Mobile data, VoLTE, VoWiFi, 5G attach; data survives a network handover
- [ ] Alarms fire with the screen off and the phone idle (Doze regressions are common and brutal)
- [ ] No random reboots over 72 h of normal use
- [ ] Battery drain overnight in airplane mode < ~1–2 %/h (catches wakelock regressions)
- [ ] Encryption/`/data` mounts cleanly across reboots
- [ ] Fingerprint and face unlock

**Should-work:**
- [ ] Camera: all lenses, video, slow-mo, third-party apps (CameraX)
- [ ] Glyph interface, notification lighting, charging indicator
- [ ] GPS lock cold and warm; Wi-Fi, BT audio, NFC, tap-to-pay
- [ ] Speaker/mic quality, Dolby, headset detection
- [ ] Play Integrity state you can live with (see `03-device-and-recovery.md`)

**Then, and only then:** switch. Keep the 11.9 zip and stock firmware on your laptop permanently.

---

## Phase 5 — Maintainership

Covered separately, because the rules are stricter than you expect and they affect what you may
publish. Read [`04-maintainership.md`](04-maintainership.md) **before** you post a build anywhere.
