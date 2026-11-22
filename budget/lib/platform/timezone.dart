import 'dart:io';

import 'package:budget/platform/capabilities.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// The IANA name of the local time zone, or null when it cannot be found.
///
/// Uses `flutter_timezone` where it has an implementation and falls back to
/// the system configuration on Linux and Windows.
Future<String?> localTimezoneName() async {
  if (PlatformCapabilities.supportsTimezonePlugin) {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } on Object {
      return null;
    }
  }
  if (PlatformCapabilities.isLinux) return linuxTimezoneName();
  final String? fromEnv = Platform.environment['TZ'];
  if (fromEnv != null && fromEnv.contains('/')) return fromEnv;
  return null;
}

/// Reads `/etc/timezone` or resolves the `/etc/localtime` symlink.
String? linuxTimezoneName({String root = ''}) {
  try {
    final File file = File('$root/etc/timezone');
    if (file.existsSync()) {
      final String name = file.readAsStringSync().trim();
      if (name.isNotEmpty) return name;
    }
    final Link link = Link('$root/etc/localtime');
    if (link.existsSync()) {
      final String target = link.targetSync();
      const String marker = 'zoneinfo/';
      final int index = target.indexOf(marker);
      if (index >= 0) return target.substring(index + marker.length);
    }
  } on FileSystemException {
    return null;
  }
  return null;
}
