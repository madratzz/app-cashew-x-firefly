import 'package:budget/database/schema_versions.dart';
import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';

const _walletPk = '0';
const _categoryPk = '0';
const _transactionPk = 'transaction';
const _budgetPk = 'budget';
const _payeePk = 'payee';
const _groupPk = 'group';
const _tagPk = 'tag';

void main() {
  final verifier = SchemaVerifier(
    _SchemaSnapshots(),
    setup: (raw) => raw.execute('PRAGMA foreign_keys = ON'),
  );

  test('upgrades the v46 snapshot and preserves legacy rows', () async {
    final schema = await verifier.schemaAt(46);
    addTearDown(schema.rawDatabase.dispose);
    schema.rawDatabase
      ..execute("""
        INSERT INTO wallets (wallet_pk, name, date_created, "order")
        VALUES ('0', 'Default wallet', 1700000000, 0)
      """)
      ..execute("""
        INSERT INTO categories (category_pk, name, date_created, "order")
        VALUES ('0', 'Balance correction', 1700000000, 0)
      """)
      ..execute("""
        INSERT INTO transactions
          (transaction_pk, name, amount, note, category_fk, date_created)
        VALUES ('transaction', 'Correction', 12.5, '', '0', 1700000000)
      """);
    final db = FinanceDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 47, validateDropped: true);
    expect(await _userVersion(db), 47);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);

    final wallet = await db.select(db.wallets).getSingle();
    expect(wallet.walletPk, _walletPk);
    expect(wallet.name, 'Default wallet');
    expect(wallet.accountKind, AccountKind.asset);
    expect(wallet.archived, isFalse);

    final transaction = await db.select(db.transactions).getSingle();
    expect(transaction.transactionPk, _transactionPk);
    expect(transaction.name, 'Correction');
    expect(transaction.amount, 12.5);
    expect(transaction.categoryFk, _categoryPk);
    expect(transaction.walletFk, _walletPk);
    expect(transaction.payeeFk, isNull);
    expect(transaction.foreignAmount, isNull);
    expect(transaction.foreignCurrency, isNull);
    expect(transaction.splitGroupFk, isNull);
    expect(transaction.splitOrder, isNull);
    expect(transaction.fireflyType, isNull);
    expect(transaction.billFk, isNull);
    expect(transaction.reconciled, isFalse);

    // Legacy JSON has no values for the new non-nullable fields.
    final walletJson = wallet.toJson()
      ..remove('accountKind')
      ..remove('archived');
    expect(TransactionWallet.fromJson(walletJson), wallet);
    final transactionJson = transaction.toJson()..remove('reconciled');
    expect(Transaction.fromJson(transactionJson), transaction);
  });

  test('creates schema v47 and round-trips Firefly rows and columns', () async {
    final db = FinanceDatabase(
      NativeDatabase.memory(
          setup: (raw) => raw.execute('PRAGMA foreign_keys = ON')),
    );
    addTearDown(db.close);

    expect(await _userVersion(db), 47);

    final now = DateTime(2024, 1, 1);
    final end = DateTime(2024, 1, 31);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value(_categoryPk),
          name: 'Balance correction',
          order: 0,
        ));
    final wallet = await db.into(db.wallets).insertReturning(
          WalletsCompanion.insert(
            walletPk: const Value(_walletPk),
            name: 'Credit',
            order: 0,
            accountKind: const Value(AccountKind.liability),
            archived: const Value(true),
          ),
        );
    expect(wallet.accountKind, AccountKind.liability);
    expect(wallet.archived, isTrue);

    await db.into(db.budgets).insert(BudgetsCompanion.insert(
          budgetPk: const Value(_budgetPk),
          name: 'Groceries',
          amount: 100,
          startDate: now,
          endDate: end,
          periodLength: 1,
          order: 0,
        ));

    await _roundTrip(
        db,
        db.payees,
        Payee(
          payeePk: _payeePk,
          name: 'Shop',
          kind: PayeeKind.expense,
          active: true,
          dateCreated: now,
          dateTimeModified: now,
        ));
    await _roundTrip(
        db,
        db.transactionGroups,
        TransactionGroup(
          groupPk: _groupPk,
          title: 'Receipt',
          dateTimeModified: now,
        ));

    final transaction = await db.into(db.transactions).insertReturning(
          TransactionsCompanion.insert(
            transactionPk: const Value(_transactionPk),
            name: 'Groceries',
            amount: -20,
            note: '',
            categoryFk: _categoryPk,
            payeeFk: const Value(_payeePk),
            foreignAmount: const Value(25.5),
            foreignCurrency: const Value('eur'),
            splitGroupFk: const Value(_groupPk),
            splitOrder: const Value(1),
            fireflyType: const Value(FireflyTransactionType.withdrawal),
            billFk: const Value('bill'),
            reconciled: const Value(true),
          ),
        );
    expect(transaction.payeeFk, _payeePk);
    expect(transaction.foreignAmount, 25.5);
    expect(transaction.foreignCurrency, 'eur');
    expect(transaction.splitGroupFk, _groupPk);
    expect(transaction.splitOrder, 1);
    expect(transaction.fireflyType, FireflyTransactionType.withdrawal);
    expect(transaction.billFk, 'bill');
    expect(transaction.reconciled, isTrue);

    await _roundTrip(
        db,
        db.tags,
        Tag(
          tagPk: _tagPk,
          name: 'Monthly',
          description: 'A regular purchase',
          date: now,
          dateCreated: now,
          dateTimeModified: now,
        ));
    await _roundTrip(
      db,
      db.transactionTags,
      const TransactionTagLink(transactionFk: _transactionPk, tagFk: _tagPk),
    );
    await _roundTrip(
        db,
        db.attachments,
        Attachment(
          attachmentPk: 'receipt',
          attachableType: 'TransactionJournal',
          attachableFk: _transactionPk,
          filename: 'receipt.pdf',
          mime: 'application/pdf',
          size: 120,
          uploadState: 'uploaded',
          dateCreated: now,
          dateTimeModified: now,
        ));
    await _roundTrip(
        db,
        db.accountDetails,
        AccountDetail(
          walletFk: _walletPk,
          liabilityType: 'loan',
          liabilityDirection: 'credit',
          interest: 3.5,
          interestPeriod: 'yearly',
          includeNetWorth: true,
          virtualBalance: 5,
          serverBalance: -20,
          serverBalanceDate: now,
          dateTimeModified: now,
        ));
    await _roundTrip(
        db,
        db.budgetLimits,
        BudgetLimit(
          budgetLimitPk: 'limit',
          budgetFk: _budgetPk,
          start: now,
          end: end,
          amount: 100,
          currency: 'eur',
          dateTimeModified: now,
        ));
    await _roundTrip(
      db,
      db.fireflySyncMeta,
      const FireflySyncMetaEntry(key: 'deleteLogCursor', value: '1700000000'),
    );
    await _roundTrip(
        db,
        db.fireflyResourceCache,
        FireflyCachedResource(
          resourcePk: 'bill',
          entityType: FireflyEntityType.bill,
          json: '{"name":"Utilities"}',
          dateTimeModified: now,
        ));
    await _roundTrip(
        db,
        db.fireflyConflicts,
        FireflyConflict(
          conflictPk: 'conflict',
          entityType: FireflyEntityType.transaction,
          localPk: _transactionPk,
          remoteId: '12',
          localJson: '{"amount":20}',
          remoteJson: '{"amount":25}',
          resolution: 'serverWins',
          dateCreated: now,
          acknowledged: false,
        ));
    final mapping = FireflyIdMapping(
      entityType: FireflyEntityType.transaction,
      localPk: _transactionPk,
      remoteId: '12',
      remoteSubId: '13',
      remoteRole: 0,
      state: FireflySyncState.synced,
      attempts: 0,
      remoteUpdatedAt: now,
      localVersionAt: now,
    );
    await _roundTrip(db, db.fireflyIdMap, mapping);

    // Each local key and each complete remote key is unique within its type.
    await expectLater(
      db.into(db.fireflyIdMap).insert(mapping.copyWith(localPk: 'duplicate')),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.into(db.fireflyIdMap).insert(mapping.copyWith(remoteId: '14')),
      throwsA(isA<SqliteException>()),
    );
    await db.into(db.fireflyIdMap).insert(
          mapping.copyWith(localPk: 'transfer-side', remoteRole: 1),
        );
    await expectLater(
      db.into(db.transactionTags).insert(
            const TransactionTagLink(
                transactionFk: _transactionPk, tagFk: _tagPk),
          ),
      throwsA(isA<SqliteException>()),
    );
  });
}

