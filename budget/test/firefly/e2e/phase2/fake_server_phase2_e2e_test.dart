import 'support/phase2_emulator.dart';
import 'support/phase2_suite.dart';

/// The Phase 2 flow against an emulated Firefly III over loopback HTTP.
void main() {
  definePhase2Suite((clock) => Phase2Emulator.target(clock.now), live: false);
}
