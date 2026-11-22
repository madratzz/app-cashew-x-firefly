import 'dart:convert';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/db/budget_queries.dart';
import 'package:budget/firefly/db/category_queries.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:budget/firefly/db/objective_queries.dart';
import 'package:budget/firefly/db/wallet_queries.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/hashing.dart';
import 'package:drift/drift.dart';

/// Roams the presentation fields of rows linked to Firefly.
class FireflyMetaRoaming {
  const FireflyMetaRoaming(this.context, {this.enabled = false});

  static const String settingKey = 'fireflyMetaRoaming';

  final SyncContext context;
  final bool enabled;

  static const _collections = {
    FireflyEntityType.walletAccount: 'wallets',
    FireflyEntityType.liabilityAccount: 'liabilities',
    FireflyEntityType.category: 'categories',
    FireflyEntityType.budget: 'budgets',
    FireflyEntityType.piggyBank: 'objectives',
  };

  Future<void> pull() => _sync(upload: false);
  Future<void> push() => _sync(upload: true);

  Future<void> _sync({required bool upload}) async {
    if (!enabled || !context.config.mode) return;
    for (final collection in _collections.entries) {
      if (context.isCancelled()) return;
      final type = collection.key;
      final mappings = (await context.idMap.list(type)).where(_canRoam);
      if (mappings.isEmpty) continue;

      final name = 'cashew.${collection.value}.v1';
      final localKey = 'metaRoaming.$name';
      final api = context.api.preferences;
      JsonObject? remote;
      try {
        final preference = await api.get(name);
        if (preference.name != name || preference.data is! String) {
          throw const FireflyInvalidPayload();
        }
        remote = _decode(preference.data as String);
      } on FireflyNotFound {
        // First device to roam this collection creates the preference.
      }
      if (context.isCancelled()) return;

      final rows = remote ?? <String, Object?>{};
      final merged = await context.db.transaction(() async {
        final before = await context.meta.read(localKey);
        final saved = before == null ? <String, Object?>{} : _decode(before);
        final accepted = <String, Object?>{};
        final afterUpload = <String, Object?>{};
        var changed = false;

        for (final mapping in mappings) {
          final local = await _readLocal(type, mapping.localPk);
          if (local == null) continue;
          final id = mapping.remoteId;
          final previous = saved[id] as JsonObject?;
          final baseline = previous?['pk'] == mapping.localPk
              ? (previous?['fields'] as JsonObject?)
              : null;
          final remoteFields = _fields(rows[id]);
          final outgoing = {...remoteFields};
          final applied = <String, Object?>{};
          final acknowledged = <String, Object?>{};
          final uploaded = <String, Object?>{};

          for (final field in local.fields.entries) {
            final key = field.key;
            final localValue = field.value;
            final last = _stamp(key, baseline?[key]);
            final incoming = _stamp(key, remoteFields[key]);
            final localTime = local.modifiedAt ?? context.now();
            if (incoming == null ||
                (last != null && last.at.isAfter(incoming.at)) ||
                (last != null &&
                    localValue != last.value &&
                    localValue != incoming.value &&
                    (incoming.at == last.at && incoming.value == last.value ||
                        localTime.isAfter(incoming.at)))) {
              if (last != null) acknowledged[key] = last.json;
              if (upload) {
                final entry =
                    _outgoingStamp(localValue, localTime, last, incoming).json;
                outgoing[key] = entry;
                uploaded[key] = entry;
                changed = true;
              }
            } else {
              acknowledged[key] = incoming.json;
              uploaded[key] = incoming.json;
              if (localValue != incoming.value) applied[key] = incoming.value;
            }
          }
          if (applied.isNotEmpty) await local.write(applied);
          if (outgoing.isNotEmpty) rows[id] = outgoing;
          accepted[id] = {'pk': mapping.localPk, 'fields': acknowledged};
          afterUpload[id] = {'pk': mapping.localPk, 'fields': uploaded};
        }
        // Update pulled baselines together with their Drift fields. Unsent
        // local edits keep their old baselines until Firefly accepts the write.
        final checkpoint = canonicalJson(accepted);
        if (checkpoint != before) {
          await context.meta.write(localKey, checkpoint);
        }
        return changed ? canonicalJson(afterUpload) : null;
      });

      if (merged == null || context.isCancelled()) continue;
      final data = canonicalJson(rows);
      if (remote == null) {
        await api.create({'name': name, 'data': data});
      } else {
        await api.update(name, {'data': data});
      }
      await context.meta.write(localKey, merged);
    }
  }

  bool _canRoam(FireflyIdMapping mapping) =>
      !IdMapRepository.isProvisional(mapping) &&
      mapping.state != FireflySyncState.localOnly &&
      mapping.state != FireflySyncState.pendingDelete;