Future<int> _userVersion(FinanceDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}

Future<void> _roundTrip<T extends Table, D extends Insertable<D>>(
  FinanceDatabase db,
  TableInfo<T, D> table,
  D row,
) async {
  await db.into(table).insert(row);
  expect(await db.select(table).getSingle(), row);
}

class _SchemaSnapshots implements SchemaInstantiationHelper {
  @override
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version) =>
      _SnapshotDatabase(db, version);
}

// Reuse the Drift snapshots generated from drift_schema_v46.json and v47.json.
class _SnapshotDatabase extends GeneratedDatabase {
  _SnapshotDatabase(super.executor, this.schemaVersion);

  // Earlier schema dumps evaluate these SQL defaults with DateTime.now().
  // Use one timestamp across snapshots so verifying them is deterministic.
  static final _legacyTimestampDefault = RegExp(
    r'("(?:date_time_modified|original_date_due)" INTEGER(?: NOT)? NULL DEFAULT )\d+',
  );

  @override
  Future<void> customStatement(String statement, [List<Object?>? args]) {
    return super.customStatement(
      statement.replaceAllMapped(
        _legacyTimestampDefault,
        (match) => '${match[1]}1700000000',
      ),
      args,
    );
  }

  @override
  final int schemaVersion;

  @override
  late final Iterable<DatabaseSchemaEntity> allSchemaEntities =
      switch (schemaVersion) {
    46 => Schema46(database: this).entities,
    47 => Schema47(database: this).entities,
    _ => throw MissingSchemaException(schemaVersion, const [46, 47]),
  };

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
}
