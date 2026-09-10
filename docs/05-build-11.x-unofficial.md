# 5. Building the current Android 16 build (11.11) unofficially, for yourself

Verified 2026-09-10. **This is the project to actually do first** — it supersedes Phase 1 in
[`02-bringup-plan.md`](02-bringup-plan.md), which said "build 11.9". Build 11.11 instead.

## Yes, you can. And it is allowed.

Evolution X's rule restricts **publishing** unofficial builds for a device that has an active
maintainer. It says nothing about compiling for your own phone. Building 11.11 for yourself is
fine; putting the zip on XDA or Telegram is not, unless hiroshi approves.

The build system agrees — from `vendor_evolution/config/version.mk`:

```make
EVO_BUILD_TYPE ?= Unofficial
```

Unofficial is the **default**, and the private signing keys are an optional include for it
(`-include vendor/evolution-priv/keys/keys.mk`; only `Official` hard-requires them). Nothing
blocks you.

## What has actually changed since Pong's 11.9

| Layer | Commits since 2026-08-02 | Notes |
|---|---|---|
| `vendor_evolution` (the EvoX layer) | **133** | but see below — 129 landed in one drop |
| `Evolution-X/manifest` | 3 | includes *"Forks for 2026-09 ASB"* (Aug 27) |
| **`device_nothing_Pong`** | **2** | *dolby vintf makefile*, *sensors: pass touch coords* — trivial |
| LineageOS platform (1031 projects) | continuous | the September ASB is the meaningful part |

The single most valuable delta is not a feature. It is this:

```
release: Bump Security String to 2026-08-01   (Aug 3)
release: Bump Security String to 2026-09-05   (Aug 19)
```

**Pong's 11.9 was built Aug 2 — before both.** Building today gets you roughly a month of
security patches your current install does not have.

### The 129-commit drop, and why 11.10 is not reachable

`vendor_evolution` `bka` has a **linear first-parent history with no merge commits**, and 129 of
those 133 commits share a single committer date, 2026-09-09. Checking the mainline state at
2026-08-19 shows `PRODUCT_VERSION_MAJOR = 23` and no `EVO_VERSION` at all — that is *plain
LineageOS*, not EvoX 11.10.

Conclusion: **the branch was rebased and force-pushed on 2026-09-09.** EvoX replayed their whole
stack onto a fresher `vendor_lineage` snapshot (whose own commits kept their August dates) and
uprevved to 11.11 in the same drop.

Practical consequence: **you cannot check out an August commit to build 11.10.** That state is no
longer reachable on this branch. Your realistic choice is 11.11 or nothing.

### Where Pong actually sits

Across all **87** devices on the Android 16 branch:

```
31 devices on 11.10      ← dodge (OnePlus 13) is here
15 devices on 11.9       ← Pong is here
41 devices on OLDER than 11.9  (down to 11.4.1)
 0 devices on 11.11
```

Pong is mid-pack, not neglected — nearly half of all EvoX Android 16 devices are on something
older than yours.

## Timing caution

**11.11 is one day old and zero devices have shipped it.** It landed together with a rebase of the
entire vendor tree. That combination is exactly when build breakage and regressions show up.

- Want to *learn the build*: go now, and expect to debug. That is the point.
- Want a *daily driver upgrade*: wait a week or two and let 87 maintainers shake it out first.

## The build

```bash
mkdir -p ~/android/evox && cd ~/android/evox

repo init --depth=1 --partial-clone --clone-filter=blob:limit=10M \
  -u https://github.com/Evolution-X/manifest -b bka -g default,-mips,-darwin,-notdefault
repo sync -c -j4 --no-clone-bundle --no-tags --optimized-fetch --prune

source build/envsetup.sh
export WITH_GMS=true      # omit entirely for the Vanilla (no-GApps) build
brunch Pong               # breakfast Pong + mka evolution;  use -j6 on 16 GB RAM
```

`breakfast Pong` runs roomservice, which reads `evolution.dependencies` from the device tree and
auto-clones the kernel, blobs, Glyph app and Dolby HAL. You do not clone those by hand.

Output: `out/target/product/Pong/EvolutionX-16.0-<date>-Pong-11.11-Unofficial.zip`

## The two things that will catch you out

**1. Test-keys.** Without `vendor/evolution-priv/keys/`, your build is signed with AOSP's public
test-keys. Any app signed with those same public keys gets **platform-level permissions**. Fine
for a test flash; not fine for a daily driver. Generate your own keys following the
[LineageOS signing guide](https://wiki.lineageos.org/signing_builds) — note it now covers ~75 APEX
keys as well as the usual `releasekey/platform/shared/media/...` set, and put them in
`vendor/evolution-priv/keys/` with a `keys.mk`.

**2. You cannot dirty-flash this over your official 11.9.** Different signing keys mean
platform-signed system apps change signature. You need a **clean flash — format data**. Back up
first, and plan for it rather than discovering it in recovery.

Everything else in [`03-device-and-recovery.md`](03-device-and-recovery.md) applies unchanged:
flash EvoX recovery, format data, `adb sideload` your zip, keep the official 11.9 zip as rollback.
