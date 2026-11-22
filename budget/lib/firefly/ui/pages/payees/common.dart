import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/syncClient.dart';

FinanceDatabase fireflyPayeesDb(FinanceDatabase? db) => db ?? database;

/// Tells the scheduler about a payee edit: the legacy watcher skips Payees.
typedef FireflyPayeeWriteNotifier = void Function();

void defaultFireflyPayeeWrite() => fireflyLocalWrite();

String fireflyPayeeKindKey(PayeeKind kind) => kind == PayeeKind.expense
    ? 'firefly-payees-kind-expense'
    : 'firefly-payees-kind-revenue';