  Future<_LocalRow?> _readLocal(FireflyEntityType type, String pk) async {
    final db = context.db;
    switch (type) {
      case FireflyEntityType.walletAccount:
      case FireflyEntityType.liabilityAccount:
        final row = await db.fireflyWallet(pk);
        if (row == null) return null;
        // Account order already synchronizes through Firefly's native API.
        return _LocalRow(
          row.dateTimeModified,
          {'colour': row.colour, 'iconName': row.iconName},
          (fields) => (db.update(db.wallets)
                ..where((wallet) => wallet.walletPk.equals(pk)))
              .write(WalletsCompanion(
            colour: _value(fields, 'colour'),
            iconName: _value(fields, 'iconName'),
          )),
        );
      case FireflyEntityType.category:
        final row = await db.fireflyCategory(pk);
        if (row == null) return null;
        return _LocalRow(
          row.dateTimeModified,
          {
            'colour': row.colour,
            'iconName': row.iconName,
            'emojiIconName': row.emojiIconName,
            'order': row.order,
          },
          (fields) => (db.update(db.categories)
                ..where((category) => category.categoryPk.equals(pk)))
              .write(CategoriesCompanion(
            colour: _value(fields, 'colour'),
            iconName: _value(fields, 'iconName'),
            emojiIconName: _value(fields, 'emojiIconName'),
            order: _value(fields, 'order'),
          )),
        );
      case FireflyEntityType.budget:
        final row = await db.fireflyBudget(pk);
        if (row == null) return null;
        return _LocalRow(
          row.dateTimeModified,
          {'colour': row.colour, 'order': row.order},
          (fields) => (db.update(db.budgets)
                ..where((budget) => budget.budgetPk.equals(pk)))
              .write(BudgetsCompanion(
            colour: _value(fields, 'colour'),
            order: _value(fields, 'order'),
          )),
        );
      case FireflyEntityType.piggyBank:
        final row = await db.fireflyObjective(pk);
        if (row == null) return null;
        return _LocalRow(
          row.dateTimeModified,
          {
            'colour': row.colour,
            'iconName': row.iconName,
            'emojiIconName': row.emojiIconName,
            'order': row.order,
          },
          (fields) => (db.update(db.objectives)
                ..where((objective) => objective.objectivePk.equals(pk)))
              .write(ObjectivesCompanion(
            colour: _value(fields, 'colour'),
            iconName: _value(fields, 'iconName'),
            emojiIconName: _value(fields, 'emojiIconName'),
            order: _value(fields, 'order'),
          )),
        );
      default:
        throw StateError('Unsupported roaming collection');
    }
  }
}

_Stamp _outgoingStamp(
  Object? value,
  DateTime localTime,
  _Stamp? last,
  _Stamp? incoming,
) {
  if (last != null && value == last.value) return last;
  // Keep versions increasing even if the device clock moved back.
  var at = localTime;
  for (final stamp in [last, incoming].whereType<_Stamp>()) {
    if (!at.isAfter(stamp.at)) {
      at = stamp.at.add(const Duration(microseconds: 1));
    }
  }
  return _Stamp(value, at);
}

class _LocalRow {
  const _LocalRow(this.modifiedAt, this.fields, this.write);

  final DateTime? modifiedAt;
  final JsonObject fields;
  final Future<int> Function(JsonObject) write;
}

class _Stamp {
  const _Stamp(this.value, this.at);

  final Object? value;
  final DateTime at;
  JsonObject get json => {'value': value, 'at': at.toUtc().toIso8601String()};
}

JsonObject _decode(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is JsonObject) return decoded;
  } on FormatException {
    throw const FireflyInvalidPayload();
  }
  throw const FireflyInvalidPayload();
}

JsonObject _fields(Object? raw) {
  if (raw == null) return const {};
  if (raw is JsonObject) return raw;
  throw const FireflyInvalidPayload();
}

_Stamp? _stamp(String key, Object? raw) {
  if (raw == null) return null;
  if (raw is! JsonObject || !raw.containsKey('value')) {
    throw const FireflyInvalidPayload();
  }
  final timestamp = raw['at'];
  final at = timestamp is String ? DateTime.tryParse(timestamp) : null;
  final value = raw['value'];
  final valid = switch (key) {
    'order' => value is int,
    'colour' =>
      value == null || value is String && value.length <= COLOUR_LIMIT,
    _ => value == null || value is String,
  };
  if (at == null || !valid) throw const FireflyInvalidPayload();
  return _Stamp(value, at);
}

Value<T> _value<T>(JsonObject fields, String key) =>
    fields.containsKey(key) ? Value(fields[key] as T) : const Value.absent();
