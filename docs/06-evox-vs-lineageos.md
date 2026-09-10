# 6. Evolution X or LineageOS + NikGapps? And should you self-build at all?

Verified 2026-09-10.

## Recommendation: Evolution X, official 11.9, flashed and left alone.

Not because it is objectively better than LineageOS — because of the constraints you set: no root,
no Magisk modules, no flashing things to inactive slots, no ongoing maintenance.

### The two features you named are built in, without root

Both live in Evolver, Evolution X's own settings app:

| Feature | Where | Root needed? |
|---|---|---|
| Remove screenshot / screen-record restrictions in all apps | `miscellaneous_ignore_window_secure` — *"Remove screenshot and screen recording restrictions for all apps"* | **No** |
| Play Integrity Fix + **TrickyStore**, with a per-app target picker | `PlayIntegrityFix.kt`, `TrickyStore.kt`, `TrickyStoreAppSettings.kt` | **No** |

Also present: `miscellaneous_unlimit_screenrecord`, `miscellaneous_app_downgrade`,
`miscellaneous_block_wallpaper_dimming`, `miscellaneous_pairip_activity_block`, plus
lockscreen / statusbar / QS / powermenu / themes / notifications sections.

On LineageOS, FLAG_SECURE bypass needs LSPosed, and Play Integrity needs Magisk +
PlayIntegrityFix + TrickyStore as modules. Both need root. That is exactly the hassle you ruled
out — and each is a thing that breaks on updates and needs re-fixing.

### GApps: baked in, so OTA actually works

`vendor_evolution/config/common_full_phone.mk`:

```make
WITH_GMS ?= true
```

GApps are part of the ROM image on the default phone build. OTA updates just apply.

With LineageOS + NikGapps, every nightly replaces the system image. You either trust addon.d
survival (fragile on A/B + dynamic partitions) or re-sideload NikGapps after each update. That is
a recurring chore forever, which is precisely what you said you did not want.

## The honest counterpoint

LineageOS is currently **ahead of Evolution X on this device**:

| | Latest build | Security patch level |
|---|---|---|
| LineageOS Pong nightly | **2026-09-09** (weekly) | **2026-08-01** |
| Evolution X Pong 11.9 | 2026-08-02 (when the maintainer builds) | **July 2026** |

LineageOS builds Pong weekly and automatically; Evolution X builds when hiroshi has time. If
monthly security cadence is your single highest priority, LineageOS wins and you accept the GApps
chore and the root requirement for your two features.

For most people that trade goes the other way: a month's patch lag matters less than adding
Magisk, LSPosed and two modules to a daily driver — that is a larger change in attack surface than
the lag it fixes.

## What is in 11.10 and 11.11

**11.10 (Aug 2026)** — not a feature release. August security rollup plus per-device tree updates.

> Note: the "Android 16 QPR2" line in device changelogs is maintainer free-text, not a version
> signal. Devices on 11.9 report it too, and some on 11.10 do not. The reliable signal is the
> patch month.

**11.11 (2026-09-09)** — the substantial one. From the 129-commit drop:

- **Pixel polish:** Pixel 10 boot animation, monet dynamic boot animations, google-sans-flex fonts,
  CD1A wallpaper, AOD wallpaper, extended wallpaper effect, extendible theme manager
- **SystemUI:** background blur on by default, themed notification icons, clock reactive variants,
  "create any bubble", more smartspace features, glanceable-hub media, biometric dialog tuning
- **Performance:** two SurfaceFlinger VRR flags, ART/dexpreopt boot-image tuning, reduced
  system_server verbosity, hwc composition strategy changes
- **Stability hacks:** suppress ASI crash dialogs, SystemUI ANRs, Google TTS FC warnings
- **Default changes:** NFC off by default, dreams disabled, Seedvault-as-default reverted
- **Build fingerprint spoofed as Pixel Canary**

Zero of the 87 Android 16 devices have shipped 11.11 yet.

## Should you self-build for daily use? No.

This contradicts the framing in [`05-build-11.x-unofficial.md`](05-build-11.x-unofficial.md), so
state it plainly: **self-building and hassle-free daily driving are opposed goals.**

Flashing official 11.9 gets you:

- EvoX-signed → the in-ROM updater works, no clean flash later
- GApps included, both wanted features present, no root
- 11.11 arrives as an OTA when the maintainer builds it — zero effort

Self-building gets you a month of patches sooner and costs you the OTA path entirely: self-signed
means a clean flash to switch to it, and then *every* future update is a manual build you must
remember to do.

So: **flash official 11.9 and call it a day.** Build only when the goal is learning or the
Android 17 port — ideally not on the phone you depend on.

## Why the blobs are not on the newest Nothing OS

Your premise here is off — **neither tree is on NOS 3.2.** What you saw is old git history.

| Tree | `proprietary-files.txt` header | Extracted |
|---|---|---|
| Evolution X Pong | `V4.1-260618-1026` — **NOS 4.1** | 2026-07-31 |
| LineageOS Pong | `B4.0-251226-1110` — **NOS 4.0** | 2026-01-31 |

The `Update from NOS V3.2-*` commits date to **2025** (Sept 2025 in LineageOS's tree; Jan 2026 in
EvoX's, which then moved to 4.0 on Feb 1 and 4.1 on Jul 31). They are simply the visible history,
not the current state.

Two details worth knowing:

1. **EvoX's blobs are newer than LineageOS's** here — 4.1 versus 4.0. Another point in EvoX's
   favour for this specific device.
2. **Inside EvoX's tree the two files disagree:** blobs from `V4.1-260618-1026`, but
   `proprietary-firmware.txt` (abl, aop, modem, bluetooth, cpucp…) is pinned at
   `V4.0-251119-1654`. Vendor blobs and firmware images are extracted separately. Firmware changes
   rarely and re-pinning it risks bootloader and modem breakage, so it deliberately lags.

**Why blobs lag stock at all:** a custom ROM replaces `system`/`product` but keeps the vendor
partition extracted from one specific stock firmware. Every blob bump risks breaking HAL
compatibility with the rest of the tree, so maintainers move on their own schedule, not Nothing's.
A tree "still on" an older firmware is usually a stability decision, not neglect.
