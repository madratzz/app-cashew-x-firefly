import 'package:budget/firefly/sync/contracts.dart';

/// WP-37 supplies the empty-server check and local upload.
class FireflyBootstrapUpload {
  const FireflyBootstrapUpload(this.context);

  final SyncContext context;

  Future<bool> canUpload() async => false;
  Future<SyncReport> run() async => const SyncReport(cancelled: true);
}
