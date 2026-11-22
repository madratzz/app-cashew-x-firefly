import 'package:budget/firefly/firefly.dart';
import 'package:flutter/foundation.dart';

/// Which plugin-backed features exist on the running platform.
///
/// Every getter is a pure function of [defaultTargetPlatform] and [kIsWeb],
/// so tests can override the platform with `debugDefaultTargetPlatformOverride`.
class PlatformCapabilities {
  PlatformCapabilities._();

  static TargetPlatform get _platform => defaultTargetPlatform;

  static bool get isAndroid => !kIsWeb && _platform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && _platform == TargetPlatform.iOS;
  static bool get isMacOS => !kIsWeb && _platform == TargetPlatform.macOS;
  static bool get isLinux => !kIsWeb && _platform == TargetPlatform.linux;
  static bool get isWindows => !kIsWeb && _platform == TargetPlatform.windows;

  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isMacOS || isLinux || isWindows;

  /// Google sign-in, Drive backup and Gmail import. Off on every platform:
  /// Firefly III login replaces Google sign-in (WP-42).
  static bool get supportsGoogleSignIn => false;

  /// Firebase auth and Firestore (shared budgets). Off with Google sign-in
  /// (WP-42).
  static bool get supportsFirebase => false;

  /// Scheduled notifications. `flutter_local_notifications` 17.x has no
  /// Windows implementation and cannot schedule on Linux.
  static bool get supportsLocalNotifications => isMobile || isMacOS;

  /// `local_auth` has no Linux implementation.
  static bool get supportsBiometrics => isMobile || isMacOS || isWindows;

  static bool get supportsHomeWidget => isAndroid;
  static bool get supportsQuickActions => isMobile;
  static bool get supportsNotificationListener => isAndroid;
  static bool get supportsDisplayMode => isAndroid;
  static bool get supportsAppSettings => isMobile;

  /// Store purchases. Desktop builds unlock premium like the web build (D7).
  static bool get supportsInAppPurchase => isMobile;
  static bool get supportsInAppReview => isMobile;

  static bool get supportsCamera => isMobile;

  /// `flutter_timezone` 1.x has no Linux or Windows implementation.
  static bool get supportsTimezonePlugin => isMobile || isMacOS || kIsWeb;

  /// `flutter_charset_detector` is only verified on Android and iOS.
  static bool get supportsCharsetDetector => isMobile;

  static bool get googleDriveAvailable =>
      supportsGoogleSignIn && !FireflyMode.enabled;
}
