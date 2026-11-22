import 'package:budget/firefly/config/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default storage keeps macOS off the data protection keychain', () {
    final options = TokenStore.defaultStorage.mOptions.toMap();
    expect(options['useDataProtectionKeyChain'], 'false');
  });

  test('default storage leaves iOS options at the plugin defaults', () {
    expect(TokenStore.defaultStorage.iOptions.toMap(),
        IOSOptions.defaultOptions.toMap());
  });
}
