# chaqqon-qa

Android smoke test for the Chaqqon app on a GitHub Actions emulator (x86_64, API 34).
The app source lives elsewhere; this repo only holds the workflow.

The repo is public (free Actions minutes), so the APK and the results are encrypted.
The key is the `APK_PASSWORD` Actions secret; a copy lives in the macOS Keychain
(service `chaqqon-qa-apk-password`).

## Run a test

```sh
# 1. Build
flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64

# 2. Encrypt
export APK_PASSWORD=$(security find-generic-password -a "$USER" -s chaqqon-qa-apk-password -w)
openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -md sha256 -salt \
  -in app-x86_64-release.apk -out app-x86_64-release.apk.enc -pass env:APK_PASSWORD

# 3. Publish — the workflow starts by itself
gh release create v1.8.3-78 app-x86_64-release.apk.enc --notes "1.8.3+78"
```

Rerun by hand: Actions → Android smoke test → Run workflow (empty tag = latest release).

## Read the results

```sh
gh run download <run-id> -n smoke-results
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -md sha256 \
  -in smoke-results.tar.gz.enc -pass env:APK_PASSWORD | tar xzf -
```

`out/` then holds the screenshots, `logcat.txt`, `crash.txt`, `install.txt`.

The test checks: the APK installs, the app launches, it is still running 45 s later, and nothing in the crash buffer.
It stops at the sign-in screen — going further needs a test phone number with a fixed SMS code.
