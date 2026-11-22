import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/bill.dart';
import 'package:budget/firefly/api/models/recurrence.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/resource_cache_repository.dart';
import 'package:budget/firefly/db/sync_meta_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _bill = FireflyEntityType.bill;
const _recurrence = FireflyEntityType.recurrence;

/// Cache primary keys are also the local IDs used by sync and bill links.
extension FireflyBillRecurrenceQueries on FinanceDatabase {
  Future<FireflyCachedResource?> fireflyBill(String pk) =>
      readFireflySchedule(_bill, pk);

  Future<FireflyCachedResource?> fireflyRecurrence(String pk) =>
      readFireflySchedule(_recurrence, pk);

  Stream<List<FireflyCachedResource>> watchFireflyBills() =>
      ResourceCacheRepository(this).watch(_bill);

  Stream<List<FireflyCachedResource>> watchFireflyRecurrences() =>
      ResourceCacheRepository(this).watch(_recurrence);

  /// Omit [pk] to create an offline draft. Supply it to edit an existing row.
  Future<String> saveFireflyBill(JsonObject fields, {String? pk}) => _save(
        _bill,
        FireflyBill(id: '', attributes: fields).toWriteJson(),
        pk,
      );

  /// Template references use server IDs. Keep a template's id when editing it.
  Future<String> saveFireflyRecurrence(JsonObject fields, {String? pk}) =>
      _save(
        _recurrence,
        {
          ...FireflyRecurrence(id: '', attributes: fields)
              .toWriteJson(updating: true),
          if (fields.containsKey('type')) 'type': fields['type'],
        },
        pk,
      );

  Future<void> deleteFireflyBill(String pk) => _delete(_bill, pk);

  Future<void> deleteFireflyRecurrence(String pk) => _delete(_recurrence, pk);

  Future<FireflyCachedResource?> readFireflySchedule(
      FireflyEntityType type, String pk) {
    final cache = ResourceCacheRepository(this);
    return cache.read(type, _cacheId(type, pk));
  }

  Future<void> writeFireflySchedule(
    FireflyEntityType type,
    String pk,
    JsonObject attributes, {
    DateTime? modifiedAt,
  }) =>
      ResourceCacheRepository(this)
          .write(type, _cacheId(type, pk), attributes, modifiedAt: modifiedAt);

  /// Called by sync when the remote resource no longer exists.
  Future<void> removeFireflySchedule(FireflyEntityType type, String pk) async {
    await ResourceCacheRepository(this).remove(type, _cacheId(type, pk));
    if (type == _bill) {
      await (update(transactions)..where((row) => row.billFk.equals(pk)))
          .write(const TransactionsCompanion(billFk: Value(null)));
    }
  }

  Future<String> _save(FireflyEntityType type, JsonObject fields, String? pk) =>
      transaction(() async {
        final id = ResourceCacheRepository.resourcePk(
            type, pk == null ? const Uuid().v4() : _cacheId(type, pk));
        final old = await readFireflySchedule(type, id);
        if (pk != null && old == null) throw const FireflyNotFound();
        if (type == _recurrence && old != null && fields.containsKey('type')) {
          final mapping = await IdMapRepository(this).byLocal(type, id);
          if (mapping != null && !IdMapRepository.isProvisional(mapping)) {
            fields.remove('type');
          }
        }
        // Drift stores seconds. Two offline edits in the same second must
        // still sort after the version currently in the sync map.
        final now = DateTime.now();
        final previous = old?.dateTimeModified;
        final next = previous?.add(const Duration(seconds: 1));
        await writeFireflySchedule(
          type,
          id,
          {
            if (old != null) ...ResourceCacheRepository.decode(old),
            ...fields,
          },
          modifiedAt: next != null && next.isAfter(now) ? next : now,
        );
        return id;
      });

  Future<void> _delete(FireflyEntityType type, String pk) =>
      transaction(() async {
        final id = ResourceCacheRepository.resourcePk(type, _cacheId(type, pk));
        final idMap = IdMapRepository(this);
        final mapping = await idMap.byLocal(type, id);
        // A create interrupted after the server accepted it can still be
        // found by its unique name when the next pull resolves this delete.
        if (mapping?.state == FireflySyncState.creating) {
          final row = await readFireflySchedule(type, id);
          if (row != null) {
            final field = type == _bill ? 'name' : 'title';
            final name = ResourceCacheRepository.decode(row)[field];
            if (name is String) {
              await SyncMetaRepository(this).write(
                  fireflyScheduleDeleteKey(id), name.trim().toLowerCase());
            }
          }
        }
        await idMap.markPendingDelete(type, id);
        await removeFireflySchedule(type, id);
      });
}

String _cacheId(FireflyEntityType type, String pk) {
  final prefix = '${type.name}:';
  return pk.startsWith(prefix) ? pk.substring(prefix.length) : pk;
}

String fireflyScheduleDeleteKey(String pk) => 'pendingScheduleCreateDelete.$pk';
