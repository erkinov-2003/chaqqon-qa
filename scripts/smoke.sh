#!/usr/bin/env bash
# Installs the APK on the running emulator, launches it and records
# screenshots, logcat and the crash buffer into out/.
# Fails when the install fails, the app is gone after launch, or it crashed.
set -uo pipefail

PKG=uz.chaqqon.med
OUT=out
mkdir -p "$OUT"

APK=$(ls apk/*.apk | head -n 1)
echo "APK: $APK ($(du -h "$APK" | cut -f1)), emulator ABI: $(adb shell getprop ro.product.cpu.abi)"

# -g grants every runtime permission up front, so no dialog covers the screen.
if ! adb install -r -g "$APK" > "$OUT/install.txt" 2>&1; then
  cat "$OUT/install.txt"
  echo "::error::Install failed"
  exit 1
fi
cat "$OUT/install.txt"

adb logcat -c
adb logcat -b crash -c || true
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null

shot() { adb exec-out screencap -p > "$OUT/$1.png"; }
sleep 20; shot 01-after-20s
sleep 25; shot 02-after-45s

adb logcat -d > "$OUT/logcat.txt"
adb logcat -d -b crash > "$OUT/crash.txt" || true
adb shell dumpsys activity activities | grep -E "topResumedActivity" > "$OUT/top-activity.txt" || true
cat "$OUT/top-activity.txt"

status=0
if [ -z "$(adb shell pidof "$PKG" | tr -d '\r')" ]; then
  echo "::error::$PKG is not running 45 s after launch"
  status=1
fi
# The run log is public — the crash itself is only in the encrypted results.
if grep -q "$PKG" "$OUT/crash.txt"; then
  echo "::error::Crash in the crash buffer — see crash.txt in the results"
  status=1
fi
[ $status -eq 0 ] && echo "Smoke test passed: installed, launched, still running, no crash."
exit $status
