# 1. Build environment — honest assessment and Fedora setup

## Your hardware vs. what this actually needs

| | LineageOS guidance for this branch generation | Yours | Verdict |
|---|---|---|---|
| RAM | 64 GB recommended | 16 GB DDR4 | **Workable, but the main source of pain** |
| Storage | 400 GB free | 512 GB total, shared with Fedora | **The hard constraint — plan it first** |
| CPU | more cores = linearly faster | i7-1255U (2P + 8E, 12 threads, ~15–28 W sustained) | Slow but fine |

None of this is a blocker. All of it changes how you should work.

### Storage — decide this before you sync anything

A 512 GB drive is ~476 GiB usable. After Fedora and your data, assume **~420 GiB free**.

Rough budget for one device, one Android version:

```
source tree (partial clone)     60–90 GB
out/ (one device, A17, gapps)  120–180 GB
ccache                          25–50 GB
--------------------------------------------
total                          205–320 GB
```

It fits — **with a partial clone**. With a full clone (~150 GB source) you are at ~370 GB and
one bad day from a disk-full build failure at hour nine. Two things follow:

1. **Always sync shallow/partial.** Commands below.
2. **You get one device and one Android version at a time.** If you keep an 11.9 tree *and* a
   12.x tree, you will not fit. Budget for one, or get an external SSD.

If you can spend money, a 1 TB USB 3.2 Gen 2 NVMe enclosure (~10 Gbps) is the single highest-value
purchase for this project. It removes the constraint entirely and is fast enough for AOSP builds.
Do not use a spinning USB drive — build times roughly double.

**Fedora/btrfs note:** Fedora defaults to btrfs with zstd compression, which saves real space here.
But copy-on-write fragments badly under an AOSP build. Disable CoW on the output dir while it is
still empty:

```bash
mkdir -p ~/android/evox/out && chattr +C ~/android/evox/out
```

### RAM — how to survive 16 GB

The AOSP build system assumes it can start one heavy process per core. With 12 threads and 16 GB,
the default will OOM you during `soong_build`, `metalava`, or R8. Fixes, in order of importance:

```bash
# 1. Cap parallelism. This is the big one. Start at 6; drop to 4 if you still OOM.
m -j6

# 2. Give yourself real swap on NVMe. Fedora's default zram (~8 GB) is not enough alone.
sudo fallocate -l 48G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab

# 3. Keep zram too — it absorbs the small stuff. Fedora enables it by default; verify:
zramctl
```

Swap on NVMe is slow but it is the difference between "build takes 3 extra hours" and "build dies
at hour 9 and you start over". Take the trade.

**Expected build times on your machine** (be mentally prepared for these):

- Clean build from scratch: **8–16 hours**
- Incremental after a small device-tree change: 20–90 minutes
- `repo sync` of a fresh tree: 1–3 hours depending on your connection

The i7-1255U is a 15 W-class chip in a thin chassis; it will thermally throttle to E-core speeds
for most of a long build. Build on AC power, on a hard surface or a stand, and do not expect to
use the laptop for anything else meanwhile.

---

## Fedora setup

AOSP ships its own prebuilt clang and JDK, so you do **not** need to match Ubuntu's JDK version.
You mostly need build glue, 32-bit libs, and a few tools Fedora names differently.

```bash
sudo dnf install -y @development-tools \
  bc bison ccache curl flex gcc gcc-c++ git git-lfs gnupg2 gperf \
  ImageMagick lz4 lzop ncurses-devel openssl-devel perl-Digest-SHA \
  python3 python3-pip rsync schedtool squashfs-tools unzip wget xz zip \
  zlib-devel libxml2 libxslt dtc erofs-utils android-tools jq \
  ncurses-compat-libs glibc-devel.i686 libstdc++-devel.i686 \
  zlib-devel.i686 ncurses-devel.i686
```

`ncurses-compat-libs` and the `.i686` packages matter — some AOSP prebuilts still want
`libncurses.so.5` and 32-bit glibc, and the failures they produce are cryptic.

Install the `repo` launcher from Google directly (Fedora's packaged one lags):

```bash
mkdir -p ~/bin && curl -s https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo && echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
```

Git identity and ccache:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"

echo 'export USE_CCACHE=1'                  >> ~/.bashrc
echo 'export CCACHE_EXEC=/usr/bin/ccache'   >> ~/.bashrc
source ~/.bashrc
ccache -M 30G && ccache -o compression=true
```

30 GB compressed is the right size for a single device on a tight disk. ccache turns a
rebuild-after-sync from hours into tens of minutes — it is not optional on this hardware.

---

## Syncing the source (partial clone — use this, not the wiki default)

```bash
mkdir -p ~/android/evox && cd ~/android/evox

# Start on the Android 16 branch first. See docs/02 for why.
repo init --depth=1 --partial-clone --clone-filter=blob:limit=10M \
  -u https://github.com/Evolution-X/manifest -b bka -g default,-mips,-darwin,-notdefault

repo sync -c -j4 --no-clone-bundle --no-tags --optimized-fetch --prune
```

What these flags buy you:

- `--partial-clone --clone-filter=blob:limit=10M` — fetch large blobs lazily. Biggest space saver.
- `--depth=1` — no history. You lose `git log` on AOSP repos; you keep full history where it
  matters because you will clone the device trees separately as normal repos.
- `-c` — current branch only, not every branch of all 1031 projects.
- `-g default,-mips,-darwin,-notdefault` — skip groups you will never build.
- `-j4` — more parallel fetches will saturate a home connection and cause retries, not speed.

If a sync dies partway (it will, at least once), just re-run the same `repo sync` line. It resumes.

**One caveat on `--depth=1`:** if you later need to cherry-pick upstream commits by hash, a shallow
repo cannot see them. Fix it per-repo when it comes up:
`git fetch --unshallow` in that one project, not across the tree.

---

## Verify before you go further

```bash
free -h        # confirm swap is active and large
df -h ~        # confirm 300 GB+ free
ccache -s      # confirm ccache is wired up
nproc          # 12 — but you will build with -j6
```

Next: [`02-bringup-plan.md`](02-bringup-plan.md)
