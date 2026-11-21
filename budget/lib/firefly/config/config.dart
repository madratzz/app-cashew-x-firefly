import 'package:flutter/foundation.dart';

class FireflyConfig {
  const FireflyConfig({
    this.mode = false,
    this.baseUrl = '',
    this.syncOnChange = true,
    this.applyRules = true,
    this.fireWebhooks = true,
    this.transactionWindowDays = 90,
    this.pageSize = 100,
    this.subcategorySeparator = ' / ',
  });

  factory FireflyConfig.fromSettings(Map<String, Object?> settings) {
    final baseUrl = settings[baseUrlKey];
    final window = settings[transactionWindowDaysKey];
    final pageSize = settings[pageSizeKey];
    final separator = settings[subcategorySeparatorKey];
    return FireflyConfig(
      mode: settings[modeKey] == true,
      baseUrl: baseUrl is String ? baseUrl : '',
      syncOnChange: settings[syncOnChangeKey] != false,
      applyRules: settings[applyRulesKey] != false,
      fireWebhooks: settings[fireWebhooksKey] != false,
      transactionWindowDays: window is int && window >= 0 ? window : 90,
      pageSize: pageSize is int && pageSize > 0 ? pageSize : 100,
      subcategorySeparator:
          separator is String && separator.isNotEmpty ? separator : ' / ',
    );
  }

  static const modeKey = 'fireflyMode';
  static const baseUrlKey = 'fireflyBaseUrl';
  static const syncOnChangeKey = 'fireflySyncOnChange';
  static const applyRulesKey = 'fireflyApplyRules';
  static const fireWebhooksKey = 'fireflyFireWebhooks';
  static const transactionWindowDaysKey = 'fireflyTransactionWindowDays';
  static const pageSizeKey = 'fireflyPageSize';
  static const subcategorySeparatorKey = 'fireflySubcategorySeparator';

  final bool mode;
  final String baseUrl;
  final bool syncOnChange;
  final bool applyRules;
  final bool fireWebhooks;
  final int transactionWindowDays;
  final int pageSize;
  final String subcategorySeparator;
}

const _allowHttp = kDebugMode && bool.fromEnvironment('FIREFLY_ALLOW_HTTP');

Uri normalizeFireflyUrl(String input) {
  final value = input.trim();
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      RegExp(r'^[a-z][a-z0-9+.-]*://[^/?#]*@', caseSensitive: false)
          .hasMatch(value) ||
      uri.hasQuery ||
      uri.hasFragment ||
      RegExp(r'[\s\\]').hasMatch(value)) {
    throw const FormatException('Invalid Firefly server URL');
  }
  final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
  if (uri.scheme != 'https' &&
      !(uri.scheme == 'http' && loopback && _allowHttp)) {
    throw const FormatException('Firefly requires HTTPS');
  }
  final path = uri.path
      .replaceFirst(RegExp(r'/+$'), '')
      .replaceFirst(RegExp(r'/api(?:/v1)?$'), '');
  return uri.replace(path: path);
}
