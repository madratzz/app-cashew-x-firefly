import 'package:integration_test/integration_test.dart';

import '../test/firefly/e2e/support/e2e_harness.dart';
import '../test/firefly/e2e/support/phase1_suite.dart';

/// The Phase 1 flow on a device or desktop, against the emulated server on a
/// loopback port.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  definePhase1Suite((clock) => E2eTarget.fake(clock.now), live: false);
}
