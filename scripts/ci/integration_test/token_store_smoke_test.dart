// Copied into budget/integration_test/ by CI only. Proves the platform
// keychain stores and reads the Firefly token with the CI signing setup.
import 'package:budget/firefly/config/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TokenStore writes, reads and deletes the token', (_) async {
    final store = TokenStore();
    await store.write('ci-smoke-token');
    expect(await store.read(), 'ci-smoke-token');
    expect(store.sessionOnly, isFalse);
    await store.delete();
    expect(await store.read(), isNull);
  });
}
