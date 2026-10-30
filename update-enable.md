# In-app update (update-enable)

Hand this file to the agent on the build PC. It describes what was added so the app can update itself, and the exact release routine.

## Why this exists
Version 1.0.0 (released) has **no update code**, so it can never detect updates. The first build containing this feature (`1.0.1+2`) must be installed manually once (download from the website, install over the old app; no uninstall needed if the signing key matches). From then on, updates are offered inside the app.

## How it works
1. On app start (and on resume, throttled to once per 30 min) the app fetches
   `https://raw.githubusercontent.com/JoshDumadapat/RentEaseApk/main/version.json`
   (public repo, no token, no Firebase/backend involved).
2. If `latestBuild` is greater than the installed build number, a banner pops up
   ("New version available"). Tapping it opens the **Profile** tab.
3. On the Profile screen, below **Log out**, the old static "RentEase prototype · v1.0" footer was replaced by
   the real installed version, release notes and an **Update to vX.Y.Z** button.
4. The button downloads the APK inside the app (progress bar), asks for the
   "Install unknown apps" permission if needed, then opens Android's installer. The user taps **Install**.
   (Android never allows a fully silent install.)
5. If `installed build < minSupportedBuild`, the update is **forced**: the banner cannot be dismissed.
6. Offline or malformed JSON: the check fails silently; the app is unaffected.

Guests (tenant guest mode) don't see the banner (no Profile access).

## Code changes (no backend, rules, Auth or repository code touched)
New folder `lib/features/app_update/`:
- `model/app_update_info.dart`: parses `version.json`.
- `data/app_update_service.dart`: fetches `version.json` (URL constant `versionJsonUrl`) and reads installed version.
- `services/apk_installer.dart`: downloads (dio, https only), requests install permission, opens installer (open_filex).
- `cubit/app_update_cubit.dart` + `app_update_state.dart`: state machine (`idle`, `upToDate`, `available`, `forced`, `downloading`).
- `widgets/update_banner.dart`: top pop-up in both shells.
- `widgets/update_section.dart`: version label + Update button on both profile screens.
- `widgets/update_lifecycle_watcher.dart`: re-check on app resume.

Edited files:
- `pubspec.yaml`: version `1.0.1+2`; added `package_info_plus`, `dio`, `path_provider`, `open_filex`.
- `android/app/src/main/AndroidManifest.xml`: `REQUEST_INSTALL_PACKAGES` permission (open_filex ships its own FileProvider).
- `lib/main.dart`: provides `AppUpdateCubit`, wraps the app in `UpdateLifecycleWatcher`.
- `lib/features/shell/view/main_shell.dart` and `landlord_shell.dart`: mount `UpdateBanner`.
- `lib/features/profile/view/profile_screen.dart` and `owner_profile_screen.dart`: footer replaced by `UpdateSection`.

## Fixed links
| What | Value |
|---|---|
| APK repo | `https://github.com/JoshDumadapat/RentEaseApk` (must stay public) |
| APK file name (identical on every release) | `Renteaseph.apk` |
| Website download button (set once) | `https://github.com/JoshDumadapat/RentEaseApk/releases/latest/download/Renteaseph.apk` |
| Version file | `version.json` at the root of the `main` branch of the APK repo |

`apkUrl` in `version.json` also uses the `latest/download` link, so it never changes.

## Release routine (every release)
1. Pull the latest code on the build PC.
2. Bump `version:` in `pubspec.yaml`, e.g. `1.0.2+3`. **The number after `+` must always increase.**
3. Build on the PC whose debug keystore signed v1.0.0 (see "Signing" below):
   `flutter build apk --release`
4. Rename `build/app/outputs/flutter-apk/app-release.apk` to `Renteaseph.apk`.
5. In the `RentEaseApk` repo create a GitHub Release: new tag (e.g. `v1.0.2`), title like `RentEase v1.0.2`, attach `Renteaseph.apk`.
   Publish it (not draft, not pre-release).
6. **After** the release is published, edit `version.json` in the APK repo (`latestVersion`, `latestBuild`, `notes`) and commit to `main`.
   GitHub caches raw files ~5 min, so the app may take a few minutes to see it.
7. Never delete the release that is currently `latest`.

Template (`version.json`, also in this repo at `docs/version.json.example`):
```json
{
  "latestVersion": "1.0.1",
  "latestBuild": 2,
  "minSupportedBuild": 1,
  "apkUrl": "https://github.com/JoshDumadapat/RentEaseApk/releases/latest/download/Renteaseph.apk",
  "notes": "What's new in this version"
}
```
Set `minSupportedBuild` to the new build number only when you want to force everyone to update.

## First release checklist (1.0.1+2)
1. Build and publish `v1.0.1` as above, then add `version.json` with `latestBuild: 2`.
2. Point the website download button at the fixed `latest/download/Renteaseph.apk` link.
3. Install it on a phone that has v1.0.0 and confirm it updates in place with data intact.
   If Android says "App not installed", the signing key does not match (see below).
4. Test the real flow: bump to `1.0.2+3`, build, publish `v1.0.2`, set `latestBuild: 3`, open the app on the phone with 1.0.1.

## Signing
`android/app/build.gradle.kts` signs release builds with the **debug keystore** (`~/.android/debug.keystore` on that PC), which is not in git.
In-place updates only work if every release is signed with the same key as v1.0.0.
- Build releases on the PC that built v1.0.0, or copy its `debug.keystore` to the other PC.
- Back up that keystore. If it is lost, existing users must uninstall and reinstall once.
- Check keys: `keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android` and compare SHA-256.

## Edge cases to test
Offline start (no popup, no crash), cancel the Android installer (button stays), deny "Install unknown apps" (message + retry), forced update (`minSupportedBuild` above installed), login/logout unaffected.
