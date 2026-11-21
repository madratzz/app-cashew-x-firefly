import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:drift/drift.dart';

class ConflictRepository {
  const ConflictRepository(this.db);

  final FinanceDatabase db;

  Future<FireflyConflict> record({
    required FireflyEntityType type,
    required String localPk,
    required String remoteId,
    required JsonObject local,
    JsonObject? remote,
    required String resolution,
    DateTime? createdAt,
  }) =>
      db
          .into(db.fireflyConflicts)
          .insertReturning(FireflyConflictsCompanion.insert(
            entityType: type,
            localPk: localPk,
            remoteId: remoteId,
            localJson: jsonEncode(local),
            remoteJson: Value(remote == null ? null : jsonEncode(remote)),
            resolution: resolution,
            dateCreated:
                createdAt == null ? const Value.absent() : Value(createdAt),
          ));

  Future<FireflyConflict?> read(String pk) => (db.select(db.fireflyConflicts)
        ..where((row) => row.conflictPk.equals(pk)))
      .getSingleOrNull();

  Future<List<FireflyConflict>> list({bool unacknowledgedOnly = false}) =>
      _list(unacknowledgedOnly).get();

  Stream<List<FireflyConflict>> watch({bool unacknowledgedOnly = false}) =>
      _list(unacknowledgedOnly).watch();

  Future<void> acknowledge(String pk) => (db.update(db.fireflyConflicts)
        ..where((row) => row.conflictPk.equals(pk)))
      .write(const FireflyConflictsCompanion(acknowledged: Value(true)));

  SimpleSelectStatement<$FireflyConflictsTable, FireflyConflict> _list(
      bool unacknowledgedOnly) {
    final query = db.select(db.fireflyConflicts)
      ..orderBy([(row) => OrderingTerm.desc(row.dateCreated)]);
    if (unacknowledgedOnly) {
      query.where((row) => row.acknowledged.equals(false));
    }
    return query;
  }
}
