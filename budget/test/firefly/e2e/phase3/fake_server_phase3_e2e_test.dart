import 'support/phase3_emulator.dart';
import 'support/phase3_suite.dart';

/// The Phase 3 flow against an emulated Firefly III over loopback HTTP.
void main() {
  definePhase3Suite((clock) => Phase3Emulator.target(clock.now), live: false);
}
