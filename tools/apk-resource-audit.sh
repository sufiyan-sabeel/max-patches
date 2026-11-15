#!/usr/bin/env bash
# Audit a YouTube APK's resource table and DEX for the navigation-bar hook.
#
# Answers exactly three questions, with no guessing:
#   1. Does the APK ship a drawable named yt_fill_bell_black_24?
#   2. If not, which bell/notification drawables does it ship instead?
#   3. Which method holds the EnumMap.put of the notification tab, and does its shape still match
#      SetEnumMapFingerprint?
#
# Usage: tools/apk-resource-audit.sh <youtube.apk> [output-dir]
#
# Requires aapt2 (Android SDK build-tools), and either baksmali or jadx for the DEX part. It writes
# evidence files and prints a verdict; it never edits anything.

set -euo pipefail

APK="${1:?usage: $0 <youtube.apk> [output-dir]}"
OUT="${2:-apk-audit}"
mkdir -p "$OUT"

say() { printf '\n== %s\n' "$*"; }

if [ ! -f "$APK" ]; then
  echo "no such file: $APK" >&2
  exit 2
fi

say "identity"
sha256sum "$APK" | tee "$OUT/sha256.txt"
ls -l "$APK"
# The declared YouTube targets carry two accepted signing certificates; record what this APK is.
if command -v apksigner >/dev/null; then
  apksigner verify --print-certs "$APK" > "$OUT/certificates.txt" 2>&1 || true
  grep -i "SHA-256 digest" "$OUT/certificates.txt" | head -3 || true
else
  echo "apksigner not on PATH; certificate not recorded"
fi

AAPT2="$(command -v aapt2 || true)"
if [ -z "$AAPT2" ] && [ -n "${ANDROID_HOME:-}" ]; then
  AAPT2="$(ls -d "$ANDROID_HOME"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)"
fi
if [ -z "$AAPT2" ]; then
  echo "aapt2 not found: set ANDROID_HOME or put build-tools on PATH" >&2
  exit 3
fi

say "version and package"
"$AAPT2" dump badging "$APK" | grep -E "^package:|^application-label" | tee "$OUT/badging.txt"

say "the drawable the fingerprint looks for"
if "$AAPT2" dump resources "$APK" > "$OUT/resources.txt" 2>&1; then
  if grep -qE "drawable/yt_fill_bell_black_24\b" "$OUT/resources.txt"; then
    echo "PRESENT: drawable/yt_fill_bell_black_24"
    grep -E "drawable/yt_fill_bell_black_24\b" "$OUT/resources.txt" | head -5
  else
    echo "ABSENT: drawable/yt_fill_bell_black_24"
  fi

  say "every drawable whose name mentions bell or notification"
  grep -oE "drawable/[A-Za-z0-9_]*(bell|notification)[A-Za-z0-9_]*" "$OUT/resources.txt" \
    | sort -u | tee "$OUT/bell-drawables.txt"

  say "every id whose name mentions bottom_bar or navigation"
  grep -oE "(id|drawable|layout)/[A-Za-z0-9_]*(bottom_bar|navigation|pivot)[A-Za-z0-9_]*" \
    "$OUT/resources.txt" | sort -u | tee "$OUT/navigation-resources.txt"
else
  echo "aapt2 dump resources failed; see $OUT/resources.txt" >&2
fi

say "DEX: the method that builds the notification-tab icon map"
if command -v baksmali >/dev/null; then
  mkdir -p "$OUT/dex"
  ( cd "$OUT/dex" && unzip -o -q "../../$APK" "classes*.dex" && baksmali d classes.dex -o smali 2>/dev/null || true )
  if [ -d "$OUT/dex/smali" ]; then
    # The fingerprint expects: a drawable int constant, Integer.valueOf(int), EnumMap.put(Enum,Object)
    grep -rl "Ljava/util/EnumMap;->put" "$OUT/dex/smali" 2>/dev/null | head -20 \
      | tee "$OUT/enummap-methods.txt"
    echo "--- candidate methods, with their drawable constants"
    while read -r f; do
      [ -z "$f" ] && continue
      echo "### $f"
      grep -nE "const .*0x7f0[0-9a-f]+|Integer;->valueOf|EnumMap;->put" "$f" | head -12
    done < "$OUT/enummap-methods.txt"
  fi
else
  echo "baksmali not on PATH; skipping DEX inspection (install smali/baksmali or use jadx)"
fi

say "verdict"
{
  echo "APK:            $(sha256sum "$APK" | cut -d' ' -f1)"
  echo "bell drawables: $(wc -l < "$OUT/bell-drawables.txt" 2>/dev/null || echo 0)"
  echo
  echo "Next: open $OUT/bell-drawables.txt and find the drawable that carries the notification tab's"
  echo "filled icon. The patch needs a name that exists in THIS APK — do not substitute a different"
  echo "icon, and do not guess. Record the chosen name and its resource id in"
  echo "docs/YOUTUBE_21_45_82.md before changing any fingerprint."
} | tee "$OUT/verdict.txt"
