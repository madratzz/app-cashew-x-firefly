import 'package:budget/database/tables.dart';

class SyncMetaRepository {
  const SyncMetaRepository(this.db);

  final FinanceDatabase db;
  static const deleteLogCursor = 'deleteLogCursor';
  static const serverVersion = 'serverVersion';
  static const serverUserId = 'serverUserId';
  static const serverUrlHash = 'serverUrlHash';
  static const transactionPage = 'transactionPage';
  static const transactionCursor = 'transactionCursor';
  static const lastFullReconcile = 'lastFullReconcile';
  static const lastSync = 'lastSync';

  static String contributorVersion(String id) => 'contributorVersion.$id';

  Future<String?> read(String key) async =>
      (await (db.select(db.fireflySyncMeta)
                ..where((row) => row.key.equals(key)))
              .getSingleOrNull())
          ?.value;

  Future<void> write(String key, String value) => db
      .into(db.fireflySyncMeta)
      .insertOnConflictUpdate(FireflySyncMetaEntry(key: key, value: value));

  Future<DateTime?> readDate(String key) async {
    final value = await read(key);
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  Future<void> writeDate(String key, DateTime value) =>
      write(key, value.toUtc().toIso8601String());

  Future<void> remove(String key) =>
      (db.delete(db.fireflySyncMeta)..where((row) => row.key.equals(key))).go();
}
