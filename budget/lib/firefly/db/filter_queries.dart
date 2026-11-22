import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/attachment.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:drift/drift.dart';

/// Firefly-only transaction filters. Empty values mean "ignore".
class FireflySearchFilters {
  FireflySearchFilters({
    this.payeePk,
    List<String>? tagPks,
    this.matchAllTags = false,
    this.billPk,
    this.reconciled,
    this.hasAttachment,
  }) : tagPks = tagPks ?? [];

  String? payeePk;
  List<String> tagPks;
  bool matchAllTags;
  String? billPk;
  bool? reconciled;
  bool? hasAttachment;

  bool get isClear =>
      payeePk == null &&
      tagPks.isEmpty &&
      billPk == null &&
      reconciled == null &&
      hasAttachment == null;

  void clear() {
    payeePk = null;
    tagPks = [];
    matchAllTags = false;
    billPk = null;
    reconciled = null;
    hasAttachment = null;
  }

  FireflySearchFilters copy() => FireflySearchFilters(
        payeePk: payeePk,
        tagPks: [...tagPks],
        matchAllTags: matchAllTags,
        billPk: billPk,
        reconciled: reconciled,
        hasAttachment: hasAttachment,
      );
}

extension FireflyFilterQueries on FinanceDatabase {
  Future<List<String>> fireflyFilteredTransactionPks(
      {String? payeePk,
      List<String> tagPks = const [],
      bool matchAllTags = false,
      String? billPk,
      bool? reconciled,
      bool? hasAttachment}) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.transactionPk])
      ..where(_fireflyFilterExpression(FireflySearchFilters(
        payeePk: payeePk,
        tagPks: [...tagPks],
        matchAllTags: matchAllTags,
        billPk: billPk,
        reconciled: reconciled,
        hasAttachment: hasAttachment,
      )))
      ..orderBy([
        OrderingTerm.desc(transactions.dateCreated),
        OrderingTerm.asc(transactions.transactionPk),
      ]);
    return [
      for (final row in await query.get())
        row.read(transactions.transactionPk)!,
    ];
  }

  /// Transactions matching [filters] and the legacy [searchFilters]. The text
  /// query also matches payee and tag names, so search works offline.
  Stream<List<Transaction>> watchFireflyFilteredTransactions(
    FireflySearchFilters filters, {
    SearchFilters? searchFilters,
  }) {
    final legacy = searchFilters?.copyWith();
    final text = legacy?.searchQuery?.trim() ?? '';
    legacy?.searchQuery = null;
    return (select(transactions)
          ..where((row) =>
              _fireflyFilterExpression(filters) &
              onlyShowIfFollowsSearchFilters(
                row,
                legacy,
                joinedWithSubcategoriesTable: null,
                joinedWithObjectiveLoans: null,
                joinedWithCategories: false,
                joinedWithBudgets: false,
                joinedWithObjectives: false,
              ) &
              (text.isEmpty
                  ? const Constant(true)
                  : _fireflyTextMatch(text, includeLegacyFields: true)))
          ..orderBy([
            (row) => OrderingTerm.desc(row.dateCreated),
            (row) => OrderingTerm.asc(row.transactionPk),
          ]))
        .watch();
  }

  /// Transactions whose payee or tag name contains [search] but whose own
  /// title and note do not; these are missed by the legacy text search.
  Stream<List<Transaction>> watchFireflyPayeeTagMatches(String search) {
    final text = search.trim();
    if (text.isEmpty) return Stream.value(const []);
    return (select(transactions)
          ..where((row) =>
              _fireflyTextMatch(text, includeLegacyFields: false) &
              (row.name.collate(Collate.noCase).like('%$text%') |
                      row.note.collate(Collate.noCase).like('%$text%'))
                  .not())
          ..orderBy([
            (row) => OrderingTerm.desc(row.dateCreated),
            (row) => OrderingTerm.asc(row.transactionPk),
          ]))
        .watch();
  }

  Expression<bool> _fireflyTextMatch(String text,
      {required bool includeLegacyFields}) {
    final pattern = '%$text%';
    final payeeMatch = selectOnly(payees)
      ..addColumns([payees.payeePk])
      ..where(payees.name.collate(Collate.noCase).like(pattern));
    final tagMatch = selectOnly(transactionTags).join([
      innerJoin(tags, tags.tagPk.equalsExp(transactionTags.tagFk),
          useColumns: false),
    ])
      ..addColumns([transactionTags.transactionFk])
      ..where(tags.name.collate(Collate.noCase).like(pattern));
    Expression<bool> match = transactions.payeeFk.isInQuery(payeeMatch) |
        transactions.transactionPk.isInQuery(tagMatch);
    if (includeLegacyFields) {
      match = match |
          transactions.name.collate(Collate.noCase).like(pattern) |
          transactions.note.collate(Collate.noCase).like(pattern);
    }
    return match;
  }

  Expression<bool> _fireflyFilterExpression(FireflySearchFilters filters) {
    Expression<bool> result = const Constant(true);
    final payeePk = filters.payeePk;
    if (payeePk != null) result &= transactions.payeeFk.equals(payeePk);
    final tagPks = filters.tagPks.toSet();
    if (tagPks.isNotEmpty) {
      final count = transactionTags.tagFk.count(distinct: true);
      final tagged = selectOnly(transactionTags)
        ..addColumns([transactionTags.transactionFk])
        ..where(transactionTags.tagFk.isIn(tagPks));
      if (filters.matchAllTags) {
        tagged.groupBy([transactionTags.transactionFk],
            having: count.equals(tagPks.length));
      }
      result &= transactions.transactionPk.isInQuery(tagged);
    }
    final billPk = filters.billPk;
    if (billPk != null) result &= transactions.billFk.equals(billPk);
    final reconciled = filters.reconciled;
    if (reconciled != null) {
      result &= transactions.reconciled.equals(reconciled);
    }
    final hasAttachment = filters.hasAttachment;
    if (hasAttachment != null) {
      final owners = selectOnly(attachments)
        ..addColumns([attachments.attachableFk])
        ..where(attachments.attachableType
                .equals(FireflyAttachment.transactionJournal) &
            attachments.uploadState.equals(fireflyAttachmentDeleted).not());
      final attached = transactions.transactionPk.isInQuery(owners) |
          (transactions.pairedTransactionFk.isNotNull() &
              transactions.pairedTransactionFk.isInQuery(owners));
      result &= hasAttachment ? attached : attached.not();
    }
    return result;
  }
}
