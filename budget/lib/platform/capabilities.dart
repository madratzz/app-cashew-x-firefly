import 'package:budget/firefly/firefly.dart';
import 'package:flutter/foundation.dart';

class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get supportsGoogleSignIn => _mobile || kIsWeb;
  static bool get supportsFirebase => _mobile || kIsWeb;
  static bool get supportsLocalNotifications => _mobile;
  static bool get supportsBiometrics => _mobile;
  static bool get supportsHomeWidget => _mobile;
  static bool get supportsInAppPurchase => _mobile;
  static bool get supportsCamera => _mobile;
  static bool get googleDriveAvailable =>
      supportsGoogleSignIn && !FireflyMode.enabled;
}
