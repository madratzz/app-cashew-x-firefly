import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/id_map_repository.dart';
import 'package:drift/drift.dart';

extension FireflyPayeeQueries on FinanceDatabase {
  Future<Payee?> fireflyPayee(String pk) => _payee(pk).getSingleOrNull();

  Stream<Payee?> watchFireflyPayee(String pk) => _payee(pk).watchSingleOrNull();

  Future<List<Payee>> fireflyPayees({String? search}) async =>
      _matchingPayees(await _payeeList().get(), search);

  Stream<List<Payee>> watchFireflyPayees({
    String? search,
    PayeeKind? kind,
    bool activeOnly = false,
  }) =>
      _payeeList(kind: kind, activeOnly: activeOnly)
          .watch()
          .map((rows) => _matchingPayees(rows, search));

  Stream<List<Transaction>> watchFireflyPayeeTransactions(String payeePk) =>
      (select(transactions)
            ..where((row) => row.payeeFk.equals(payeePk))
            ..orderBy([
              (row) => OrderingTerm.desc(row.dateCreated),
              (row) => OrderingTerm.asc(row.transactionPk),
            ]))
          .watch();

  Future<Payee> fireflyCreatePayee({
    required String name,
    required PayeeKind kind,
    bool active = true,
    String? notes,
    String? iban,
  }) =>
      into(payees).insertReturning(PayeesCompanion.insert(
        name: _localPayeeName(name),
        kind: kind,
        active: Value(active),
        notes: Value(_optionalText(notes)),
        iban: Value(_payeeIban(iban)),
        dateTimeModified: Value(DateTime.now()),
      ));

  /// Firefly fixes the account kind at creation.
  Future<Payee?> fireflyUpdatePayee(Payee payee) => transaction(() async {
        final previous = await fireflyPayee(payee.payeePk);
        if (previous == null) return null;

        final now = DateTime.now();
        final next = previous.dateTimeModified?.add(const Duration(seconds: 1));
        await (update(payees)
              ..where((row) => row.payeePk.equals(payee.payeePk)))
            .write(PayeesCompanion(
          name: Value(_localPayeeName(payee.name)),
          active: Value(payee.active),
          notes: Value(_optionalText(payee.notes)),
          iban: Value(_payeeIban(payee.iban)),
          dateTimeModified:
              Value(next != null && next.isAfter(now) ? next : now),
        ));
        return fireflyPayee(payee.payeePk);
      });

  /// Queues account deletion and clears local references in one transaction.
  Future<void> fireflyDeletePayee(String pk) => transaction(() async {
        await IdMapRepository(this)
            .markPendingDelete(FireflyEntityType.payeeAccount, pk);
        await removePulledFireflyPayee(pk);
      });

  Future<void> writePulledFireflyPayee(Payee payee) =>
      into(payees).insertOnConflictUpdate(payee);

  Future<void> removePulledFireflyPayee(String pk) => transaction(() async {
        await (update(transactions)..where((row) => row.payeeFk.equals(pk)))
            .write(const TransactionsCompanion(payeeFk: Value(null)));
        await (delete(payees)..where((row) => row.payeePk.equals(pk))).go();
      });

  SimpleSelectStatement<$PayeesTable, Payee> _payee(String pk) =>
      select(payees)..where((row) => row.payeePk.equals(pk));

  SimpleSelectStatement<$PayeesTable, Payee> _payeeList({
    PayeeKind? kind,
    bool activeOnly = false,
  }) {
    final query = select(payees)
      ..orderBy([
        (row) => OrderingTerm.asc(row.name.collate(Collate.noCase)),
        (row) => OrderingTerm.asc(row.payeePk),
      ]);
    if (kind != null) query.where((row) => row.kind.equalsValue(kind));
    if (activeOnly) query.where((row) => row.active.equals(true));
    return query;
  }
}

List<Payee> _matchingPayees(List<Payee> rows, String? search) {
  final term = search?.trim().toLowerCase();
  if (term == null || term.isEmpty) return rows;
  return rows.where((row) => row.name.toLowerCase().contains(term)).toList();
}

String _localPayeeName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty || trimmed.runes.length > 1024) {
    throw ArgumentError.value(name, 'name', 'Expected 1 to 1024 characters');
  }
  return trimmed;
}

String? _optionalText(String? text) =>
    text == null || text.trim().isEmpty ? null : text.trim();

String? _payeeIban(String? iban) =>
    _optionalText(iban?.replaceAll(RegExp(r'\s+'), ''));
