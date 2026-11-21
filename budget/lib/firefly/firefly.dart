import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/token_store.dart';
import 'package:flutter/foundation.dart';

class FireflyMode {
  FireflyMode._();

  static TokenStore _tokens = TokenStore();
  static Map<String, Object?> Function()? _settings;
  static bool _hasToken = false;

  static bool get available => !kIsWeb;
  static bool get enabled => available && config.mode && _hasToken;
  static FireflyConfig get config =>
      FireflyConfig.fromSettings(_settings?.call() ?? const {});
  static TokenStore get tokens => _tokens;

  /// Pass a settings reader so later setting changes are visible to hooks.
  static Future<void> init(Map<String, Object?> Function() settings,
      {TokenStore? tokenStore}) async {
    _settings = settings;
    _tokens = tokenStore ?? _tokens;
    _hasToken = false;
    if (config.mode) await refreshToken();
  }

  /// Call after a successful TokenStore write or deletion.
  static Future<void> refreshToken() async {
    _hasToken = false;
    if (!available) return;
    final token = await _tokens.read();
    _hasToken = token != null && token.trim().isNotEmpty;
  }
}
