import 'dart:math';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/account.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/payee_queries.dart';
import 'package:budget/firefly/sync/collection_sync.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:uuid/uuid.dart';

const _type = FireflyEntityType.payeeAccount;

class PayeeAccountSyncer extends EntitySyncer {
  const PayeeAccountSyncer();

  static final _cycles = Expando<CollectionSync<FireflyAccount>>();

  @override
  FireflyEntityType get type => _type;

  CollectionSync<FireflyAccount> _cycle(SyncContext context) =>
      _cycles[context] ??= CollectionSync(
        adapter: _PayeeAdapter(context),
        idMap: context.idMap,
        conflicts: context.conflicts,
        pageSize: context.config.pageSize,
        now: context.now,
      );

  @override
  Future<void> pull(SyncContext context) async {
    if (context.config.mode && !context.isCancelled()) {
      await _cycle(context).pull();
    }
  }

  @override
  Future<void> push(SyncContext context) async {
    if (context.config.mode && !context.isCancelled()) {
      await _cycle(context).push();
    }
  }

  @override
  Future<void> pushDeletes(SyncContext context) async {
    if (context.config.mode && !context.isCancelled()) {
      await _cycle(context).pushDeletes();
    }
  }
}

class _PayeeAdapter extends CollectionAdapter<FireflyAccount> {
  _PayeeAdapter(this.context);

  final SyncContext context;
  final _lastPages = <PayeeKind, FireflyPage<FireflyAccount>>{};

  FinanceDatabase get _db => context.db;

  @override
  FireflyEntityType get type => _type;

  @override
  bool get compareHashWhenTimestampsEqual => true;

  @override
  Future<FireflyPage<RemoteCollectionRow<FireflyAccount>>> page(
      int page, int limit) async {
    if (page == 1) _lastPages.clear();
    final rows = <RemoteCollectionRow<FireflyAccount>>[];
    var valid = true;

    // /accounts accepts one type filter. Expose both streams as one collection
    // so a remote deletion requires a complete listing of both account kinds.
    for (final kind in PayeeKind.values) {
      final previous = _lastPages[kind];
      if (previous != null && page > previous.totalPages) continue;
      final result = await context.api.accounts
          .list(type: kind.name, page: page, limit: limit);
      _lastPages[kind] = result;
      valid = valid &&
          result.currentPage == page &&
          result.total >= 0 &&
          result.totalPages >= 0 &&
          result.perPage > 0 &&
          result.items.length <= result.perPage &&
          (previous == null ||
              (previous.total == result.total &&
                  previous.perPage == result.perPage &&
                  previous.totalPages == result.totalPages)) &&
          (page <= result.totalPages ||
              (page == 1 && result.totalPages == 0 && result.total == 0)) &&
          (page >= result.totalPages || result.items.isNotEmpty);
      for (final account in result.items) {
        if (account.type == kind.name) {
          rows.add(_remoteRow(account));
        } else {
          valid = false;
        }
      }
    }

    return FireflyPage(
      items: rows,
      total: _lastPages.values.fold(0, (sum, result) => sum + result.total),
      // An invalid member listing must suppress collection-wide deletes.
      currentPage: valid ? page : 0,
      perPage: _lastPages.values.fold(0, (sum, result) => sum + result.perPage),
      totalPages: _lastPages.values
          .fold(0, (count, result) => max(count, result.totalPages)),
    );
  }

  @override
  Future<List<LocalCollectionRow>> listLocal() async =>
      (await _db.fireflyPayees()).map(_localRow).toList();

  @override
  Future<LocalCollectionRow?> readLocal(String pk) async {
    final payee = await _db.fireflyPayee(pk);
    return payee == null ? null : _localRow(payee);
  }

