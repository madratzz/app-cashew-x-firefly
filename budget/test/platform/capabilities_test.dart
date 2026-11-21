import 'dart:io';

import 'package:budget/platform/capabilities.dart';
import 'package:budget/platform/timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  void on(TargetPlatform platform) =>
      debugDefaultTargetPlatformOverride = platform;

  test('mobile keeps every plugin feature', () {
    for (final TargetPlatform platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ]) {
      on(platform);
      expect(PlatformCapabilities.isMobile, isTrue);
      expect(PlatformCapabilities.supportsGoogleSignIn, isTrue);
      expect(PlatformCapabilities.supportsFirebase, isTrue);
      expect(PlatformCapabilities.supportsLocalNotifications, isTrue);
      expect(PlatformCapabilities.supportsBiometrics, isTrue);
      expect(PlatformCapabilities.supportsInAppPurchase, isTrue);
      expect(PlatformCapabilities.supportsCamera, isTrue);
      expect(PlatformCapabilities.supportsCharsetDetector, isTrue);
    }
    on(TargetPlatform.android);
    expect(PlatformCapabilities.supportsHomeWidget, isTrue);
    on(TargetPlatform.iOS);
    expect(PlatformCapabilities.supportsHomeWidget, isFalse);
  });

  test('desktop hides Google, Firebase, store and camera', () {
    for (final TargetPlatform platform in <TargetPlatform>[
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      on(platform);
      expect(PlatformCapabilities.isDesktop, isTrue);
      expect(PlatformCapabilities.supportsGoogleSignIn, isFalse);
      expect(PlatformCapabilities.supportsFirebase, isFalse);
      expect(PlatformCapabilities.googleDriveAvailable, isFalse);
      expect(PlatformCapabilities.supportsInAppPurchase, isFalse);
      expect(PlatformCapabilities.supportsInAppReview, isFalse);
      expect(PlatformCapabilities.supportsCamera, isFalse);
      expect(PlatformCapabilities.supportsHomeWidget, isFalse);
      expect(PlatformCapabilities.supportsQuickActions, isFalse);
      expect(PlatformCapabilities.supportsCharsetDetector, isFalse);
    }
  });

  test('per-desktop plugin gaps', () {
    on(TargetPlatform.macOS);
    expect(PlatformCapabilities.supportsLocalNotifications, isTrue);
    expect(PlatformCapabilities.supportsBiometrics, isTrue);
    expect(PlatformCapabilities.supportsTimezonePlugin, isTrue);
    on(TargetPlatform.linux);
    expect(PlatformCapabilities.supportsLocalNotifications, isFalse);
    expect(PlatformCapabilities.supportsBiometrics, isFalse);
    expect(PlatformCapabilities.supportsTimezonePlugin, isFalse);
    on(TargetPlatform.windows);
    expect(PlatformCapabilities.supportsLocalNotifications, isFalse);
    expect(PlatformCapabilities.supportsBiometrics, isTrue);
    expect(PlatformCapabilities.supportsTimezonePlugin, isFalse);
  });

  group('linuxTimezoneName', () {
    late Directory root;
    setUp(() {
      root = Directory.systemTemp.createTempSync('tz');
      Directory('${root.path}/etc').createSync();
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('reads /etc/timezone', () {
      File('${root.path}/etc/timezone').writeAsStringSync('Europe/Berlin\n');
      expect(linuxTimezoneName(root: root.path), 'Europe/Berlin');
    });

    test('resolves the /etc/localtime link', () {
      Link('${root.path}/etc/localtime')
          .createSync('/usr/share/zoneinfo/Asia/Karachi');
      expect(linuxTimezoneName(root: root.path), 'Asia/Karachi');
    });

    test('returns null when nothing is configured', () {
      expect(linuxTimezoneName(root: root.path), isNull);
    });
  });
}
