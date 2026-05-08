# Android App

Steps to scaffold a new Android app, get it building from the CLI, and ship signed releases via
GitHub Actions for installation through Obtainium. Android Studio is used once for project
generation and never reopened; everything else is `./gradlew` and `adb`.

## 1. Dev shell

Create `flake.nix` for JDK, adb, and Android Studio:

```nix
{
  description = "<AppName> dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "android-studio" ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          jdk17
          android-tools  # adb
          android-studio # one-time scaffolding only
          glib           # gsettings, which Studio probes at startup
        ];

        JAVA_HOME = "${pkgs.jdk17.home}";
      };
    };
}
```

Activate with `nix develop`.

## 2. Generate the project skeleton

Studio's project wizard produces a known-good Gradle setup, manifest, gradle wrapper, and Material
theme that's tedious to assemble by hand. Used once and only once.

```
android-studio
```

New Project → Phone and Tablet → Empty Views Activity. Settings:

- Language: Kotlin
- Build configuration: Kotlin DSL (build.gradle.kts)
- Minimum SDK: API 26 (Android 8.0; covers ~99% of active devices)
- Save location: a subdirectory like `<appname>/android`

Studio downloads the SDK to `~/Android/Sdk` (this lives outside the Nix store and that is correct;
the SDK is per-user state, not project-pinned).

Wait for the initial Gradle sync, then close Studio. After this point, `android-studio` and `glib`
can be dropped from the flake.

## 3. Build and install from the CLI

```
android/gradlew -p android assembleDebug
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

The `-r` flag reinstalls over an existing copy. Phone needs USB debugging enabled (Settings → About
phone → tap Build Number 7 times → Developer Options → USB debugging).

## 4. Release signing

Distributable APKs must be signed with a release key, and Android requires every update to be signed
by the same key forever. Store the key in Proton Pass.

### Generate the keystore

From inside the dev shell:

```
keytool -genkeypair -v -keystore <appname>.jks -keyalg RSA -keysize 2048 -validity 10000 -alias <appname>
```

Use a max-length generated password. The X.509 identity fields are unused for sideloaded apps and
can be filled in roughly.

### Store the keys

- Canonical: upload the `.jks` to Proton Pass as a file attachment; store both passwords as fields
  on the same item.
- Working copy: a local path outside any git repo, e.g., `~/.config/<appname>/<appname>.jks`.
  Re-pull from Proton Pass on a fresh laptop.

### Set up Gradle to use the keys

Create `android/keystore.properties` and add it to `.gitignore`:

```
storeFile=/home/user/.config/<appname>/<appname>.jks
storePassword=<password>
keyAlias=<appname>
keyPassword=<password>
```

In `android/app/build.gradle.kts`, add at the very top:

```kotlin
import java.util.Properties
```

Above the `android { }` block (the order matters):

```kotlin
val keystoreProps = Properties().apply {
    val f = rootProject.file("keystore.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun keystoreProp(key: String): String? =
    keystoreProps.getProperty(key) ?: System.getenv(key)
```

Inside `android { }`, alongside `buildTypes`:

```kotlin
signingConfigs {
    create("release") {
        keystoreProp("storeFile")?.let {
            storeFile = file(it)
            storePassword = keystoreProp("storePassword")
            keyAlias = keystoreProp("keyAlias")
            keyPassword = keystoreProp("keyPassword")
        }
    }
}
```

And in `buildTypes.release`:

```kotlin
signingConfig = signingConfigs.getByName("release")
```

### Build a signed APK

```
android/gradlew -p android assembleRelease
```

Output at `android/app/build/outputs/apk/release/app-release.apk`. Install with:

```bash
adb install -r android/app/build/outputs/apk/release/app-release.apk
```

If the debug version is still installed, it'll have to be uninstalled.

After this, every future release uses the same key and `-r` upgrades cleanly.

## 5. Versioning

Obtainium compares `versionCode` (a monotonic integer in the manifest) to detect updates. Encode a
SemVer string into one. In `android/gradle.properties`:

```
<appname>Version=0.1.0
```

In the `defaultConfig { }` of `app/build.gradle.kts`:

```kotlin
val <appname>Version: String by project
val parts = <appname>Version.split(".").map { it.toInt() }
require(parts.size == 3) {
    "<appname>Version must be MAJOR.MINOR.PATCH (got: $<appname>Version)"
}
versionCode = parts[0] * 1_000_000 + parts[1] * 1_000 + parts[2]
versionName = <appname>Version
```

`0.1.0` → versionCode `1000`, `1.2.3` → `1002003`.

## 6. GitHub Actions release workflow

Creating a workflow at `.github/workflows/release.yml` builds + signs on tag push and uploads the
APK to a GitHub Release.

```yaml
name: Release

on:
  push:
    tags:
      - "v*"
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-24.04
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"
          cache: gradle

      - name: Decode keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.SIGNING_KEYSTORE_BASE64 }}
        run: echo "$KEYSTORE_BASE64" | base64 -d > "$RUNNER_TEMP/<appname>.jks"

      - name: Build release APK
        env:
          storeFile: ${{ runner.temp }}/<appname>.jks
          storePassword: ${{ secrets.SIGNING_KEYSTORE_PASSWORD }}
          keyAlias: ${{ secrets.SIGNING_KEY_ALIAS }}
          keyPassword: ${{ secrets.SIGNING_KEY_PASSWORD }}
        run: |
          chmod +x android/gradlew
          android/gradlew -p android assembleRelease

      - name: Rename APK with version + timestamp
        run: |
          VERSION=$(grep '^<appname>Version=' android/gradle.properties | cut -d= -f2)
          TIMESTAMP=$(date -u +"%Y.%m.%dT%H.%M.%SZ")
          mv android/app/build/outputs/apk/release/app-release.apk \
             "android/app/build/outputs/apk/release/<appname>-v${VERSION}+${TIMESTAMP}.apk"

      - name: Upload APK as workflow artifact
        uses: actions/upload-artifact@v4
        with:
          name: <appname>-apk
          path: android/app/build/outputs/apk/release/<appname>-*.apk

      - name: Create GitHub Release
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v2
        with:
          files: android/app/build/outputs/apk/release/<appname>-*.apk
          generate_release_notes: true
```

Add four repository secrets in Settings → Secrets and variables → Actions → Repository secrets:

- `SIGNING_KEYSTORE_BASE64`: output of `base64 -w0 <appname>.jks` (single line)
- `SIGNING_KEYSTORE_PASSWORD`
- `SIGNING_KEY_ALIAS`
- `SIGNING_KEY_PASSWORD`

Test it worked via Actions tab → Run workflow, which should execute the release step but won't
publish.

To cut a real release:

```
git tag v0.1.0
git push origin v0.1.0
```

Or manually tag in the GitHub UI.

## 7. Distribute via Obtainium

On the phone, in Obtainium:

- Add app → paste the GitHub repo URL (`https://github.com/<user>/<repo>`)
- Obtainium auto-detects the GitHub release format and watches for new tags
