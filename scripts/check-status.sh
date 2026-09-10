#!/usr/bin/env bash
# Re-check the Android 17 / Pong porting situation. All facts in docs/ came from these checks.
# Usage: ./scripts/check-status.sh
set -uo pipefail

hr() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

hr "Pong official Evolution X build (Android 16 / bka)"
curl -sSL https://raw.githubusercontent.com/Evolution-X/OTA/bka/builds/Pong.json \
  | grep -E '"(maintainer|currently_maintained|filename|version|github)"'

hr "Is Pong on the Android 17 (cnb) branch yet?"
if curl -sfL -o /dev/null https://raw.githubusercontent.com/Evolution-X/OTA/cnb/builds/Pong.json; then
  echo "YES — Pong now has an official 12.x build."
else
  echo "NO — no Pong.json on the cnb branch."
fi

hr "Devices with any Evolution X 12.x build"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git clone -q --depth 1 --branch cnb --filter=blob:none \
  https://github.com/Evolution-X/OTA "$tmp/ota" 2>/dev/null \
  && ls "$tmp/ota/builds" | sed 's/\.json$//' | tr '\n' ' ' && echo \
  || echo "  (clone failed)"

hr "Official LineageOS devices per branch"
curl -sSL https://raw.githubusercontent.com/LineageOS/hudson/main/lineage-build-targets \
  | grep -vE '^\s*#|^\s*$' | awk '{print $3}' | sort | uniq -c | sort -rn
echo -n "Pong: "; curl -sSL https://raw.githubusercontent.com/LineageOS/hudson/main/lineage-build-targets | grep -i '^Pong ' || echo "not listed"

hr "Do Pong's cnb branches contain real Android 17 work, or are they placeholders?"
for repo in Evolution-X-Devices/device_nothing_Pong \
            Evolution-X-Devices/kernel_nothing_sm8475 \
            Evolution-X-Devices/vendor_nothing_Pong \
            Evolution-X-Devices/packages_apps_ParanoidGlyph; do
  bka=$(git ls-remote --heads "https://github.com/$repo" bka 2>/dev/null | awk '{print $1}')
  cnb=$(git ls-remote --heads "https://github.com/$repo" cnb 2>/dev/null | awk '{print $1}')
  if [ -z "$cnb" ]; then                 state="no cnb branch"
  elif [ "$bka" = "$cnb" ]; then         state="PLACEHOLDER (identical to bka)"
  else                                    state="diverged — inspect it"
  fi
  printf '  %-52s %s\n' "${repo#*/}" "$state"
done
echo "  (a 'diverged' device tree may still be BEHIND bka — check:"
echo "   git rev-list --count bka..cnb  in a clone)"

hr "Is LineageOS 24.0 / Evolution X 12.x still actively developed?"
for repo in LineageOS/android_build Evolution-X/vendor_evolution Evolution-X/manifest; do
  case "$repo" in LineageOS/*) br=lineage-24.0 ;; *) br=cnb ;; esac
  d=$(git clone -q --depth 1 --branch "$br" --filter=blob:none \
        "https://github.com/$repo" "$tmp/$(basename "$repo")" 2>/dev/null \
      && git -C "$tmp/$(basename "$repo")" log -1 --format=%cd --date=short 2>/dev/null)
  printf '  %-36s %-13s last commit: %s\n' "$repo" "$br" "${d:-unknown}"
done

hr "Has Pong appeared on a lineage-24.0 branch yet?"
git ls-remote --heads https://github.com/LineageOS/android_device_nothing_Pong 2>/dev/null \
  | awk '{print "  " $2}'
