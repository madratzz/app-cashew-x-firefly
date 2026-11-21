import 'package:budget/database/tables.dart';
import 'package:budget/struct/iconObjects.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const fireflyUncategorizedCategoryPk = 'firefly-uncategorized';

bool isFireflySyncableCategory(String pk) =>
    pk != '0' && pk != fireflyUncategorizedCategoryPk;

extension FireflyCategoryQueries on FinanceDatabase {
  Future<TransactionCategory?> fireflyCategory(String pk) =>
      (select(categories)..where((row) => row.categoryPk.equals(pk)))
          .getSingleOrNull();

  Future<List<TransactionCategory>> fireflySyncableCategories() =>
      (select(categories)
            ..where((row) => row.categoryPk
                .isNotIn(const ['0', fireflyUncategorizedCategoryPk]))
            ..orderBy([
              (row) => OrderingTerm.desc(row.mainCategoryPk.isNull()),
              (row) => OrderingTerm.asc(row.order),
              (row) => OrderingTerm.asc(row.categoryPk),
            ]))
          .get();

  Future<String> ensureUncategorizedCategory() async {
    const pk = fireflyUncategorizedCategoryPk;
    if (await fireflyCategory(pk) == null) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          categoryPk: const Value(pk),
          name: 'Uncategorized',
          iconName: const Value('image.png'),
          order: await _nextCategoryOrder(null),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
    return pk;
  }

  Future<TransactionCategory> writeFireflyCategory({
    required String name,
    required String? parentPk,
    required DateTime? modifiedAt,
    required DateTime createdAt,
    String? pk,
  }) async {
    final categoryPk = pk ?? const Uuid().v4();
    final existing = await fireflyCategory(categoryPk);
    final storedName = _categoryName(name);
    if (existing == null) {
      await into(categories).insert(CategoriesCompanion.insert(
        categoryPk: Value(categoryPk),
        name: storedName,
        mainCategoryPk: Value(parentPk),
        order: await _nextCategoryOrder(parentPk),
        iconName: Value(_categoryIcon(storedName)),
        dateCreated: Value(createdAt),
        dateTimeModified: Value(modifiedAt),
      ));
    } else {
      await (update(categories)
            ..where((row) => row.categoryPk.equals(categoryPk)))
          .write(CategoriesCompanion(
        name: Value(storedName),
        mainCategoryPk: Value(parentPk),
        dateTimeModified: Value(modifiedAt),
      ));
      if (existing.mainCategoryPk != parentPk) {
        final updateReferences = update(transactions)
          ..where((row) =>
              row.subCategoryFk.equals(categoryPk) |
              row.categoryFk.equals(categoryPk));
        await updateReferences.write(TransactionsCompanion(
          categoryFk: Value(parentPk ?? categoryPk),
          subCategoryFk: Value(parentPk == null ? null : categoryPk),
        ));
      }
    }
    return (await fireflyCategory(categoryPk))!;
  }

  Future<List<TransactionCategory>> fireflyCategoryChildren(String pk) =>
      (select(categories)..where((row) => row.mainCategoryPk.equals(pk))).get();

  Future<void> deleteFireflyCategory(String pk) async {
    final references = select(transactions)
      ..where((row) => row.categoryFk.equals(pk) | row.subCategoryFk.equals(pk))
      ..limit(1);
    if (await references.getSingleOrNull() != null) {
      final fallback = await ensureUncategorizedCategory();
      await (update(transactions)
            ..where((row) =>
                row.categoryFk.equals(pk) | row.subCategoryFk.equals(pk)))
          .write(TransactionsCompanion(
        categoryFk: Value(fallback),
        subCategoryFk: const Value(null),
      ));
    }
    await (delete(associatedTitles)..where((row) => row.categoryFk.equals(pk)))
        .go();
    await (delete(categoryBudgetLimits)
          ..where((row) => row.categoryFk.equals(pk)))
        .go();
    await (delete(scannerTemplates)
          ..where((row) => row.defaultCategoryFk.equals(pk)))
        .go();
    await (delete(categories)..where((row) => row.categoryPk.equals(pk))).go();
  }

  Future<int> _nextCategoryOrder(String? parentPk) async {
    final last = await (select(categories)
          ..where((row) => parentPk == null
              ? row.mainCategoryPk.isNull()
              : row.mainCategoryPk.equals(parentPk))
          ..orderBy([(row) => OrderingTerm.desc(row.order)])
          ..limit(1))
        .getSingleOrNull();
    return (last?.order ?? -1) + 1;
  }
}

String _categoryName(String name) {
  final trimmed = name.trim();
  return String.fromCharCodes(trimmed.runes.take(NAME_LIMIT)).trimRight();
}

String _categoryIcon(String name) {
  final normalized = name.toLowerCase();
  return (iconObjects
                  .where((icon) =>
                      icon.mostLikelyCategoryName?.toLowerCase() == normalized)
                  .firstOrNull ??
              iconObjects
                  .where((icon) => icon.tags.contains(normalized))
                  .firstOrNull)
          ?.icon ??
      'image.png';
}
