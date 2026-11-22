@Tags(['live'])
@Timeout(Duration(minutes: 30))
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_harness.dart';
import 'support/phase1_suite.dart';

/// The Phase 1 flow against a disposable Firefly III 6.6.2 named by
/// FIREFLY_E2E_URL and FIREFLY_E2E_TOKEN. Skips when they are unset. See
/// docs/firefly/testing.md.
void main() {
  definePhase1Suite((_) async => E2eTarget.fromEnvironment(), live: true);
}
