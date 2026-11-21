# Platforms

Cashew builds for Android, iOS, web, macOS, Linux and Windows from `budget/`
with the Flutter version pinned in `budget/.fvmrc` (3.19.6). Every feature
switch below comes from `budget/lib/platform/capabilities.dart`
(`PlatformCapabilities`); code checks those getters, not the OS directly.

## Features per platform

| Feature | Android | iOS | Web | macOS | Linux | Windows |
|---|---|---|---|---|---|---|
| Local database, transactions, budgets, CSV and backup import/export | yes | yes | yes | yes | yes | yes |
| Firefly III sync | yes | yes | no | yes | yes | yes |
| Google sign-in, Drive backup, Gmail import | yes | yes | yes | no | no | no |
| Firebase shared budgets | yes | yes | yes | no | no | no |
| Scheduled notifications | yes | yes | no | yes | no | no |
| Biometric / system lock | yes | yes | no | yes | no | yes |
| Home screen widgets | yes | no | no | no | no | no |
| Quick actions (app icon shortcuts) | yes | yes | no | no | no | no |
| Notification scanning for auto transactions | yes | no | no | no | no | no |
| Camera for receipts | yes | yes | no | no | no | no |
| In-app purchase and store review | yes | yes | no | no | no | no |
| Premium | store | store | unlocked | unlocked | unlocked | unlocked |
| CSV character set detection | auto | auto | UTF-8 | UTF-8 | UTF-8 | UTF-8 |
| Time zone | plugin | plugin | plugin | plugin | `/etc/timezone` or `/etc/localtime` | `TZ` variable, else default |

Desktop differences:

- The database lives in the application support directory
  (`~/Library/Containers/<bundle>/Data/Library/Application Support/...` on
  macOS, `~/.local/share/<app>` on Linux, `%APPDATA%\<org>\<app>` on Windows),
  not in Documents.
- Exports open the native save dialog; if it fails the file goes to Downloads.
- The window cannot shrink below 360 × 600 logical pixels.
- The Firefly token is stored with `flutter_secure_storage`: Keychain on macOS,
  libsecret on Linux, Credential Manager on Windows. On Linux without a secret
  service the token is kept in memory for the session only.

## Build prerequisites

| Target | Needs | Command |
|---|---|---|
| Android | JDK 17, Android SDK (`ANDROID_HOME`) | `fvm flutter build apk` |
| iOS | macOS, Xcode, CocoaPods | `fvm flutter build ios --no-codesign` |
| Web | nothing extra | `fvm flutter build web` |
| macOS | macOS 10.15+ deployment target, Xcode, CocoaPods | `fvm flutter build macos` |
| Linux | `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libsecret-1-dev libjsoncpp-dev` | `fvm flutter build linux` |
| Windows | Visual Studio 2022 with "Desktop development with C++", Developer Mode on (plugin symlinks) | `fvm flutter build windows` |

macOS entitlements (`macos/Runner/*.entitlements`): app sandbox, network
client, user-selected and Downloads read/write, and a keychain access group for
secure storage. Release builds that should run on other machines need a
signing identity; signing secrets come from CI only.

Android excludes `FlutterSecureStorage.xml` from cloud backup and device
transfer (`android/app/src/main/res/xml/backup_rules.xml`,
`data_extraction_rules.xml`).
