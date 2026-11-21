import 'dart:async';

import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/engine.dart';
import 'package:budget/widgets/navigationFramework.dart'
    show loadingIndeterminateKey, loadingProgressKey;

class SyncScheduler {
  SyncScheduler(this.engine) {
    _progress = engine.progress.listen(_showProgress);
  }

  final SyncEngine engine;
  late final StreamSubscription<SyncProgress> _progress;
  Timer? _foregroundTimer;
  Timer? _debounce;
  bool _disposed = false;
  bool _showingProgress = false;

  SyncReport? get lastReport => engine.lastReport;

  void start() => resume();

  void resume() {
    if (_disposed || _foregroundTimer != null || !engine.context.config.mode) {
      return;
    }
    _foregroundTimer =
        Timer.periodic(const Duration(minutes: 15), (_) => _trigger());
    _trigger();
  }

  void pause() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    _debounce?.cancel();
    _debounce = null;
  }

  void localWrite() {
    if (_foregroundTimer == null || !engine.context.config.syncOnChange) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), _trigger);
  }

  void _trigger() => unawaited(syncNow());

  Future<SyncReport> syncNow({bool fullResync = false}) => _disposed
      ? Future.value(const SyncReport(cancelled: true))
      : engine.run(fullResync: fullResync);

  void _showProgress(SyncProgress progress) {
    if (progress.phase == SyncPhase.complete) {
      _clearProgress();
      return;
    }
    _showingProgress = true;
    if (progress.phase == SyncPhase.preflight) {
      loadingIndeterminateKey.currentState?.setVisibility(true);
    }
    loadingProgressKey.currentState?.setProgressPercentage(
      (progress.phase.index + 1) / SyncPhase.values.length,
    );
  }

  void _clearProgress() {
    if (!_showingProgress) return;
    _showingProgress = false;
    loadingProgressKey.currentState?.setProgressPercentage(0);
    loadingIndeterminateKey.currentState?.setVisibility(false);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    pause();
    unawaited(_progress.cancel());
    _clearProgress();
    engine.cancel();
  }
}
