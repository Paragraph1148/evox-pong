# Evolution X 12.x (Android 17) for Nothing Phone (2) — Feasibility & Bring-Up Plan

Research snapshot: **2026-09-10**. All facts below were verified against live git remotes
and upstream JSON, not from memory. Re-verify before acting — this moves weekly.

---

## TL;DR

**Yes, it is possible unofficially for personal use.** No, it is not a rebase — it is a real
Android 17 device bring-up that nobody has started yet.

**Correct one assumption first:** Evolution X 12.1 is **Android 17**, not Android 16.
Your device is not "stuck on an old 11.9" — 11.9 *is* the current Android 16 release, and
Android 16 is where Nothing officially ends support for Pong. Going to 12.x means porting
Pong to a major Android version it has never run.

**And it is much earlier days than it looks.** Only **3 devices in the entire Evolution X
project** have a 12.x build. **Zero of LineageOS's 315 official devices** are on the
Android 17 branch yet. You would not be catching up to the pack; you would be near the front of it.

---

## Verified facts

| Question | Answer | Source of truth |
|---|---|---|
| What is EvoX 11.9? | Android **16**, branch `bka`, LineageOS `lineage-23.2` base | `Evolution-X/manifest` @ `bka` → `android-16.0.0_r4` |
| What is EvoX 12.1/12.2? | Android **17**, branch `cnb`, LineageOS `lineage-24.0` base | `Evolution-X/manifest` @ `cnb` → `android-17.0.0_r1` |
| Pong's current official build | `EvolutionX-16.0-20260802-Pong-11.9-Official.zip` | `Evolution-X/OTA` @ `bka` → `builds/Pong.json` |
| Pong's maintainer | `hiroshi.` (GitHub `joshuah345`), flagged **`currently_maintained: true`** | same JSON |
| Devices with any EvoX 12.x build | **3**: `marble`, `raphael`, `venus` | `Evolution-X/OTA` @ `cnb` → `builds/` |
| Official LineageOS devices on `lineage-24.0` | **0 of 315** (201 on 23.2, 114 on 22.2) | `LineageOS/hudson` → `lineage-build-targets` |
| Pong on LineageOS | `lineage-23.2` is the newest branch; no `lineage-24.0` | `LineageOS/android_device_nothing_Pong` |
| Nothing's official support | Android 16 (Nothing OS 4.0) is the **final** OS upgrade; security patches to 2027 | Nothing update policy |
| SoC / kernel | SM8475 (Snapdragon 8+ Gen 1), kernel **5.10.246** GKI | `android_kernel_nothing_sm8475` @ `lineage-23.2` |
| Blob source | `gitlab.com/joshuah345/proprietary_vendor_nothing_Pong` @ `lineage-23.2` | `evolution.dependencies` |
| Firmware the tree targets | `Pong_B4.1-260618-1026` | device tree commit, 2026-07-09 |

### The critical finding

Pong's Evolution X repos **do have `cnb` branches — and every one of them is an empty
placeholder.** This is the whole story:

```
device_nothing_Pong      cnb is an ANCESTOR of bka   → 0 unique commits, 28 commits BEHIND
kernel_nothing_sm8475    cnb SHA == bka SHA          → byte-identical
vendor_nothing_Pong      cnb SHA == bka SHA          → byte-identical
packages_apps_ParanoidGlyph  cnb behind bka          → 0 unique commits
```

`cnb`'s tip commit on the device tree is *"Initialize for Evolution X 11.6.x"* from April.
The branches were cut and never touched. **Not one line of Android 17 work exists for Pong.**

That is good news and bad news. Bad: there is no half-finished port to pick up. Good: nothing
is blocked, nobody has hit a wall and given up. The work simply has not been started.

### What Nothing's "Snapdragon 8+ Gen 1 can't do Android 17" claim actually means

Press coverage says the port is impractical because Qualcomm no longer supports the kernel.
That is true **for an OEM**, who needs Qualcomm to ship a new BSP and pass GMS/CTS.
It is not true for a custom ROM. Custom ROMs run new Android on old vendor blobs routinely —
that is exactly what Treble and the vendor-interface compatibility guarantees are for. You will
run an Android 17 framework on Android 16 (B4.x) vendor blobs and a 5.10 kernel. That works.
It is the normal way this is done. It is also where all your bugs will come from.

---

## Guides in this repo

| Doc | What it covers |
|---|---|
| [`docs/01-build-environment.md`](docs/01-build-environment.md) | Honest hardware assessment, Fedora setup, disk strategy, how to survive 16 GB RAM |
| [`docs/02-bringup-plan.md`](docs/02-bringup-plan.md) | The phased plan, and the concrete Android 17 work items derived from a finished port |
| [`docs/03-device-and-recovery.md`](docs/03-device-and-recovery.md) | Unlocking, flashing, A/B slots, and how to always get back to a working phone |
| [`docs/04-maintainership.md`](docs/04-maintainership.md) | The official rules — including the one that blocks you today |

---

## Read this before you start

Two things will decide whether this goes well.

**1. Your laptop is under-specced for this, and storage is the hard limit.** LineageOS's own
guidance for this branch generation is 64 GB RAM and 400 GB of disk. You have 16 GB and a
512 GB drive shared with Fedora. It is doable — people build on 16 GB — but see
[`docs/01-build-environment.md`](docs/01-build-environment.md) before you sync a single repo.
Getting the disk strategy wrong means discovering it 100 GB into a sync.

**2. Do not daily-drive your own first Android 17 build.** You said this is your daily driver
and that you cannot afford mistakes. Those two goals are in tension with being the first person
to run Android 17 on this device. The resolution is sequencing, not caution: keep 11.9 as your
daily driver, treat the A17 build as a project, and only switch when it passes the validation
checklist in [`docs/02-bringup-plan.md`](docs/02-bringup-plan.md). Pong is an A/B device, which
gives you a real safety net — learn how to use it before you need it.
