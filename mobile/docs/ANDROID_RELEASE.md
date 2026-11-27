# Android release runbook

The Play candidate is a separate package from the existing debug alpha. Proposed permanent ID: `com.wizardshooter.game` (confirm ownership/availability before creating the Play Console app; do not change after first upload). Debug remains `com.wizardshooter.alpha`; Android treats them as different apps. Transfer progress with Settings > Save backup / restore before uninstalling any old alpha. The Play store signs delivered APKs with the Play App Signing key, not the upload key. Use Play internal testing to verify updates; a sideload signed with another key will not update a Play install.

## Validation
The Mobile Android bundle workflow automatically runs on release configuration changes and can be dispatched manually. It uses Godot 4.5.1, JDK17, Gradle template, Android SDK36, arm64 and bundletool 1.18.2. It exports unsigned then signs using a temporary validation key. Only evidence is uploaded, never a disposable-key AAB. A release dispatch is allowed only on master and must use the owner upload key. No automatic Play upload.

The validator checks package, version code/name, target >=36, min24, nondebuggable manifest, permission allowlist, bundletool validity, PAGE_ALIGNMENT_16K and each arm64 ELF PT_LOAD alignment, and Godot assets. This is build-time validation, not Android runtime compatibility proof. Verify Android 16 edge-to-edge/safe area, 16KB device/emulator, and actual Play-generated split APKs in internal testing. Godot 4.5.1 is retained provisionally to avoid engine changes; if Gradle or API36 support fails, upgrade engine/export template together and rerun regressions.

## Owner-controlled upload key (once)
Use a machine you control with JDK17 and GitHub CLI installed. Never send passwords or keystore to chat, commit them, or reuse the disposable debug signing key. Create encrypted offline backup of key and password separately.

```sh
mkdir -p "$HOME/.wizard-shooter-signing"
chmod 700 "$HOME/.wizard-shooter-signing"
keytool -genkeypair -storetype PKCS12 \
  -keystore "$HOME/.wizard-shooter-signing/upload.p12" \
  -alias wizard-upload -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Wizard Shooter Upload"
```

Let keytool prompt for the password. Save it securely. Export public certificate for verification:
```sh
keytool -exportcert -keystore "$HOME/.wizard-shooter-signing/upload.p12" \
  -alias wizard-upload -file "$HOME/.wizard-shooter-signing/upload.der"
shasum -a 256 "$HOME/.wizard-shooter-signing/upload.der"
```

If choosing CI signing, restrict master writes, review workflow changes, and configure GitHub Actions secrets in repository settings (never paste them into an issue or chat):
- ANDROID_UPLOAD_KEYSTORE_B64: base64 of the PKCS12 file. On macOS use `base64 < "$HOME/.wizard-shooter-signing/upload.p12" | tr -d '\n' | gh secret set ANDROID_UPLOAD_KEYSTORE_B64 --repo lucas-gomes-s/wizard-shooter`.
- ANDROID_UPLOAD_PASSWORD: enter securely via GitHub UI or interactive `gh secret set`.
- ANDROID_UPLOAD_ALIAS: wizard-upload.
- Actions variable ANDROID_UPLOAD_SHA256: SHA256 of the DER public certificate (not a secret).

The key is decoded in the signing step only, deleted at exit, and its certificate fingerprint compared to the configured pin. Owner can instead sign the unsigned local export using jarsigner without uploading a private key to GitHub; use the same validation script. Play App Signing enrollment still happens in Play Console.

## First release
Dispatch Mobile Android bundle > release on master. Default candidate name 0.2.0-beta.1. Version code = 1000 + workflow run number, strictly greater than last uploaded Play code supplied by owner (0 first time). Do not re-run release jobs: dispatch a new run to get a fresh code. Play Console is authoritative for monotonicity, not this workflow. Keep an independent copy of the verified AAB and metadata before CI retention expires. Confirm the correct signing certificate in Play Console. No publishing is performed here.

## Acceptance gates
- validation pipeline green, owner-signed release pipeline green, package ID confirmed.
- Google Play app signing, internal testing install, then upgrade from a subsequent version without data loss.
- actual device layout, touch, performance, pause/background/resume, 16KB test.
- first-run onboarding, first fusion and balance targets observed.
- store graphics, privacy policy, Data Safety, target audience, content rating and ads declaration.
- closed testing group and real feedback. No payments/ads in this beta.

References: https://support.google.com/googleplay/android-developer/answer/11926878 ; https://developer.android.com/guide/practices/page-sizes ; https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html
