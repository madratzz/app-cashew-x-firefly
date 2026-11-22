import 'package:integration_test/integration_test.dart';

import '../../test/firefly/e2e/phase2/support/phase2_emulator.dart';
import '../../test/firefly/e2e/phase2/support/phase2_suite.dart';

/// The Phase 2 flow on a device or desktop, against the emulated server on a
/// loopback port.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  definePhase2Suite((clock) => Phase2Emulator.target(clock.now), live: false);
}
