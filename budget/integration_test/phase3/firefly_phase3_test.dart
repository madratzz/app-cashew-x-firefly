import 'package:integration_test/integration_test.dart';

import '../../test/firefly/e2e/phase3/support/phase3_emulator.dart';
import '../../test/firefly/e2e/phase3/support/phase3_suite.dart';

/// The Phase 3 flow on a device or desktop, against the emulated server on a
/// loopback port.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  definePhase3Suite((clock) => Phase3Emulator.target(clock.now), live: false);
}
