@Tags(['live'])
@Timeout(Duration(minutes: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import '../support/e2e_harness.dart';
import 'support/phase3_suite.dart';

/// The Phase 3 flow against a disposable Firefly III 6.6.2 named by
/// FIREFLY_E2E_URL and FIREFLY_E2E_TOKEN. Skips when they are unset. Objects
/// carry a per-run suffix and are deleted afterwards. See
/// docs/firefly/testing.md.
void main() {
  definePhase3Suite((_) async => E2eTarget.fromEnvironment(), live: true);
}
