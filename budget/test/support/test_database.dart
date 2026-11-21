import 'package:budget/database/tables.dart';
import 'package:drift/native.dart';

FinanceDatabase inMemoryFinanceDatabase() => FinanceDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA foreign_keys = ON'),
      ),
    );
