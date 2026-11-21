import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:drift/drift.dart';

class ResourceCacheRepository {
  const ResourceCacheRepository(this.db);

  final FinanceDatabase db;

  static String resourcePk(FireflyEntityType type, String id) =>
      '${type.name}:$id';

  static JsonObject decode(FireflyCachedResource row) =>
      jsonDecode(row.json) as JsonObject;

  Future<FireflyCachedResource?> read(FireflyEntityType type, String id) =>
      (db.select(db.fireflyResourceCache)
            ..where((row) => row.resourcePk.equals(resourcePk(type, id))))
          .getSingleOrNull();

  Future<List<FireflyCachedResource>> list(FireflyEntityType type) =>
      _byType(type).get();

  Stream<List<FireflyCachedResource>> watch(FireflyEntityType type) =>
      _byType(type).watch();

  Future<void> write(FireflyEntityType type, String id, JsonObject data,
          {DateTime? modifiedAt}) =>
      db.into(db.fireflyResourceCache).insertOnConflictUpdate(
            FireflyResourceCacheCompanion.insert(
              resourcePk: resourcePk(type, id),
              entityType: type,
              json: jsonEncode(data),
              dateTimeModified: Value(modifiedAt),
            ),
          );

  Future<void> remove(FireflyEntityType type, String id) =>
      (db.delete(db.fireflyResourceCache)
            ..where((row) => row.resourcePk.equals(resourcePk(type, id))))
          .go();

  SimpleSelectStatement<$FireflyResourceCacheTable, FireflyCachedResource>
      _byType(FireflyEntityType type) => db.select(db.fireflyResourceCache)
        ..where((row) => row.entityType.equalsValue(type));
}
