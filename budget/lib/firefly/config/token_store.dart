import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore({FlutterSecureStorage? storage, bool? linux})
      : _storage = storage ?? const FlutterSecureStorage(),
        _linux =
            linux ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux);

  static const key = 'firefly.pat';
  final FlutterSecureStorage _storage;
  final bool _linux;
  bool _sessionOnly = false;
  String? _sessionToken;

  bool get sessionOnly => _sessionOnly;

  Future<String?> read() =>
      _useStorage(() => _storage.read(key: key), () => _sessionToken);

  Future<void> write(String token) {
    if (token.trim().isEmpty) throw ArgumentError('Token is empty');
    return _useStorage(() => _storage.write(key: key, value: token), () {
      _sessionToken = token;
    });
  }

  Future<void> delete() => _useStorage(() => _storage.delete(key: key), () {
        _sessionToken = null;
      });

  Future<T> _useStorage<T>(
      Future<T> Function() action, T Function() sessionAction) async {
    if (kIsWeb) throw UnsupportedError('Firefly secure storage is unavailable');
    if (_sessionOnly) return sessionAction();
    try {
      return await action();
    } on MissingPluginException {
      if (!_linux) rethrow;
    } on PlatformException catch (error) {
      if (!_linux || error.code != 'Libsecret error') rethrow;
    }
    _sessionOnly = true;
    return sessionAction();
  }
}
