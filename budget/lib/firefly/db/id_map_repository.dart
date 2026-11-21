import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart';

class IdMapRepository {
  const IdMapRepository(this.db);

  final FinanceDatabase db;
  static const _creatingPrefix = 'cashew:creating:';

  static String creatingId(String localPk) => '$_creatingPrefix$localPk';
  static bool isProvisional(FireflyIdMapping mapping) =>
      mapping.remoteId.startsWith(_creatingPrefix);

  Future<FireflyIdMapping?> byLocal(FireflyEntityType type, String localPk) =>
      _byLocal(type, localPk).getSingleOrNull();

  Future<FireflyIdMapping?> byRemote(FireflyEntityType type, String remoteId,
          {String subId = '', int role = 0}) =>
      (db.select(db.fireflyIdMap)
            ..where((row) =>
                row.entityType.equalsValue(type) &
                row.remoteId.equals(remoteId) &
                row.remoteSubId.equals(subId) &
                row.remoteRole.equals(role)))
          .getSingleOrNull();

  Future<List<FireflyIdMapping>> forRemoteGroup(
          FireflyEntityType type, String remoteId) =>
      (db.select(db.fireflyIdMap)
            ..where((row) =>
                row.entityType.equalsValue(type) &
                row.remoteId.equals(remoteId)))
          .get();

  Future<List<FireflyIdMapping>> list(FireflyEntityType type,
          {FireflySyncState? state}) =>
      (db.select(db.fireflyIdMap)
            ..where((row) =>
                row.entityType.equalsValue(type) &
                (state == null
                    ? const Constant(true)
                    : row.state.equalsValue(state))))
          .get();

  Future<void> put(FireflyIdMapping mapping) => db
      .into(db.fireflyIdMap)
      .insertOnConflictUpdate(mapping.toCompanion(false));

  Future<bool> markPendingDelete(
          FireflyEntityType type, String localPk) async =>
      (await (db.update(db.fireflyIdMap)
            ..where((row) =>
                _localKey(row, type, localPk) &
                row.state.equalsValue(FireflySyncState.localOnly).not()))
          .write(const FireflyIdMapCompanion(
        state: Value(FireflySyncState.pendingDelete),
      ))) >
      0;

  Future<void> remove(FireflyEntityType type, String localPk) =>
      (db.delete(db.fireflyIdMap)
            ..where((row) => _localKey(row, type, localPk)))
          .go();

  SimpleSelectStatement<$FireflyIdMapTable, FireflyIdMapping> _byLocal(
          FireflyEntityType type, String localPk) =>
      db.select(db.fireflyIdMap)..where((row) => _localKey(row, type, localPk));

  Expression<bool> _localKey(
          $FireflyIdMapTable row, FireflyEntityType type, String localPk) =>
      row.entityType.equalsValue(type) & row.localPk.equals(localPk);
}
