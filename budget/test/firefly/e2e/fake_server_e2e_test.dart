import 'support/e2e_harness.dart';
import 'support/phase1_suite.dart';

/// The Phase 1 flow against an emulated Firefly III over loopback HTTP.
void main() {
  definePhase1Suite((clock) => E2eTarget.fake(clock.now), live: false);
}