  @override
  Future<String?> findNaturalKey(
      RemoteCollectionRow<FireflyAccount> remote) async {
    final name = (remote.fields['name'] as String).toLowerCase();
    for (final payee in await _db.fireflyPayees()) {
      if (payee.kind.name != remote.fields['type'] ||
          payee.name.trim().toLowerCase() != name) {
        continue;
      }
      final mapping = await context.idMap.byLocal(type, payee.payeePk);
      if (mapping == null || IdMapRepository.isProvisional(mapping)) {
        return payee.payeePk;
      }
    }
    return null;
  }

  @override
  Future<LocalCollectionRow> applyRemote(
      RemoteCollectionRow<FireflyAccount> remote,
      {String? localPk}) async {
    final existing = localPk == null ? null : await _db.fireflyPayee(localPk);
    final fields = remote.fields;
    final row = Payee(
      payeePk: localPk ?? const Uuid().v4(),
      name: fields['name'] as String,
      kind: PayeeKind.values.byName(fields['type'] as String),
      active: fields['active'] as bool,
      notes: fields['notes'] as String?,
      iban: fields['iban'] as String?,
      dateCreated:
          remote.value.createdAt ?? existing?.dateCreated ?? context.now(),
      dateTimeModified: remote.updatedAt,
    );
    await _db.writePulledFireflyPayee(row);
    return _localRow((await _db.fireflyPayee(row.payeePk))!);
  }

  @override
  Future<void> removeLocal(String pk) => _db.removePulledFireflyPayee(pk);

  @override
  Future<RemoteCollectionRow<FireflyAccount>> createRemote(
          LocalCollectionRow local) async =>
      _remoteRow(await context.api.accounts.create(local.fields));

  @override
  Future<RemoteCollectionRow<FireflyAccount>> updateRemote(
          FireflyIdMapping mapping, LocalCollectionRow local) async =>
      _remoteRow(
          await context.api.accounts.update(mapping.remoteId, local.fields));

  @override
  Future<void> removeRemote(String id) => context.api.accounts.delete(id);

  @override
  Future<RemoteCollectionRow<FireflyAccount>?> findDuplicate(
      LocalCollectionRow local, FireflyValidation error) async {
    final duplicate =
        RegExp(r'already (?:in use|exists|been taken)', caseSensitive: false);
    if (!(error.errors['name'] ?? [error.message]).any(duplicate.hasMatch)) {
      return null;
    }

    final kind = local.fields['type'] as String;
    final name = (local.fields['name'] as String).toLowerCase();
    var requested = 1;
    while (true) {
      final page = await context.api.accounts
          .list(type: kind, page: requested, limit: context.config.pageSize);
      for (final account in page.items) {
        if (account.type == kind &&
            account.name?.trim().toLowerCase() == name) {
          return _remoteRow(account);
        }
      }
      if (page.currentPage != requested ||
          requested >= page.totalPages ||
          page.items.isEmpty) {
        return null;
      }
      requested++;
    }
  }

  LocalCollectionRow _localRow(Payee payee) => LocalCollectionRow(
        pk: payee.payeePk,
        fields: _fields(
            payee.name, payee.kind.name, payee.active, payee.notes, payee.iban),
        modifiedAt: payee.dateTimeModified,
        snapshot: payee.toJson(),
      );

  RemoteCollectionRow<FireflyAccount> _remoteRow(FireflyAccount account) {
    final name = account.name?.trim();
    if (name == null ||
        name.isEmpty ||
        !PayeeKind.values.any((kind) => kind.name == account.type)) {
      throw const FireflyInvalidPayload();
    }
    return RemoteCollectionRow(
      id: account.id,
      value: account,
      fields: _fields(name, account.type!, account.active ?? true,
          account.notes, account.iban),
      updatedAt: account.updatedAt,
    );
  }

  JsonObject _fields(
          String name, String kind, bool active, String? notes, String? iban) =>
      {
        'name': name.trim(),
        'type': kind,
        'active': active,
        'notes': _nonEmpty(notes),
        'iban': _nonEmpty(iban),
      };

  String? _nonEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
