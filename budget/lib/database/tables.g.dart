// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tables.dart';

// ignore_for_file: type=lint
class $WalletsTable extends Wallets
    with TableInfo<$WalletsTable, TransactionWallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _walletPkMeta =
      const VerificationMeta('walletPk');
  @override
  late final GeneratedColumn<String> walletPk = GeneratedColumn<String>(
      'wallet_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
      'colour', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => new DateTime.now());
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencyFormatMeta =
      const VerificationMeta('currencyFormat');
  @override
  late final GeneratedColumn<String> currencyFormat = GeneratedColumn<String>(
      'currency_format', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decimalsMeta =
      const VerificationMeta('decimals');
  @override
  late final GeneratedColumn<int> decimals = GeneratedColumn<int>(
      'decimals', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(2));
  static const VerificationMeta _homePageWidgetDisplayMeta =
      const VerificationMeta('homePageWidgetDisplay');
  @override
  late final GeneratedColumnWithTypeConverter<List<HomePageWidgetDisplay>?,
      String> homePageWidgetDisplay = GeneratedColumn<String>(
          'home_page_widget_display', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(null))
      .withConverter<List<HomePageWidgetDisplay>?>(
          $WalletsTable.$converterhomePageWidgetDisplayn);
  static const VerificationMeta _accountKindMeta =
      const VerificationMeta('accountKind');
  @override
  late final GeneratedColumnWithTypeConverter<AccountKind, int> accountKind =
      GeneratedColumn<int>('account_kind', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<AccountKind>($WalletsTable.$converteraccountKind);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        walletPk,
        name,
        colour,
        iconName,
        dateCreated,
        dateTimeModified,
        order,
        currency,
        currencyFormat,
        decimals,
        homePageWidgetDisplay,
        accountKind,
        archived
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionWallet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('wallet_pk')) {
      context.handle(_walletPkMeta,
          walletPk.isAcceptableOrUnknown(data['wallet_pk']!, _walletPkMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('colour')) {
      context.handle(_colourMeta,
          colour.isAcceptableOrUnknown(data['colour']!, _colourMeta));
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('currency_format')) {
      context.handle(
          _currencyFormatMeta,
          currencyFormat.isAcceptableOrUnknown(
              data['currency_format']!, _currencyFormatMeta));
    }
    if (data.containsKey('decimals')) {
      context.handle(_decimalsMeta,
          decimals.isAcceptableOrUnknown(data['decimals']!, _decimalsMeta));
    }
    context.handle(
        _homePageWidgetDisplayMeta, const VerificationResult.success());
    context.handle(_accountKindMeta, const VerificationResult.success());
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {walletPk};
  @override
  TransactionWallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionWallet(
      walletPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wallet_pk'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colour: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}colour']),
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name']),
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency']),
      currencyFormat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_format']),
      decimals: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}decimals'])!,
      homePageWidgetDisplay: $WalletsTable.$converterhomePageWidgetDisplayn
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}home_page_widget_display'])),
      accountKind: $WalletsTable.$converteraccountKind.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_kind'])!),
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<HomePageWidgetDisplay>, String>
      $converterhomePageWidgetDisplay =
      const HomePageWidgetDisplayListInColumnConverter();
  static TypeConverter<List<HomePageWidgetDisplay>?, String?>
      $converterhomePageWidgetDisplayn =
      NullAwareTypeConverter.wrap($converterhomePageWidgetDisplay);
  static JsonTypeConverter2<AccountKind, int, int> $converteraccountKind =
      const EnumIndexConverter<AccountKind>(AccountKind.values);
}

class TransactionWallet extends DataClass
    implements Insertable<TransactionWallet> {
  final String walletPk;
  final String name;
  final String? colour;
  final String? iconName;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  final int order;
  final String? currency;
  final String? currencyFormat;
  final int decimals;
  final List<HomePageWidgetDisplay>? homePageWidgetDisplay;
  final AccountKind accountKind;
  final bool archived;
  const TransactionWallet(
      {required this.walletPk,
      required this.name,
      this.colour,
      this.iconName,
      required this.dateCreated,
      this.dateTimeModified,
      required this.order,
      this.currency,
      this.currencyFormat,
      required this.decimals,
      this.homePageWidgetDisplay,
      this.accountKind = AccountKind.asset,
      this.archived = false});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['wallet_pk'] = Variable<String>(walletPk);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colour != null) {
      map['colour'] = Variable<String>(colour);
    }
    if (!nullToAbsent || iconName != null) {
      map['icon_name'] = Variable<String>(iconName);
    }
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || currencyFormat != null) {
      map['currency_format'] = Variable<String>(currencyFormat);
    }
    map['decimals'] = Variable<int>(decimals);
    if (!nullToAbsent || homePageWidgetDisplay != null) {
      map['home_page_widget_display'] = Variable<String>($WalletsTable
          .$converterhomePageWidgetDisplayn
          .toSql(homePageWidgetDisplay));
    }
    {
      map['account_kind'] =
          Variable<int>($WalletsTable.$converteraccountKind.toSql(accountKind));
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      walletPk: Value(walletPk),
      name: Value(name),
      colour:
          colour == null && nullToAbsent ? const Value.absent() : Value(colour),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
      order: Value(order),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      currencyFormat: currencyFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyFormat),
      decimals: Value(decimals),
      homePageWidgetDisplay: homePageWidgetDisplay == null && nullToAbsent
          ? const Value.absent()
          : Value(homePageWidgetDisplay),
      accountKind: Value(accountKind),
      archived: Value(archived),
    );
  }

  factory TransactionWallet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionWallet(
      walletPk: serializer.fromJson<String>(json['walletPk']),
      name: serializer.fromJson<String>(json['name']),
      colour: serializer.fromJson<String?>(json['colour']),
      iconName: serializer.fromJson<String?>(json['iconName']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
      order: serializer.fromJson<int>(json['order']),
      currency: serializer.fromJson<String?>(json['currency']),
      currencyFormat: serializer.fromJson<String?>(json['currencyFormat']),
      decimals: serializer.fromJson<int>(json['decimals']),
      homePageWidgetDisplay: serializer.fromJson<List<HomePageWidgetDisplay>?>(
          json['homePageWidgetDisplay']),
      accountKind: json['accountKind'] == null
          ? AccountKind.asset
          : $WalletsTable.$converteraccountKind
              .fromJson(serializer.fromJson<int>(json['accountKind'])),
      archived: serializer.fromJson<bool?>(json['archived']) ?? false,
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'walletPk': serializer.toJson<String>(walletPk),
      'name': serializer.toJson<String>(name),
      'colour': serializer.toJson<String?>(colour),
      'iconName': serializer.toJson<String?>(iconName),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
      'order': serializer.toJson<int>(order),
      'currency': serializer.toJson<String?>(currency),
      'currencyFormat': serializer.toJson<String?>(currencyFormat),
      'decimals': serializer.toJson<int>(decimals),
      'homePageWidgetDisplay': serializer
          .toJson<List<HomePageWidgetDisplay>?>(homePageWidgetDisplay),
      'accountKind': serializer
          .toJson<int>($WalletsTable.$converteraccountKind.toJson(accountKind)),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  TransactionWallet copyWith(
          {String? walletPk,
          String? name,
          Value<String?> colour = const Value.absent(),
          Value<String?> iconName = const Value.absent(),
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent(),
          int? order,
          Value<String?> currency = const Value.absent(),
          Value<String?> currencyFormat = const Value.absent(),
          int? decimals,
          Value<List<HomePageWidgetDisplay>?> homePageWidgetDisplay =
              const Value.absent(),
          AccountKind? accountKind,
          bool? archived}) =>
      TransactionWallet(
        walletPk: walletPk ?? this.walletPk,
        name: name ?? this.name,
        colour: colour.present ? colour.value : this.colour,
        iconName: iconName.present ? iconName.value : this.iconName,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
        order: order ?? this.order,
        currency: currency.present ? currency.value : this.currency,
        currencyFormat:
            currencyFormat.present ? currencyFormat.value : this.currencyFormat,
        decimals: decimals ?? this.decimals,
        homePageWidgetDisplay: homePageWidgetDisplay.present
            ? homePageWidgetDisplay.value
            : this.homePageWidgetDisplay,
        accountKind: accountKind ?? this.accountKind,
        archived: archived ?? this.archived,
      );
  @override
  String toString() {
    return (StringBuffer('TransactionWallet(')
          ..write('walletPk: $walletPk, ')
          ..write('name: $name, ')
          ..write('colour: $colour, ')
          ..write('iconName: $iconName, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('order: $order, ')
          ..write('currency: $currency, ')
          ..write('currencyFormat: $currencyFormat, ')
          ..write('decimals: $decimals, ')
          ..write('homePageWidgetDisplay: $homePageWidgetDisplay, ')
          ..write('accountKind: $accountKind, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      walletPk,
      name,
      colour,
      iconName,
      dateCreated,
      dateTimeModified,
      order,
      currency,
      currencyFormat,
      decimals,
      homePageWidgetDisplay,
      accountKind,
      archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionWallet &&
          other.walletPk == this.walletPk &&
          other.name == this.name &&
          other.colour == this.colour &&
          other.iconName == this.iconName &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified &&
          other.order == this.order &&
          other.currency == this.currency &&
          other.currencyFormat == this.currencyFormat &&
          other.decimals == this.decimals &&
          other.homePageWidgetDisplay == this.homePageWidgetDisplay &&
          other.accountKind == this.accountKind &&
          other.archived == this.archived);
}

class WalletsCompanion extends UpdateCompanion<TransactionWallet> {
  final Value<String> walletPk;
  final Value<String> name;
  final Value<String?> colour;
  final Value<String?> iconName;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<int> order;
  final Value<String?> currency;
  final Value<String?> currencyFormat;
  final Value<int> decimals;
  final Value<List<HomePageWidgetDisplay>?> homePageWidgetDisplay;
  final Value<AccountKind> accountKind;
  final Value<bool> archived;
  final Value<int> rowid;
  const WalletsCompanion({
    this.walletPk = const Value.absent(),
    this.name = const Value.absent(),
    this.colour = const Value.absent(),
    this.iconName = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.order = const Value.absent(),
    this.currency = const Value.absent(),
    this.currencyFormat = const Value.absent(),
    this.decimals = const Value.absent(),
    this.homePageWidgetDisplay = const Value.absent(),
    this.accountKind = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletsCompanion.insert({
    this.walletPk = const Value.absent(),
    required String name,
    this.colour = const Value.absent(),
    this.iconName = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    required int order,
    this.currency = const Value.absent(),
    this.currencyFormat = const Value.absent(),
    this.decimals = const Value.absent(),
    this.homePageWidgetDisplay = const Value.absent(),
    this.accountKind = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        order = Value(order);
  static Insertable<TransactionWallet> custom({
    Expression<String>? walletPk,
    Expression<String>? name,
    Expression<String>? colour,
    Expression<String>? iconName,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? order,
    Expression<String>? currency,
    Expression<String>? currencyFormat,
    Expression<int>? decimals,
    Expression<String>? homePageWidgetDisplay,
    Expression<int>? accountKind,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (walletPk != null) 'wallet_pk': walletPk,
      if (name != null) 'name': name,
      if (colour != null) 'colour': colour,
      if (iconName != null) 'icon_name': iconName,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (order != null) 'order': order,
      if (currency != null) 'currency': currency,
      if (currencyFormat != null) 'currency_format': currencyFormat,
      if (decimals != null) 'decimals': decimals,
      if (homePageWidgetDisplay != null)
        'home_page_widget_display': homePageWidgetDisplay,
      if (accountKind != null) 'account_kind': accountKind,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletsCompanion copyWith(
      {Value<String>? walletPk,
      Value<String>? name,
      Value<String?>? colour,
      Value<String?>? iconName,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<int>? order,
      Value<String?>? currency,
      Value<String?>? currencyFormat,
      Value<int>? decimals,
      Value<List<HomePageWidgetDisplay>?>? homePageWidgetDisplay,
      Value<AccountKind>? accountKind,
      Value<bool>? archived,
      Value<int>? rowid}) {
    return WalletsCompanion(
      walletPk: walletPk ?? this.walletPk,
      name: name ?? this.name,
      colour: colour ?? this.colour,
      iconName: iconName ?? this.iconName,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      order: order ?? this.order,
      currency: currency ?? this.currency,
      currencyFormat: currencyFormat ?? this.currencyFormat,
      decimals: decimals ?? this.decimals,
      homePageWidgetDisplay:
          homePageWidgetDisplay ?? this.homePageWidgetDisplay,
      accountKind: accountKind ?? this.accountKind,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (walletPk.present) {
      map['wallet_pk'] = Variable<String>(walletPk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (currencyFormat.present) {
      map['currency_format'] = Variable<String>(currencyFormat.value);
    }
    if (decimals.present) {
      map['decimals'] = Variable<int>(decimals.value);
    }
    if (homePageWidgetDisplay.present) {
      map['home_page_widget_display'] = Variable<String>($WalletsTable
          .$converterhomePageWidgetDisplayn
          .toSql(homePageWidgetDisplay.value));
    }
    if (accountKind.present) {
      map['account_kind'] = Variable<int>(
          $WalletsTable.$converteraccountKind.toSql(accountKind.value));
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('walletPk: $walletPk, ')
          ..write('name: $name, ')
          ..write('colour: $colour, ')
          ..write('iconName: $iconName, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('order: $order, ')
          ..write('currency: $currency, ')
          ..write('currencyFormat: $currencyFormat, ')
          ..write('decimals: $decimals, ')
          ..write('homePageWidgetDisplay: $homePageWidgetDisplay, ')
          ..write('accountKind: $accountKind, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, TransactionCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryPkMeta =
      const VerificationMeta('categoryPk');
  @override
  late final GeneratedColumn<String> categoryPk = GeneratedColumn<String>(
      'category_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
      'colour', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emojiIconNameMeta =
      const VerificationMeta('emojiIconName');
  @override
  late final GeneratedColumn<String> emojiIconName = GeneratedColumn<String>(
      'emoji_icon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => new DateTime.now());
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _incomeMeta = const VerificationMeta('income');
  @override
  late final GeneratedColumn<bool> income = GeneratedColumn<bool>(
      'income', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("income" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _methodAddedMeta =
      const VerificationMeta('methodAdded');
  @override
  late final GeneratedColumnWithTypeConverter<MethodAdded?, int> methodAdded =
      GeneratedColumn<int>('method_added', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<MethodAdded?>($CategoriesTable.$convertermethodAddedn);
  static const VerificationMeta _mainCategoryPkMeta =
      const VerificationMeta('mainCategoryPk');
  @override
  late final GeneratedColumn<String> mainCategoryPk = GeneratedColumn<String>(
      'main_category_pk', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (category_pk)'),
      defaultValue: const Constant(null));
  @override
  List<GeneratedColumn> get $columns => [
        categoryPk,
        name,
        colour,
        iconName,
        emojiIconName,
        dateCreated,
        dateTimeModified,
        order,
        income,
        methodAdded,
        mainCategoryPk
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransactionCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_pk')) {
      context.handle(
          _categoryPkMeta,
          categoryPk.isAcceptableOrUnknown(
              data['category_pk']!, _categoryPkMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('colour')) {
      context.handle(_colourMeta,
          colour.isAcceptableOrUnknown(data['colour']!, _colourMeta));
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    if (data.containsKey('emoji_icon_name')) {
      context.handle(
          _emojiIconNameMeta,
          emojiIconName.isAcceptableOrUnknown(
              data['emoji_icon_name']!, _emojiIconNameMeta));
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('income')) {
      context.handle(_incomeMeta,
          income.isAcceptableOrUnknown(data['income']!, _incomeMeta));
    }
    context.handle(_methodAddedMeta, const VerificationResult.success());
    if (data.containsKey('main_category_pk')) {
      context.handle(
          _mainCategoryPkMeta,
          mainCategoryPk.isAcceptableOrUnknown(
              data['main_category_pk']!, _mainCategoryPkMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {categoryPk};
  @override
  TransactionCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionCategory(
      categoryPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_pk'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colour: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}colour']),
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name']),
      emojiIconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji_icon_name']),
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      income: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}income'])!,
      methodAdded: $CategoriesTable.$convertermethodAddedn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}method_added'])),
      mainCategoryPk: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}main_category_pk']),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MethodAdded, int, int> $convertermethodAdded =
      const EnumIndexConverter<MethodAdded>(MethodAdded.values);
  static JsonTypeConverter2<MethodAdded?, int?, int?> $convertermethodAddedn =
      JsonTypeConverter2.asNullable($convertermethodAdded);
}

class TransactionCategory extends DataClass
    implements Insertable<TransactionCategory> {
  final String categoryPk;
  final String name;
  final String? colour;
  final String? iconName;
  final String? emojiIconName;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  final int order;
  final bool income;
  final MethodAdded? methodAdded;
  final String? mainCategoryPk;
  const TransactionCategory(
      {required this.categoryPk,
      required this.name,
      this.colour,
      this.iconName,
      this.emojiIconName,
      required this.dateCreated,
      this.dateTimeModified,
      required this.order,
      required this.income,
      this.methodAdded,
      this.mainCategoryPk});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_pk'] = Variable<String>(categoryPk);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colour != null) {
      map['colour'] = Variable<String>(colour);
    }
    if (!nullToAbsent || iconName != null) {
      map['icon_name'] = Variable<String>(iconName);
    }
    if (!nullToAbsent || emojiIconName != null) {
      map['emoji_icon_name'] = Variable<String>(emojiIconName);
    }
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    map['order'] = Variable<int>(order);
    map['income'] = Variable<bool>(income);
    if (!nullToAbsent || methodAdded != null) {
      map['method_added'] = Variable<int>(
          $CategoriesTable.$convertermethodAddedn.toSql(methodAdded));
    }
    if (!nullToAbsent || mainCategoryPk != null) {
      map['main_category_pk'] = Variable<String>(mainCategoryPk);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      categoryPk: Value(categoryPk),
      name: Value(name),
      colour:
          colour == null && nullToAbsent ? const Value.absent() : Value(colour),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
      emojiIconName: emojiIconName == null && nullToAbsent
          ? const Value.absent()
          : Value(emojiIconName),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
      order: Value(order),
      income: Value(income),
      methodAdded: methodAdded == null && nullToAbsent
          ? const Value.absent()
          : Value(methodAdded),
      mainCategoryPk: mainCategoryPk == null && nullToAbsent
          ? const Value.absent()
          : Value(mainCategoryPk),
    );
  }

  factory TransactionCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionCategory(
      categoryPk: serializer.fromJson<String>(json['categoryPk']),
      name: serializer.fromJson<String>(json['name']),
      colour: serializer.fromJson<String?>(json['colour']),
      iconName: serializer.fromJson<String?>(json['iconName']),
      emojiIconName: serializer.fromJson<String?>(json['emojiIconName']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
      order: serializer.fromJson<int>(json['order']),
      income: serializer.fromJson<bool>(json['income']),
      methodAdded: $CategoriesTable.$convertermethodAddedn
          .fromJson(serializer.fromJson<int?>(json['methodAdded'])),
      mainCategoryPk: serializer.fromJson<String?>(json['mainCategoryPk']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryPk': serializer.toJson<String>(categoryPk),
      'name': serializer.toJson<String>(name),
      'colour': serializer.toJson<String?>(colour),
      'iconName': serializer.toJson<String?>(iconName),
      'emojiIconName': serializer.toJson<String?>(emojiIconName),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
      'order': serializer.toJson<int>(order),
      'income': serializer.toJson<bool>(income),
      'methodAdded': serializer.toJson<int?>(
          $CategoriesTable.$convertermethodAddedn.toJson(methodAdded)),
      'mainCategoryPk': serializer.toJson<String?>(mainCategoryPk),
    };
  }

  TransactionCategory copyWith(
          {String? categoryPk,
          String? name,
          Value<String?> colour = const Value.absent(),
          Value<String?> iconName = const Value.absent(),
          Value<String?> emojiIconName = const Value.absent(),
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent(),
          int? order,
          bool? income,
          Value<MethodAdded?> methodAdded = const Value.absent(),
          Value<String?> mainCategoryPk = const Value.absent()}) =>
      TransactionCategory(
        categoryPk: categoryPk ?? this.categoryPk,
        name: name ?? this.name,
        colour: colour.present ? colour.value : this.colour,
        iconName: iconName.present ? iconName.value : this.iconName,
        emojiIconName:
            emojiIconName.present ? emojiIconName.value : this.emojiIconName,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
        order: order ?? this.order,
        income: income ?? this.income,
        methodAdded: methodAdded.present ? methodAdded.value : this.methodAdded,
        mainCategoryPk:
            mainCategoryPk.present ? mainCategoryPk.value : this.mainCategoryPk,
      );
  @override
  String toString() {
    return (StringBuffer('TransactionCategory(')
          ..write('categoryPk: $categoryPk, ')
          ..write('name: $name, ')
          ..write('colour: $colour, ')
          ..write('iconName: $iconName, ')
          ..write('emojiIconName: $emojiIconName, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('order: $order, ')
          ..write('income: $income, ')
          ..write('methodAdded: $methodAdded, ')
          ..write('mainCategoryPk: $mainCategoryPk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      categoryPk,
      name,
      colour,
      iconName,
      emojiIconName,
      dateCreated,
      dateTimeModified,
      order,
      income,
      methodAdded,
      mainCategoryPk);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionCategory &&
          other.categoryPk == this.categoryPk &&
          other.name == this.name &&
          other.colour == this.colour &&
          other.iconName == this.iconName &&
          other.emojiIconName == this.emojiIconName &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified &&
          other.order == this.order &&
          other.income == this.income &&
          other.methodAdded == this.methodAdded &&
          other.mainCategoryPk == this.mainCategoryPk);
}

class CategoriesCompanion extends UpdateCompanion<TransactionCategory> {
  final Value<String> categoryPk;
  final Value<String> name;
  final Value<String?> colour;
  final Value<String?> iconName;
  final Value<String?> emojiIconName;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<int> order;
  final Value<bool> income;
  final Value<MethodAdded?> methodAdded;
  final Value<String?> mainCategoryPk;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.categoryPk = const Value.absent(),
    this.name = const Value.absent(),
    this.colour = const Value.absent(),
    this.iconName = const Value.absent(),
    this.emojiIconName = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.order = const Value.absent(),
    this.income = const Value.absent(),
    this.methodAdded = const Value.absent(),
    this.mainCategoryPk = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.categoryPk = const Value.absent(),
    required String name,
    this.colour = const Value.absent(),
    this.iconName = const Value.absent(),
    this.emojiIconName = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    required int order,
    this.income = const Value.absent(),
    this.methodAdded = const Value.absent(),
    this.mainCategoryPk = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        order = Value(order);
  static Insertable<TransactionCategory> custom({
    Expression<String>? categoryPk,
    Expression<String>? name,
    Expression<String>? colour,
    Expression<String>? iconName,
    Expression<String>? emojiIconName,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? order,
    Expression<bool>? income,
    Expression<int>? methodAdded,
    Expression<String>? mainCategoryPk,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryPk != null) 'category_pk': categoryPk,
      if (name != null) 'name': name,
      if (colour != null) 'colour': colour,
      if (iconName != null) 'icon_name': iconName,
      if (emojiIconName != null) 'emoji_icon_name': emojiIconName,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (order != null) 'order': order,
      if (income != null) 'income': income,
      if (methodAdded != null) 'method_added': methodAdded,
      if (mainCategoryPk != null) 'main_category_pk': mainCategoryPk,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? categoryPk,
      Value<String>? name,
      Value<String?>? colour,
      Value<String?>? iconName,
      Value<String?>? emojiIconName,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<int>? order,
      Value<bool>? income,
      Value<MethodAdded?>? methodAdded,
      Value<String?>? mainCategoryPk,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      categoryPk: categoryPk ?? this.categoryPk,
      name: name ?? this.name,
      colour: colour ?? this.colour,
      iconName: iconName ?? this.iconName,
      emojiIconName: emojiIconName ?? this.emojiIconName,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      order: order ?? this.order,
      income: income ?? this.income,
      methodAdded: methodAdded ?? this.methodAdded,
      mainCategoryPk: mainCategoryPk ?? this.mainCategoryPk,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryPk.present) {
      map['category_pk'] = Variable<String>(categoryPk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (emojiIconName.present) {
      map['emoji_icon_name'] = Variable<String>(emojiIconName.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (income.present) {
      map['income'] = Variable<bool>(income.value);
    }
    if (methodAdded.present) {
      map['method_added'] = Variable<int>(
          $CategoriesTable.$convertermethodAddedn.toSql(methodAdded.value));
    }
    if (mainCategoryPk.present) {
      map['main_category_pk'] = Variable<String>(mainCategoryPk.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('categoryPk: $categoryPk, ')
          ..write('name: $name, ')
          ..write('colour: $colour, ')
          ..write('iconName: $iconName, ')
          ..write('emojiIconName: $emojiIconName, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('order: $order, ')
          ..write('income: $income, ')
          ..write('methodAdded: $methodAdded, ')
          ..write('mainCategoryPk: $mainCategoryPk, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ObjectivesTable extends Objectives
    with TableInfo<$ObjectivesTable, Objective> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObjectivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _objectivePkMeta =
      const VerificationMeta('objectivePk');
  @override
  late final GeneratedColumn<String> objectivePk = GeneratedColumn<String>(
      'objective_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<ObjectiveType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: Constant(0))
          .withConverter<ObjectiveType>($ObjectivesTable.$convertertype);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
      'colour', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => new DateTime.now());
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emojiIconNameMeta =
      const VerificationMeta('emojiIconName');
  @override
  late final GeneratedColumn<String> emojiIconName = GeneratedColumn<String>(
      'emoji_icon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _incomeMeta = const VerificationMeta('income');
  @override
  late final GeneratedColumn<bool> income = GeneratedColumn<bool>(
      'income', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("income" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _walletFkMeta =
      const VerificationMeta('walletFk');
  @override
  late final GeneratedColumn<String> walletFk = GeneratedColumn<String>(
      'wallet_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (wallet_pk)'),
      defaultValue: const Constant("0"));
  @override
  List<GeneratedColumn> get $columns => [
        objectivePk,
        type,
        name,
        amount,
        order,
        colour,
        dateCreated,
        endDate,
        dateTimeModified,
        iconName,
        emojiIconName,
        income,
        pinned,
        archived,
        walletFk
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'objectives';
  @override
  VerificationContext validateIntegrity(Insertable<Objective> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('objective_pk')) {
      context.handle(
          _objectivePkMeta,
          objectivePk.isAcceptableOrUnknown(
              data['objective_pk']!, _objectivePkMeta));
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('colour')) {
      context.handle(_colourMeta,
          colour.isAcceptableOrUnknown(data['colour']!, _colourMeta));
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    if (data.containsKey('emoji_icon_name')) {
      context.handle(
          _emojiIconNameMeta,
          emojiIconName.isAcceptableOrUnknown(
              data['emoji_icon_name']!, _emojiIconNameMeta));
    }
    if (data.containsKey('income')) {
      context.handle(_incomeMeta,
          income.isAcceptableOrUnknown(data['income']!, _incomeMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('wallet_fk')) {
      context.handle(_walletFkMeta,
          walletFk.isAcceptableOrUnknown(data['wallet_fk']!, _walletFkMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {objectivePk};
  @override
  Objective map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Objective(
      objectivePk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}objective_pk'])!,
      type: $ObjectivesTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      colour: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}colour']),
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name']),
      emojiIconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji_icon_name']),
      income: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}income'])!,
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      walletFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wallet_fk'])!,
    );
  }

  @override
  $ObjectivesTable createAlias(String alias) {
    return $ObjectivesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ObjectiveType, int, int> $convertertype =
      const EnumIndexConverter<ObjectiveType>(ObjectiveType.values);
}

class Objective extends DataClass implements Insertable<Objective> {
  final String objectivePk;
  final ObjectiveType type;
  final String name;
  final double amount;
  final int order;
  final String? colour;
  final DateTime dateCreated;
  final DateTime? endDate;
  final DateTime? dateTimeModified;
  final String? iconName;
  final String? emojiIconName;
  final bool income;
  final bool pinned;
  final bool archived;
  final String walletFk;
  const Objective(
      {required this.objectivePk,
      required this.type,
      required this.name,
      required this.amount,
      required this.order,
      this.colour,
      required this.dateCreated,
      this.endDate,
      this.dateTimeModified,
      this.iconName,
      this.emojiIconName,
      required this.income,
      required this.pinned,
      required this.archived,
      required this.walletFk});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['objective_pk'] = Variable<String>(objectivePk);
    {
      map['type'] = Variable<int>($ObjectivesTable.$convertertype.toSql(type));
    }
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || colour != null) {
      map['colour'] = Variable<String>(colour);
    }
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    if (!nullToAbsent || iconName != null) {
      map['icon_name'] = Variable<String>(iconName);
    }
    if (!nullToAbsent || emojiIconName != null) {
      map['emoji_icon_name'] = Variable<String>(emojiIconName);
    }
    map['income'] = Variable<bool>(income);
    map['pinned'] = Variable<bool>(pinned);
    map['archived'] = Variable<bool>(archived);
    map['wallet_fk'] = Variable<String>(walletFk);
    return map;
  }

  ObjectivesCompanion toCompanion(bool nullToAbsent) {
    return ObjectivesCompanion(
      objectivePk: Value(objectivePk),
      type: Value(type),
      name: Value(name),
      amount: Value(amount),
      order: Value(order),
      colour:
          colour == null && nullToAbsent ? const Value.absent() : Value(colour),
      dateCreated: Value(dateCreated),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
      emojiIconName: emojiIconName == null && nullToAbsent
          ? const Value.absent()
          : Value(emojiIconName),
      income: Value(income),
      pinned: Value(pinned),
      archived: Value(archived),
      walletFk: Value(walletFk),
    );
  }

  factory Objective.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Objective(
      objectivePk: serializer.fromJson<String>(json['objectivePk']),
      type: $ObjectivesTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      order: serializer.fromJson<int>(json['order']),
      colour: serializer.fromJson<String?>(json['colour']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
      iconName: serializer.fromJson<String?>(json['iconName']),
      emojiIconName: serializer.fromJson<String?>(json['emojiIconName']),
      income: serializer.fromJson<bool>(json['income']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      archived: serializer.fromJson<bool>(json['archived']),
      walletFk: serializer.fromJson<String>(json['walletFk']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'objectivePk': serializer.toJson<String>(objectivePk),
      'type':
          serializer.toJson<int>($ObjectivesTable.$convertertype.toJson(type)),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'order': serializer.toJson<int>(order),
      'colour': serializer.toJson<String?>(colour),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
      'iconName': serializer.toJson<String?>(iconName),
      'emojiIconName': serializer.toJson<String?>(emojiIconName),
      'income': serializer.toJson<bool>(income),
      'pinned': serializer.toJson<bool>(pinned),
      'archived': serializer.toJson<bool>(archived),
      'walletFk': serializer.toJson<String>(walletFk),
    };
  }

  Objective copyWith(
          {String? objectivePk,
          ObjectiveType? type,
          String? name,
          double? amount,
          int? order,
          Value<String?> colour = const Value.absent(),
          DateTime? dateCreated,
          Value<DateTime?> endDate = const Value.absent(),
          Value<DateTime?> dateTimeModified = const Value.absent(),
          Value<String?> iconName = const Value.absent(),
          Value<String?> emojiIconName = const Value.absent(),
          bool? income,
          bool? pinned,
          bool? archived,
          String? walletFk}) =>
      Objective(
        objectivePk: objectivePk ?? this.objectivePk,
        type: type ?? this.type,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        order: order ?? this.order,
        colour: colour.present ? colour.value : this.colour,
        dateCreated: dateCreated ?? this.dateCreated,
        endDate: endDate.present ? endDate.value : this.endDate,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
        iconName: iconName.present ? iconName.value : this.iconName,
        emojiIconName:
            emojiIconName.present ? emojiIconName.value : this.emojiIconName,
        income: income ?? this.income,
        pinned: pinned ?? this.pinned,
        archived: archived ?? this.archived,
        walletFk: walletFk ?? this.walletFk,
      );
  @override
  String toString() {
    return (StringBuffer('Objective(')
          ..write('objectivePk: $objectivePk, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('order: $order, ')
          ..write('colour: $colour, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('endDate: $endDate, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('iconName: $iconName, ')
          ..write('emojiIconName: $emojiIconName, ')
          ..write('income: $income, ')
          ..write('pinned: $pinned, ')
          ..write('archived: $archived, ')
          ..write('walletFk: $walletFk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      objectivePk,
      type,
      name,
      amount,
      order,
      colour,
      dateCreated,
      endDate,
      dateTimeModified,
      iconName,
      emojiIconName,
      income,
      pinned,
      archived,
      walletFk);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Objective &&
          other.objectivePk == this.objectivePk &&
          other.type == this.type &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.order == this.order &&
          other.colour == this.colour &&
          other.dateCreated == this.dateCreated &&
          other.endDate == this.endDate &&
          other.dateTimeModified == this.dateTimeModified &&
          other.iconName == this.iconName &&
          other.emojiIconName == this.emojiIconName &&
          other.income == this.income &&
          other.pinned == this.pinned &&
          other.archived == this.archived &&
          other.walletFk == this.walletFk);
}

class ObjectivesCompanion extends UpdateCompanion<Objective> {
  final Value<String> objectivePk;
  final Value<ObjectiveType> type;
  final Value<String> name;
  final Value<double> amount;
  final Value<int> order;
  final Value<String?> colour;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> endDate;
  final Value<DateTime?> dateTimeModified;
  final Value<String?> iconName;
  final Value<String?> emojiIconName;
  final Value<bool> income;
  final Value<bool> pinned;
  final Value<bool> archived;
  final Value<String> walletFk;
  final Value<int> rowid;
  const ObjectivesCompanion({
    this.objectivePk = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.order = const Value.absent(),
    this.colour = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.endDate = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.iconName = const Value.absent(),
    this.emojiIconName = const Value.absent(),
    this.income = const Value.absent(),
    this.pinned = const Value.absent(),
    this.archived = const Value.absent(),
    this.walletFk = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObjectivesCompanion.insert({
    this.objectivePk = const Value.absent(),
    this.type = const Value.absent(),
    required String name,
    required double amount,
    required int order,
    this.colour = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.endDate = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.iconName = const Value.absent(),
    this.emojiIconName = const Value.absent(),
    this.income = const Value.absent(),
    this.pinned = const Value.absent(),
    this.archived = const Value.absent(),
    this.walletFk = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        amount = Value(amount),
        order = Value(order);
  static Insertable<Objective> custom({
    Expression<String>? objectivePk,
    Expression<int>? type,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<int>? order,
    Expression<String>? colour,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? endDate,
    Expression<DateTime>? dateTimeModified,
    Expression<String>? iconName,
    Expression<String>? emojiIconName,
    Expression<bool>? income,
    Expression<bool>? pinned,
    Expression<bool>? archived,
    Expression<String>? walletFk,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (objectivePk != null) 'objective_pk': objectivePk,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (order != null) 'order': order,
      if (colour != null) 'colour': colour,
      if (dateCreated != null) 'date_created': dateCreated,
      if (endDate != null) 'end_date': endDate,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (iconName != null) 'icon_name': iconName,
      if (emojiIconName != null) 'emoji_icon_name': emojiIconName,
      if (income != null) 'income': income,
      if (pinned != null) 'pinned': pinned,
      if (archived != null) 'archived': archived,
      if (walletFk != null) 'wallet_fk': walletFk,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObjectivesCompanion copyWith(
      {Value<String>? objectivePk,
      Value<ObjectiveType>? type,
      Value<String>? name,
      Value<double>? amount,
      Value<int>? order,
      Value<String?>? colour,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? endDate,
      Value<DateTime?>? dateTimeModified,
      Value<String?>? iconName,
      Value<String?>? emojiIconName,
      Value<bool>? income,
      Value<bool>? pinned,
      Value<bool>? archived,
      Value<String>? walletFk,
      Value<int>? rowid}) {
    return ObjectivesCompanion(
      objectivePk: objectivePk ?? this.objectivePk,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      order: order ?? this.order,
      colour: colour ?? this.colour,
      dateCreated: dateCreated ?? this.dateCreated,
      endDate: endDate ?? this.endDate,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      iconName: iconName ?? this.iconName,
      emojiIconName: emojiIconName ?? this.emojiIconName,
      income: income ?? this.income,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      walletFk: walletFk ?? this.walletFk,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (objectivePk.present) {
      map['objective_pk'] = Variable<String>(objectivePk.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($ObjectivesTable.$convertertype.toSql(type.value));
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (emojiIconName.present) {
      map['emoji_icon_name'] = Variable<String>(emojiIconName.value);
    }
    if (income.present) {
      map['income'] = Variable<bool>(income.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (walletFk.present) {
      map['wallet_fk'] = Variable<String>(walletFk.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObjectivesCompanion(')
          ..write('objectivePk: $objectivePk, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('order: $order, ')
          ..write('colour: $colour, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('endDate: $endDate, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('iconName: $iconName, ')
          ..write('emojiIconName: $emojiIconName, ')
          ..write('income: $income, ')
          ..write('pinned: $pinned, ')
          ..write('archived: $archived, ')
          ..write('walletFk: $walletFk, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PayeesTable extends Payees with TableInfo<$PayeesTable, Payee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _payeePkMeta =
      const VerificationMeta('payeePk');
  @override
  late final GeneratedColumn<String> payeePk = GeneratedColumn<String>(
      'payee_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumnWithTypeConverter<PayeeKind, int> kind =
      GeneratedColumn<int>('kind', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<PayeeKind>($PayeesTable.$converterkind);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ibanMeta = const VerificationMeta('iban');
  @override
  late final GeneratedColumn<String> iban = GeneratedColumn<String>(
      'iban', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: DateTime.now);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [payeePk, name, kind, active, notes, iban, dateCreated, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payees';
  @override
  VerificationContext validateIntegrity(Insertable<Payee> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('payee_pk')) {
      context.handle(_payeePkMeta,
          payeePk.isAcceptableOrUnknown(data['payee_pk']!, _payeePkMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    context.handle(_kindMeta, const VerificationResult.success());
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('iban')) {
      context.handle(
          _ibanMeta, iban.isAcceptableOrUnknown(data['iban']!, _ibanMeta));
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {payeePk};
  @override
  Payee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payee(
      payeePk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payee_pk'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: $PayeesTable.$converterkind.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kind'])!),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      iban: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}iban']),
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
    );
  }

  @override
  $PayeesTable createAlias(String alias) {
    return $PayeesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PayeeKind, int, int> $converterkind =
      const EnumIndexConverter<PayeeKind>(PayeeKind.values);
}

class Payee extends DataClass implements Insertable<Payee> {
  final String payeePk;
  final String name;
  final PayeeKind kind;
  final bool active;
  final String? notes;
  final String? iban;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  const Payee(
      {required this.payeePk,
      required this.name,
      required this.kind,
      required this.active,
      this.notes,
      this.iban,
      required this.dateCreated,
      this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['payee_pk'] = Variable<String>(payeePk);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<int>($PayeesTable.$converterkind.toSql(kind));
    }
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || iban != null) {
      map['iban'] = Variable<String>(iban);
    }
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    return map;
  }

  PayeesCompanion toCompanion(bool nullToAbsent) {
    return PayeesCompanion(
      payeePk: Value(payeePk),
      name: Value(name),
      kind: Value(kind),
      active: Value(active),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      iban: iban == null && nullToAbsent ? const Value.absent() : Value(iban),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
    );
  }

  factory Payee.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payee(
      payeePk: serializer.fromJson<String>(json['payeePk']),
      name: serializer.fromJson<String>(json['name']),
      kind: $PayeesTable.$converterkind
          .fromJson(serializer.fromJson<int>(json['kind'])),
      active: serializer.fromJson<bool>(json['active']),
      notes: serializer.fromJson<String?>(json['notes']),
      iban: serializer.fromJson<String?>(json['iban']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'payeePk': serializer.toJson<String>(payeePk),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<int>($PayeesTable.$converterkind.toJson(kind)),
      'active': serializer.toJson<bool>(active),
      'notes': serializer.toJson<String?>(notes),
      'iban': serializer.toJson<String?>(iban),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
    };
  }

  Payee copyWith(
          {String? payeePk,
          String? name,
          PayeeKind? kind,
          bool? active,
          Value<String?> notes = const Value.absent(),
          Value<String?> iban = const Value.absent(),
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent()}) =>
      Payee(
        payeePk: payeePk ?? this.payeePk,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        active: active ?? this.active,
        notes: notes.present ? notes.value : this.notes,
        iban: iban.present ? iban.value : this.iban,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('Payee(')
          ..write('payeePk: $payeePk, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('active: $active, ')
          ..write('notes: $notes, ')
          ..write('iban: $iban, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      payeePk, name, kind, active, notes, iban, dateCreated, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payee &&
          other.payeePk == this.payeePk &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.active == this.active &&
          other.notes == this.notes &&
          other.iban == this.iban &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified);
}

class PayeesCompanion extends UpdateCompanion<Payee> {
  final Value<String> payeePk;
  final Value<String> name;
  final Value<PayeeKind> kind;
  final Value<bool> active;
  final Value<String?> notes;
  final Value<String?> iban;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<int> rowid;
  const PayeesCompanion({
    this.payeePk = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.active = const Value.absent(),
    this.notes = const Value.absent(),
    this.iban = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PayeesCompanion.insert({
    this.payeePk = const Value.absent(),
    required String name,
    required PayeeKind kind,
    this.active = const Value.absent(),
    this.notes = const Value.absent(),
    this.iban = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        kind = Value(kind);
  static Insertable<Payee> custom({
    Expression<String>? payeePk,
    Expression<String>? name,
    Expression<int>? kind,
    Expression<bool>? active,
    Expression<String>? notes,
    Expression<String>? iban,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (payeePk != null) 'payee_pk': payeePk,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (active != null) 'active': active,
      if (notes != null) 'notes': notes,
      if (iban != null) 'iban': iban,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PayeesCompanion copyWith(
      {Value<String>? payeePk,
      Value<String>? name,
      Value<PayeeKind>? kind,
      Value<bool>? active,
      Value<String?>? notes,
      Value<String?>? iban,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<int>? rowid}) {
    return PayeesCompanion(
      payeePk: payeePk ?? this.payeePk,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      iban: iban ?? this.iban,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (payeePk.present) {
      map['payee_pk'] = Variable<String>(payeePk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<int>($PayeesTable.$converterkind.toSql(kind.value));
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (iban.present) {
      map['iban'] = Variable<String>(iban.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayeesCompanion(')
          ..write('payeePk: $payeePk, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('active: $active, ')
          ..write('notes: $notes, ')
          ..write('iban: $iban, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionGroupsTable extends TransactionGroups
    with TableInfo<$TransactionGroupsTable, TransactionGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupPkMeta =
      const VerificationMeta('groupPk');
  @override
  late final GeneratedColumn<String> groupPk = GeneratedColumn<String>(
      'group_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [groupPk, title, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_groups';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_pk')) {
      context.handle(_groupPkMeta,
          groupPk.isAcceptableOrUnknown(data['group_pk']!, _groupPkMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupPk};
  @override
  TransactionGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionGroup(
      groupPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_pk'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
    );
  }

  @override
  $TransactionGroupsTable createAlias(String alias) {
    return $TransactionGroupsTable(attachedDatabase, alias);
  }
}

class TransactionGroup extends DataClass
    implements Insertable<TransactionGroup> {
  final String groupPk;
  final String? title;
  final DateTime? dateTimeModified;
  const TransactionGroup(
      {required this.groupPk, this.title, this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_pk'] = Variable<String>(groupPk);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    return map;
  }

  TransactionGroupsCompanion toCompanion(bool nullToAbsent) {
    return TransactionGroupsCompanion(
      groupPk: Value(groupPk),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
    );
  }

  factory TransactionGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionGroup(
      groupPk: serializer.fromJson<String>(json['groupPk']),
      title: serializer.fromJson<String?>(json['title']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupPk': serializer.toJson<String>(groupPk),
      'title': serializer.toJson<String?>(title),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
    };
  }

  TransactionGroup copyWith(
          {String? groupPk,
          Value<String?> title = const Value.absent(),
          Value<DateTime?> dateTimeModified = const Value.absent()}) =>
      TransactionGroup(
        groupPk: groupPk ?? this.groupPk,
        title: title.present ? title.value : this.title,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('TransactionGroup(')
          ..write('groupPk: $groupPk, ')
          ..write('title: $title, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupPk, title, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionGroup &&
          other.groupPk == this.groupPk &&
          other.title == this.title &&
          other.dateTimeModified == this.dateTimeModified);
}

class TransactionGroupsCompanion extends UpdateCompanion<TransactionGroup> {
  final Value<String> groupPk;
  final Value<String?> title;
  final Value<DateTime?> dateTimeModified;
  final Value<int> rowid;
  const TransactionGroupsCompanion({
    this.groupPk = const Value.absent(),
    this.title = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionGroupsCompanion.insert({
    this.groupPk = const Value.absent(),
    this.title = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<TransactionGroup> custom({
    Expression<String>? groupPk,
    Expression<String>? title,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupPk != null) 'group_pk': groupPk,
      if (title != null) 'title': title,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionGroupsCompanion copyWith(
      {Value<String>? groupPk,
      Value<String?>? title,
      Value<DateTime?>? dateTimeModified,
      Value<int>? rowid}) {
    return TransactionGroupsCompanion(
      groupPk: groupPk ?? this.groupPk,
      title: title ?? this.title,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupPk.present) {
      map['group_pk'] = Variable<String>(groupPk.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionGroupsCompanion(')
          ..write('groupPk: $groupPk, ')
          ..write('title: $title, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionPkMeta =
      const VerificationMeta('transactionPk');
  @override
  late final GeneratedColumn<String> transactionPk = GeneratedColumn<String>(
      'transaction_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _pairedTransactionFkMeta =
      const VerificationMeta('pairedTransactionFk');
  @override
  late final GeneratedColumn<String> pairedTransactionFk =
      GeneratedColumn<String>('paired_transaction_fk', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES transactions (transaction_pk)'),
          defaultValue: const Constant(null));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryFkMeta =
      const VerificationMeta('categoryFk');
  @override
  late final GeneratedColumn<String> categoryFk = GeneratedColumn<String>(
      'category_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (category_pk)'));
  static const VerificationMeta _subCategoryFkMeta =
      const VerificationMeta('subCategoryFk');
  @override
  late final GeneratedColumn<String> subCategoryFk = GeneratedColumn<String>(
      'sub_category_fk', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (category_pk)'),
      defaultValue: const Constant(null));
  static const VerificationMeta _walletFkMeta =
      const VerificationMeta('walletFk');
  @override
  late final GeneratedColumn<String> walletFk = GeneratedColumn<String>(
      'wallet_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (wallet_pk)'),
      defaultValue: const Constant("0"));
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => new DateTime.now());
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _originalDateDueMeta =
      const VerificationMeta('originalDateDue');
  @override
  late final GeneratedColumn<DateTime> originalDateDue =
      GeneratedColumn<DateTime>('original_date_due', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _incomeMeta = const VerificationMeta('income');
  @override
  late final GeneratedColumn<bool> income = GeneratedColumn<bool>(
      'income', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("income" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _periodLengthMeta =
      const VerificationMeta('periodLength');
  @override
  late final GeneratedColumn<int> periodLength = GeneratedColumn<int>(
      'period_length', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _reoccurrenceMeta =
      const VerificationMeta('reoccurrence');
  @override
  late final GeneratedColumnWithTypeConverter<BudgetReoccurence?, int>
      reoccurrence = GeneratedColumn<int>('reoccurrence', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<BudgetReoccurence?>(
              $TransactionsTable.$converterreoccurrencen);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _upcomingTransactionNotificationMeta =
      const VerificationMeta('upcomingTransactionNotification');
  @override
  late final GeneratedColumn<bool> upcomingTransactionNotification =
      GeneratedColumn<bool>(
          'upcoming_transaction_notification', aliasedName, true,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("upcoming_transaction_notification" IN (0, 1))'),
          defaultValue: const Constant(true));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<TransactionSpecialType?, int>
      type = GeneratedColumn<int>('type', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<TransactionSpecialType?>(
              $TransactionsTable.$convertertypen);
  static const VerificationMeta _paidMeta = const VerificationMeta('paid');
  @override
  late final GeneratedColumn<bool> paid = GeneratedColumn<bool>(
      'paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("paid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAnotherFutureTransactionMeta =
      const VerificationMeta('createdAnotherFutureTransaction');
  @override
  late final GeneratedColumn<bool> createdAnotherFutureTransaction =
      GeneratedColumn<bool>(
          'created_another_future_transaction', aliasedName, true,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("created_another_future_transaction" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _skipPaidMeta =
      const VerificationMeta('skipPaid');
  @override
  late final GeneratedColumn<bool> skipPaid = GeneratedColumn<bool>(
      'skip_paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("skip_paid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _methodAddedMeta =
      const VerificationMeta('methodAdded');
  @override
  late final GeneratedColumnWithTypeConverter<MethodAdded?, int> methodAdded =
      GeneratedColumn<int>('method_added', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<MethodAdded?>(
              $TransactionsTable.$convertermethodAddedn);
  static const VerificationMeta _transactionOwnerEmailMeta =
      const VerificationMeta('transactionOwnerEmail');
  @override
  late final GeneratedColumn<String> transactionOwnerEmail =
      GeneratedColumn<String>('transaction_owner_email', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transactionOriginalOwnerEmailMeta =
      const VerificationMeta('transactionOriginalOwnerEmail');
  @override
  late final GeneratedColumn<String> transactionOriginalOwnerEmail =
      GeneratedColumn<String>(
          'transaction_original_owner_email', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sharedKeyMeta =
      const VerificationMeta('sharedKey');
  @override
  late final GeneratedColumn<String> sharedKey = GeneratedColumn<String>(
      'shared_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sharedOldKeyMeta =
      const VerificationMeta('sharedOldKey');
  @override
  late final GeneratedColumn<String> sharedOldKey = GeneratedColumn<String>(
      'shared_old_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sharedStatusMeta =
      const VerificationMeta('sharedStatus');
  @override
  late final GeneratedColumnWithTypeConverter<SharedStatus?, int> sharedStatus =
      GeneratedColumn<int>('shared_status', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<SharedStatus?>(
              $TransactionsTable.$convertersharedStatusn);
  static const VerificationMeta _sharedDateUpdatedMeta =
      const VerificationMeta('sharedDateUpdated');
  @override
  late final GeneratedColumn<DateTime> sharedDateUpdated =
      GeneratedColumn<DateTime>('shared_date_updated', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sharedReferenceBudgetPkMeta =
      const VerificationMeta('sharedReferenceBudgetPk');
  @override
  late final GeneratedColumn<String> sharedReferenceBudgetPk =
      GeneratedColumn<String>('shared_reference_budget_pk', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _objectiveFkMeta =
      const VerificationMeta('objectiveFk');
  @override
  late final GeneratedColumn<String> objectiveFk = GeneratedColumn<String>(
      'objective_fk', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES objectives (objective_pk)'));
  static const VerificationMeta _objectiveLoanFkMeta =
      const VerificationMeta('objectiveLoanFk');
  @override
  late final GeneratedColumn<String> objectiveLoanFk = GeneratedColumn<String>(
      'objective_loan_fk', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES objectives (objective_pk)'));
  static const VerificationMeta _budgetFksExcludeMeta =
      const VerificationMeta('budgetFksExclude');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
      budgetFksExclude = GeneratedColumn<String>(
              'budget_fks_exclude', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>(
              $TransactionsTable.$converterbudgetFksExcluden);
  static const VerificationMeta _payeeFkMeta =
      const VerificationMeta('payeeFk');
  @override
  late final GeneratedColumn<String> payeeFk = GeneratedColumn<String>(
      'payee_fk', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES payees (payee_pk)'));
  static const VerificationMeta _foreignAmountMeta =
      const VerificationMeta('foreignAmount');
  @override
  late final GeneratedColumn<double> foreignAmount = GeneratedColumn<double>(
      'foreign_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _foreignCurrencyMeta =
      const VerificationMeta('foreignCurrency');
  @override
  late final GeneratedColumn<String> foreignCurrency = GeneratedColumn<String>(
      'foreign_currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _splitGroupFkMeta =
      const VerificationMeta('splitGroupFk');
  @override
  late final GeneratedColumn<String> splitGroupFk = GeneratedColumn<String>(
      'split_group_fk', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES transaction_groups (group_pk)'));
  static const VerificationMeta _splitOrderMeta =
      const VerificationMeta('splitOrder');
  @override
  late final GeneratedColumn<int> splitOrder = GeneratedColumn<int>(
      'split_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _fireflyTypeMeta =
      const VerificationMeta('fireflyType');
  @override
  late final GeneratedColumnWithTypeConverter<FireflyTransactionType?, int>
      fireflyType = GeneratedColumn<int>('firefly_type', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<FireflyTransactionType?>(
              $TransactionsTable.$converterfireflyTypen);
  static const VerificationMeta _billFkMeta = const VerificationMeta('billFk');
  @override
  late final GeneratedColumn<String> billFk = GeneratedColumn<String>(
      'bill_fk', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reconciledMeta =
      const VerificationMeta('reconciled');
  @override
  late final GeneratedColumn<bool> reconciled = GeneratedColumn<bool>(
      'reconciled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("reconciled" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        transactionPk,
        pairedTransactionFk,
        name,
        amount,
        note,
        categoryFk,
        subCategoryFk,
        walletFk,
        dateCreated,
        dateTimeModified,
        originalDateDue,
        income,
        periodLength,
        reoccurrence,
        endDate,
        upcomingTransactionNotification,
        type,
        paid,
        createdAnotherFutureTransaction,
        skipPaid,
        methodAdded,
        transactionOwnerEmail,
        transactionOriginalOwnerEmail,
        sharedKey,
        sharedOldKey,
        sharedStatus,
        sharedDateUpdated,
        sharedReferenceBudgetPk,
        objectiveFk,
        objectiveLoanFk,
        budgetFksExclude,
        payeeFk,
        foreignAmount,
        foreignCurrency,
        splitGroupFk,
        splitOrder,
        fireflyType,
        billFk,
        reconciled
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_pk')) {
      context.handle(
          _transactionPkMeta,
          transactionPk.isAcceptableOrUnknown(
              data['transaction_pk']!, _transactionPkMeta));
    }
    if (data.containsKey('paired_transaction_fk')) {
      context.handle(
          _pairedTransactionFkMeta,
          pairedTransactionFk.isAcceptableOrUnknown(
              data['paired_transaction_fk']!, _pairedTransactionFkMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('category_fk')) {
      context.handle(
          _categoryFkMeta,
          categoryFk.isAcceptableOrUnknown(
              data['category_fk']!, _categoryFkMeta));
    } else if (isInserting) {
      context.missing(_categoryFkMeta);
    }
    if (data.containsKey('sub_category_fk')) {
      context.handle(
          _subCategoryFkMeta,
          subCategoryFk.isAcceptableOrUnknown(
              data['sub_category_fk']!, _subCategoryFkMeta));
    }
    if (data.containsKey('wallet_fk')) {
      context.handle(_walletFkMeta,
          walletFk.isAcceptableOrUnknown(data['wallet_fk']!, _walletFkMeta));
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    if (data.containsKey('original_date_due')) {
      context.handle(
          _originalDateDueMeta,
          originalDateDue.isAcceptableOrUnknown(
              data['original_date_due']!, _originalDateDueMeta));
    }
    if (data.containsKey('income')) {
      context.handle(_incomeMeta,
          income.isAcceptableOrUnknown(data['income']!, _incomeMeta));
    }
    if (data.containsKey('period_length')) {
      context.handle(
          _periodLengthMeta,
          periodLength.isAcceptableOrUnknown(
              data['period_length']!, _periodLengthMeta));
    }
    context.handle(_reoccurrenceMeta, const VerificationResult.success());
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('upcoming_transaction_notification')) {
      context.handle(
          _upcomingTransactionNotificationMeta,
          upcomingTransactionNotification.isAcceptableOrUnknown(
              data['upcoming_transaction_notification']!,
              _upcomingTransactionNotificationMeta));
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('paid')) {
      context.handle(
          _paidMeta, paid.isAcceptableOrUnknown(data['paid']!, _paidMeta));
    }
    if (data.containsKey('created_another_future_transaction')) {
      context.handle(
          _createdAnotherFutureTransactionMeta,
          createdAnotherFutureTransaction.isAcceptableOrUnknown(
              data['created_another_future_transaction']!,
              _createdAnotherFutureTransactionMeta));
    }
    if (data.containsKey('skip_paid')) {
      context.handle(_skipPaidMeta,
          skipPaid.isAcceptableOrUnknown(data['skip_paid']!, _skipPaidMeta));
    }
    context.handle(_methodAddedMeta, const VerificationResult.success());
    if (data.containsKey('transaction_owner_email')) {
      context.handle(
          _transactionOwnerEmailMeta,
          transactionOwnerEmail.isAcceptableOrUnknown(
              data['transaction_owner_email']!, _transactionOwnerEmailMeta));
    }
    if (data.containsKey('transaction_original_owner_email')) {
      context.handle(
          _transactionOriginalOwnerEmailMeta,
          transactionOriginalOwnerEmail.isAcceptableOrUnknown(
              data['transaction_original_owner_email']!,
              _transactionOriginalOwnerEmailMeta));
    }
    if (data.containsKey('shared_key')) {
      context.handle(_sharedKeyMeta,
          sharedKey.isAcceptableOrUnknown(data['shared_key']!, _sharedKeyMeta));
    }
    if (data.containsKey('shared_old_key')) {
      context.handle(
          _sharedOldKeyMeta,
          sharedOldKey.isAcceptableOrUnknown(
              data['shared_old_key']!, _sharedOldKeyMeta));
    }
    context.handle(_sharedStatusMeta, const VerificationResult.success());
    if (data.containsKey('shared_date_updated')) {
      context.handle(
          _sharedDateUpdatedMeta,
          sharedDateUpdated.isAcceptableOrUnknown(
              data['shared_date_updated']!, _sharedDateUpdatedMeta));
    }
    if (data.containsKey('shared_reference_budget_pk')) {
      context.handle(
          _sharedReferenceBudgetPkMeta,
          sharedReferenceBudgetPk.isAcceptableOrUnknown(
              data['shared_reference_budget_pk']!,
              _sharedReferenceBudgetPkMeta));
    }
    if (data.containsKey('objective_fk')) {
      context.handle(
          _objectiveFkMeta,
          objectiveFk.isAcceptableOrUnknown(
              data['objective_fk']!, _objectiveFkMeta));
    }
    if (data.containsKey('objective_loan_fk')) {
      context.handle(
          _objectiveLoanFkMeta,
          objectiveLoanFk.isAcceptableOrUnknown(
              data['objective_loan_fk']!, _objectiveLoanFkMeta));
    }
    context.handle(_budgetFksExcludeMeta, const VerificationResult.success());
    if (data.containsKey('payee_fk')) {
      context.handle(_payeeFkMeta,
          payeeFk.isAcceptableOrUnknown(data['payee_fk']!, _payeeFkMeta));
    }
    if (data.containsKey('foreign_amount')) {
      context.handle(
          _foreignAmountMeta,
          foreignAmount.isAcceptableOrUnknown(
              data['foreign_amount']!, _foreignAmountMeta));
    }
    if (data.containsKey('foreign_currency')) {
      context.handle(
          _foreignCurrencyMeta,
          foreignCurrency.isAcceptableOrUnknown(
              data['foreign_currency']!, _foreignCurrencyMeta));
    }
    if (data.containsKey('split_group_fk')) {
      context.handle(
          _splitGroupFkMeta,
          splitGroupFk.isAcceptableOrUnknown(
              data['split_group_fk']!, _splitGroupFkMeta));
    }
    if (data.containsKey('split_order')) {
      context.handle(
          _splitOrderMeta,
          splitOrder.isAcceptableOrUnknown(
              data['split_order']!, _splitOrderMeta));
    }
    context.handle(_fireflyTypeMeta, const VerificationResult.success());
    if (data.containsKey('bill_fk')) {
      context.handle(_billFkMeta,
          billFk.isAcceptableOrUnknown(data['bill_fk']!, _billFkMeta));
    }
    if (data.containsKey('reconciled')) {
      context.handle(
          _reconciledMeta,
          reconciled.isAcceptableOrUnknown(
              data['reconciled']!, _reconciledMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionPk};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      transactionPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_pk'])!,
      pairedTransactionFk: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}paired_transaction_fk']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      categoryFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_fk'])!,
      subCategoryFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sub_category_fk']),
      walletFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wallet_fk'])!,
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
      originalDateDue: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}original_date_due']),
      income: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}income'])!,
      periodLength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_length']),
      reoccurrence: $TransactionsTable.$converterreoccurrencen.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}reoccurrence'])),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      upcomingTransactionNotification: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}upcoming_transaction_notification']),
      type: $TransactionsTable.$convertertypen.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])),
      paid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}paid'])!,
      createdAnotherFutureTransaction: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}created_another_future_transaction']),
      skipPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}skip_paid'])!,
      methodAdded: $TransactionsTable.$convertermethodAddedn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}method_added'])),
      transactionOwnerEmail: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}transaction_owner_email']),
      transactionOriginalOwnerEmail: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}transaction_original_owner_email']),
      sharedKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shared_key']),
      sharedOldKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shared_old_key']),
      sharedStatus: $TransactionsTable.$convertersharedStatusn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}shared_status'])),
      sharedDateUpdated: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}shared_date_updated']),
      sharedReferenceBudgetPk: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}shared_reference_budget_pk']),
      objectiveFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}objective_fk']),
      objectiveLoanFk: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}objective_loan_fk']),
      budgetFksExclude: $TransactionsTable.$converterbudgetFksExcluden.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}budget_fks_exclude'])),
      payeeFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payee_fk']),
      foreignAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}foreign_amount']),
      foreignCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}foreign_currency']),
      splitGroupFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}split_group_fk']),
      splitOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}split_order']),
      fireflyType: $TransactionsTable.$converterfireflyTypen.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}firefly_type'])),
      billFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_fk']),
      reconciled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}reconciled'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BudgetReoccurence, int, int>
      $converterreoccurrence =
      const EnumIndexConverter<BudgetReoccurence>(BudgetReoccurence.values);
  static JsonTypeConverter2<BudgetReoccurence?, int?, int?>
      $converterreoccurrencen =
      JsonTypeConverter2.asNullable($converterreoccurrence);
  static JsonTypeConverter2<TransactionSpecialType, int, int> $convertertype =
      const EnumIndexConverter<TransactionSpecialType>(
          TransactionSpecialType.values);
  static JsonTypeConverter2<TransactionSpecialType?, int?, int?>
      $convertertypen = JsonTypeConverter2.asNullable($convertertype);
  static JsonTypeConverter2<MethodAdded, int, int> $convertermethodAdded =
      const EnumIndexConverter<MethodAdded>(MethodAdded.values);
  static JsonTypeConverter2<MethodAdded?, int?, int?> $convertermethodAddedn =
      JsonTypeConverter2.asNullable($convertermethodAdded);
  static JsonTypeConverter2<SharedStatus, int, int> $convertersharedStatus =
      const EnumIndexConverter<SharedStatus>(SharedStatus.values);
  static JsonTypeConverter2<SharedStatus?, int?, int?> $convertersharedStatusn =
      JsonTypeConverter2.asNullable($convertersharedStatus);
  static TypeConverter<List<String>, String> $converterbudgetFksExclude =
      const StringListInColumnConverter();
  static TypeConverter<List<String>?, String?> $converterbudgetFksExcluden =
      NullAwareTypeConverter.wrap($converterbudgetFksExclude);
  static JsonTypeConverter2<FireflyTransactionType, int, int>
      $converterfireflyType = const EnumIndexConverter<FireflyTransactionType>(
          FireflyTransactionType.values);
  static JsonTypeConverter2<FireflyTransactionType?, int?, int?>
      $converterfireflyTypen =
      JsonTypeConverter2.asNullable($converterfireflyType);
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String transactionPk;
  final String? pairedTransactionFk;
  final String name;
  final double amount;
  final String note;
  final String categoryFk;
  final String? subCategoryFk;
  final String walletFk;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  final DateTime? originalDateDue;
  final bool income;
  final int? periodLength;
  final BudgetReoccurence? reoccurrence;
  final DateTime? endDate;
  final bool? upcomingTransactionNotification;
  final TransactionSpecialType? type;
  final bool paid;
  final bool? createdAnotherFutureTransaction;
  final bool skipPaid;
  final MethodAdded? methodAdded;
  final String? transactionOwnerEmail;
  final String? transactionOriginalOwnerEmail;
  final String? sharedKey;
  final String? sharedOldKey;
  final SharedStatus? sharedStatus;
  final DateTime? sharedDateUpdated;
  final String? sharedReferenceBudgetPk;
  final String? objectiveFk;
  final String? objectiveLoanFk;
  final List<String>? budgetFksExclude;
  final String? payeeFk;
  final double? foreignAmount;
  final String? foreignCurrency;
  final String? splitGroupFk;
  final int? splitOrder;
  final FireflyTransactionType? fireflyType;
  final String? billFk;
  final bool reconciled;
  const Transaction(
      {required this.transactionPk,
      this.pairedTransactionFk,
      required this.name,
      required this.amount,
      required this.note,
      required this.categoryFk,
      this.subCategoryFk,
      required this.walletFk,
      required this.dateCreated,
      this.dateTimeModified,
      this.originalDateDue,
      required this.income,
      this.periodLength,
      this.reoccurrence,
      this.endDate,
      this.upcomingTransactionNotification,
      this.type,
      required this.paid,
      this.createdAnotherFutureTransaction,
      required this.skipPaid,
      this.methodAdded,
      this.transactionOwnerEmail,
      this.transactionOriginalOwnerEmail,
      this.sharedKey,
      this.sharedOldKey,
      this.sharedStatus,
      this.sharedDateUpdated,
      this.sharedReferenceBudgetPk,
      this.objectiveFk,
      this.objectiveLoanFk,
      this.budgetFksExclude,
      this.payeeFk,
      this.foreignAmount,
      this.foreignCurrency,
      this.splitGroupFk,
      this.splitOrder,
      this.fireflyType,
      this.billFk,
      this.reconciled = false});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_pk'] = Variable<String>(transactionPk);
    if (!nullToAbsent || pairedTransactionFk != null) {
      map['paired_transaction_fk'] = Variable<String>(pairedTransactionFk);
    }
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['note'] = Variable<String>(note);
    map['category_fk'] = Variable<String>(categoryFk);
    if (!nullToAbsent || subCategoryFk != null) {
      map['sub_category_fk'] = Variable<String>(subCategoryFk);
    }
    map['wallet_fk'] = Variable<String>(walletFk);
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    if (!nullToAbsent || originalDateDue != null) {
      map['original_date_due'] = Variable<DateTime>(originalDateDue);
    }
    map['income'] = Variable<bool>(income);
    if (!nullToAbsent || periodLength != null) {
      map['period_length'] = Variable<int>(periodLength);
    }
    if (!nullToAbsent || reoccurrence != null) {
      map['reoccurrence'] = Variable<int>(
          $TransactionsTable.$converterreoccurrencen.toSql(reoccurrence));
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || upcomingTransactionNotification != null) {
      map['upcoming_transaction_notification'] =
          Variable<bool>(upcomingTransactionNotification);
    }
    if (!nullToAbsent || type != null) {
      map['type'] =
          Variable<int>($TransactionsTable.$convertertypen.toSql(type));
    }
    map['paid'] = Variable<bool>(paid);
    if (!nullToAbsent || createdAnotherFutureTransaction != null) {
      map['created_another_future_transaction'] =
          Variable<bool>(createdAnotherFutureTransaction);
    }
    map['skip_paid'] = Variable<bool>(skipPaid);
    if (!nullToAbsent || methodAdded != null) {
      map['method_added'] = Variable<int>(
          $TransactionsTable.$convertermethodAddedn.toSql(methodAdded));
    }
    if (!nullToAbsent || transactionOwnerEmail != null) {
      map['transaction_owner_email'] = Variable<String>(transactionOwnerEmail);
    }
    if (!nullToAbsent || transactionOriginalOwnerEmail != null) {
      map['transaction_original_owner_email'] =
          Variable<String>(transactionOriginalOwnerEmail);
    }
    if (!nullToAbsent || sharedKey != null) {
      map['shared_key'] = Variable<String>(sharedKey);
    }
    if (!nullToAbsent || sharedOldKey != null) {
      map['shared_old_key'] = Variable<String>(sharedOldKey);
    }
    if (!nullToAbsent || sharedStatus != null) {
      map['shared_status'] = Variable<int>(
          $TransactionsTable.$convertersharedStatusn.toSql(sharedStatus));
    }
    if (!nullToAbsent || sharedDateUpdated != null) {
      map['shared_date_updated'] = Variable<DateTime>(sharedDateUpdated);
    }
    if (!nullToAbsent || sharedReferenceBudgetPk != null) {
      map['shared_reference_budget_pk'] =
          Variable<String>(sharedReferenceBudgetPk);
    }
    if (!nullToAbsent || objectiveFk != null) {
      map['objective_fk'] = Variable<String>(objectiveFk);
    }
    if (!nullToAbsent || objectiveLoanFk != null) {
      map['objective_loan_fk'] = Variable<String>(objectiveLoanFk);
    }
    if (!nullToAbsent || budgetFksExclude != null) {
      map['budget_fks_exclude'] = Variable<String>($TransactionsTable
          .$converterbudgetFksExcluden
          .toSql(budgetFksExclude));
    }
    if (!nullToAbsent || payeeFk != null) {
      map['payee_fk'] = Variable<String>(payeeFk);
    }
    if (!nullToAbsent || foreignAmount != null) {
      map['foreign_amount'] = Variable<double>(foreignAmount);
    }
    if (!nullToAbsent || foreignCurrency != null) {
      map['foreign_currency'] = Variable<String>(foreignCurrency);
    }
    if (!nullToAbsent || splitGroupFk != null) {
      map['split_group_fk'] = Variable<String>(splitGroupFk);
    }
    if (!nullToAbsent || splitOrder != null) {
      map['split_order'] = Variable<int>(splitOrder);
    }
    if (!nullToAbsent || fireflyType != null) {
      map['firefly_type'] = Variable<int>(
          $TransactionsTable.$converterfireflyTypen.toSql(fireflyType));
    }
    if (!nullToAbsent || billFk != null) {
      map['bill_fk'] = Variable<String>(billFk);
    }
    map['reconciled'] = Variable<bool>(reconciled);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      transactionPk: Value(transactionPk),
      pairedTransactionFk: pairedTransactionFk == null && nullToAbsent
          ? const Value.absent()
          : Value(pairedTransactionFk),
      name: Value(name),
      amount: Value(amount),
      note: Value(note),
      categoryFk: Value(categoryFk),
      subCategoryFk: subCategoryFk == null && nullToAbsent
          ? const Value.absent()
          : Value(subCategoryFk),
      walletFk: Value(walletFk),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
      originalDateDue: originalDateDue == null && nullToAbsent
          ? const Value.absent()
          : Value(originalDateDue),
      income: Value(income),
      periodLength: periodLength == null && nullToAbsent
          ? const Value.absent()
          : Value(periodLength),
      reoccurrence: reoccurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(reoccurrence),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      upcomingTransactionNotification:
          upcomingTransactionNotification == null && nullToAbsent
              ? const Value.absent()
              : Value(upcomingTransactionNotification),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      paid: Value(paid),
      createdAnotherFutureTransaction:
          createdAnotherFutureTransaction == null && nullToAbsent
              ? const Value.absent()
              : Value(createdAnotherFutureTransaction),
      skipPaid: Value(skipPaid),
      methodAdded: methodAdded == null && nullToAbsent
          ? const Value.absent()
          : Value(methodAdded),
      transactionOwnerEmail: transactionOwnerEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionOwnerEmail),
      transactionOriginalOwnerEmail:
          transactionOriginalOwnerEmail == null && nullToAbsent
              ? const Value.absent()
              : Value(transactionOriginalOwnerEmail),
      sharedKey: sharedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedKey),
      sharedOldKey: sharedOldKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedOldKey),
      sharedStatus: sharedStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedStatus),
      sharedDateUpdated: sharedDateUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedDateUpdated),
      sharedReferenceBudgetPk: sharedReferenceBudgetPk == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedReferenceBudgetPk),
      objectiveFk: objectiveFk == null && nullToAbsent
          ? const Value.absent()
          : Value(objectiveFk),
      objectiveLoanFk: objectiveLoanFk == null && nullToAbsent
          ? const Value.absent()
          : Value(objectiveLoanFk),
      budgetFksExclude: budgetFksExclude == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetFksExclude),
      payeeFk: payeeFk == null && nullToAbsent
          ? const Value.absent()
          : Value(payeeFk),
      foreignAmount: foreignAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(foreignAmount),
      foreignCurrency: foreignCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(foreignCurrency),
      splitGroupFk: splitGroupFk == null && nullToAbsent
          ? const Value.absent()
          : Value(splitGroupFk),
      splitOrder: splitOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(splitOrder),
      fireflyType: fireflyType == null && nullToAbsent
          ? const Value.absent()
          : Value(fireflyType),
      billFk:
          billFk == null && nullToAbsent ? const Value.absent() : Value(billFk),
      reconciled: Value(reconciled),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      transactionPk: serializer.fromJson<String>(json['transactionPk']),
      pairedTransactionFk:
          serializer.fromJson<String?>(json['pairedTransactionFk']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      categoryFk: serializer.fromJson<String>(json['categoryFk']),
      subCategoryFk: serializer.fromJson<String?>(json['subCategoryFk']),
      walletFk: serializer.fromJson<String>(json['walletFk']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
      originalDateDue: serializer.fromJson<DateTime?>(json['originalDateDue']),
      income: serializer.fromJson<bool>(json['income']),
      periodLength: serializer.fromJson<int?>(json['periodLength']),
      reoccurrence: $TransactionsTable.$converterreoccurrencen
          .fromJson(serializer.fromJson<int?>(json['reoccurrence'])),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      upcomingTransactionNotification:
          serializer.fromJson<bool?>(json['upcomingTransactionNotification']),
      type: $TransactionsTable.$convertertypen
          .fromJson(serializer.fromJson<int?>(json['type'])),
      paid: serializer.fromJson<bool>(json['paid']),
      createdAnotherFutureTransaction:
          serializer.fromJson<bool?>(json['createdAnotherFutureTransaction']),
      skipPaid: serializer.fromJson<bool>(json['skipPaid']),
      methodAdded: $TransactionsTable.$convertermethodAddedn
          .fromJson(serializer.fromJson<int?>(json['methodAdded'])),
      transactionOwnerEmail:
          serializer.fromJson<String?>(json['transactionOwnerEmail']),
      transactionOriginalOwnerEmail:
          serializer.fromJson<String?>(json['transactionOriginalOwnerEmail']),
      sharedKey: serializer.fromJson<String?>(json['sharedKey']),
      sharedOldKey: serializer.fromJson<String?>(json['sharedOldKey']),
      sharedStatus: $TransactionsTable.$convertersharedStatusn
          .fromJson(serializer.fromJson<int?>(json['sharedStatus'])),
      sharedDateUpdated:
          serializer.fromJson<DateTime?>(json['sharedDateUpdated']),
      sharedReferenceBudgetPk:
          serializer.fromJson<String?>(json['sharedReferenceBudgetPk']),
      objectiveFk: serializer.fromJson<String?>(json['objectiveFk']),
      objectiveLoanFk: serializer.fromJson<String?>(json['objectiveLoanFk']),
      budgetFksExclude:
          serializer.fromJson<List<String>?>(json['budgetFksExclude']),
      payeeFk: serializer.fromJson<String?>(json['payeeFk']),
      foreignAmount: serializer.fromJson<double?>(json['foreignAmount']),
      foreignCurrency: serializer.fromJson<String?>(json['foreignCurrency']),
      splitGroupFk: serializer.fromJson<String?>(json['splitGroupFk']),
      splitOrder: serializer.fromJson<int?>(json['splitOrder']),
      fireflyType: $TransactionsTable.$converterfireflyTypen
          .fromJson(serializer.fromJson<int?>(json['fireflyType'])),
      billFk: serializer.fromJson<String?>(json['billFk']),
      reconciled: serializer.fromJson<bool?>(json['reconciled']) ?? false,
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionPk': serializer.toJson<String>(transactionPk),
      'pairedTransactionFk': serializer.toJson<String?>(pairedTransactionFk),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String>(note),
      'categoryFk': serializer.toJson<String>(categoryFk),
      'subCategoryFk': serializer.toJson<String?>(subCategoryFk),
      'walletFk': serializer.toJson<String>(walletFk),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
      'originalDateDue': serializer.toJson<DateTime?>(originalDateDue),
      'income': serializer.toJson<bool>(income),
      'periodLength': serializer.toJson<int?>(periodLength),
      'reoccurrence': serializer.toJson<int?>(
          $TransactionsTable.$converterreoccurrencen.toJson(reoccurrence)),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'upcomingTransactionNotification':
          serializer.toJson<bool?>(upcomingTransactionNotification),
      'type': serializer
          .toJson<int?>($TransactionsTable.$convertertypen.toJson(type)),
      'paid': serializer.toJson<bool>(paid),
      'createdAnotherFutureTransaction':
          serializer.toJson<bool?>(createdAnotherFutureTransaction),
      'skipPaid': serializer.toJson<bool>(skipPaid),
      'methodAdded': serializer.toJson<int?>(
          $TransactionsTable.$convertermethodAddedn.toJson(methodAdded)),
      'transactionOwnerEmail':
          serializer.toJson<String?>(transactionOwnerEmail),
      'transactionOriginalOwnerEmail':
          serializer.toJson<String?>(transactionOriginalOwnerEmail),
      'sharedKey': serializer.toJson<String?>(sharedKey),
      'sharedOldKey': serializer.toJson<String?>(sharedOldKey),
      'sharedStatus': serializer.toJson<int?>(
          $TransactionsTable.$convertersharedStatusn.toJson(sharedStatus)),
      'sharedDateUpdated': serializer.toJson<DateTime?>(sharedDateUpdated),
      'sharedReferenceBudgetPk':
          serializer.toJson<String?>(sharedReferenceBudgetPk),
      'objectiveFk': serializer.toJson<String?>(objectiveFk),
      'objectiveLoanFk': serializer.toJson<String?>(objectiveLoanFk),
      'budgetFksExclude': serializer.toJson<List<String>?>(budgetFksExclude),
      'payeeFk': serializer.toJson<String?>(payeeFk),
      'foreignAmount': serializer.toJson<double?>(foreignAmount),
      'foreignCurrency': serializer.toJson<String?>(foreignCurrency),
      'splitGroupFk': serializer.toJson<String?>(splitGroupFk),
      'splitOrder': serializer.toJson<int?>(splitOrder),
      'fireflyType': serializer.toJson<int?>(
          $TransactionsTable.$converterfireflyTypen.toJson(fireflyType)),
      'billFk': serializer.toJson<String?>(billFk),
      'reconciled': serializer.toJson<bool>(reconciled),
    };
  }

  Transaction copyWith(
          {String? transactionPk,
          Value<String?> pairedTransactionFk = const Value.absent(),
          String? name,
          double? amount,
          String? note,
          String? categoryFk,
          Value<String?> subCategoryFk = const Value.absent(),
          String? walletFk,
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent(),
          Value<DateTime?> originalDateDue = const Value.absent(),
          bool? income,
          Value<int?> periodLength = const Value.absent(),
          Value<BudgetReoccurence?> reoccurrence = const Value.absent(),
          Value<DateTime?> endDate = const Value.absent(),
          Value<bool?> upcomingTransactionNotification = const Value.absent(),
          Value<TransactionSpecialType?> type = const Value.absent(),
          bool? paid,
          Value<bool?> createdAnotherFutureTransaction = const Value.absent(),
          bool? skipPaid,
          Value<MethodAdded?> methodAdded = const Value.absent(),
          Value<String?> transactionOwnerEmail = const Value.absent(),
          Value<String?> transactionOriginalOwnerEmail = const Value.absent(),
          Value<String?> sharedKey = const Value.absent(),
          Value<String?> sharedOldKey = const Value.absent(),
          Value<SharedStatus?> sharedStatus = const Value.absent(),
          Value<DateTime?> sharedDateUpdated = const Value.absent(),
          Value<String?> sharedReferenceBudgetPk = const Value.absent(),
          Value<String?> objectiveFk = const Value.absent(),
          Value<String?> objectiveLoanFk = const Value.absent(),
          Value<List<String>?> budgetFksExclude = const Value.absent(),
          Value<String?> payeeFk = const Value.absent(),
          Value<double?> foreignAmount = const Value.absent(),
          Value<String?> foreignCurrency = const Value.absent(),
          Value<String?> splitGroupFk = const Value.absent(),
          Value<int?> splitOrder = const Value.absent(),
          Value<FireflyTransactionType?> fireflyType = const Value.absent(),
          Value<String?> billFk = const Value.absent(),
          bool? reconciled}) =>
      Transaction(
        transactionPk: transactionPk ?? this.transactionPk,
        pairedTransactionFk: pairedTransactionFk.present
            ? pairedTransactionFk.value
            : this.pairedTransactionFk,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        categoryFk: categoryFk ?? this.categoryFk,
        subCategoryFk:
            subCategoryFk.present ? subCategoryFk.value : this.subCategoryFk,
        walletFk: walletFk ?? this.walletFk,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
        originalDateDue: originalDateDue.present
            ? originalDateDue.value
            : this.originalDateDue,
        income: income ?? this.income,
        periodLength:
            periodLength.present ? periodLength.value : this.periodLength,
        reoccurrence:
            reoccurrence.present ? reoccurrence.value : this.reoccurrence,
        endDate: endDate.present ? endDate.value : this.endDate,
        upcomingTransactionNotification: upcomingTransactionNotification.present
            ? upcomingTransactionNotification.value
            : this.upcomingTransactionNotification,
        type: type.present ? type.value : this.type,
        paid: paid ?? this.paid,
        createdAnotherFutureTransaction: createdAnotherFutureTransaction.present
            ? createdAnotherFutureTransaction.value
            : this.createdAnotherFutureTransaction,
        skipPaid: skipPaid ?? this.skipPaid,
        methodAdded: methodAdded.present ? methodAdded.value : this.methodAdded,
        transactionOwnerEmail: transactionOwnerEmail.present
            ? transactionOwnerEmail.value
            : this.transactionOwnerEmail,
        transactionOriginalOwnerEmail: transactionOriginalOwnerEmail.present
            ? transactionOriginalOwnerEmail.value
            : this.transactionOriginalOwnerEmail,
        sharedKey: sharedKey.present ? sharedKey.value : this.sharedKey,
        sharedOldKey:
            sharedOldKey.present ? sharedOldKey.value : this.sharedOldKey,
        sharedStatus:
            sharedStatus.present ? sharedStatus.value : this.sharedStatus,
        sharedDateUpdated: sharedDateUpdated.present
            ? sharedDateUpdated.value
            : this.sharedDateUpdated,
        sharedReferenceBudgetPk: sharedReferenceBudgetPk.present
            ? sharedReferenceBudgetPk.value
            : this.sharedReferenceBudgetPk,
        objectiveFk: objectiveFk.present ? objectiveFk.value : this.objectiveFk,
        objectiveLoanFk: objectiveLoanFk.present
            ? objectiveLoanFk.value
            : this.objectiveLoanFk,
        budgetFksExclude: budgetFksExclude.present
            ? budgetFksExclude.value
            : this.budgetFksExclude,
        payeeFk: payeeFk.present ? payeeFk.value : this.payeeFk,
        foreignAmount:
            foreignAmount.present ? foreignAmount.value : this.foreignAmount,
        foreignCurrency: foreignCurrency.present
            ? foreignCurrency.value
            : this.foreignCurrency,
        splitGroupFk:
            splitGroupFk.present ? splitGroupFk.value : this.splitGroupFk,
        splitOrder: splitOrder.present ? splitOrder.value : this.splitOrder,
        fireflyType: fireflyType.present ? fireflyType.value : this.fireflyType,
        billFk: billFk.present ? billFk.value : this.billFk,
        reconciled: reconciled ?? this.reconciled,
      );
  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('transactionPk: $transactionPk, ')
          ..write('pairedTransactionFk: $pairedTransactionFk, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('categoryFk: $categoryFk, ')
          ..write('subCategoryFk: $subCategoryFk, ')
          ..write('walletFk: $walletFk, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('originalDateDue: $originalDateDue, ')
          ..write('income: $income, ')
          ..write('periodLength: $periodLength, ')
          ..write('reoccurrence: $reoccurrence, ')
          ..write('endDate: $endDate, ')
          ..write(
              'upcomingTransactionNotification: $upcomingTransactionNotification, ')
          ..write('type: $type, ')
          ..write('paid: $paid, ')
          ..write(
              'createdAnotherFutureTransaction: $createdAnotherFutureTransaction, ')
          ..write('skipPaid: $skipPaid, ')
          ..write('methodAdded: $methodAdded, ')
          ..write('transactionOwnerEmail: $transactionOwnerEmail, ')
          ..write(
              'transactionOriginalOwnerEmail: $transactionOriginalOwnerEmail, ')
          ..write('sharedKey: $sharedKey, ')
          ..write('sharedOldKey: $sharedOldKey, ')
          ..write('sharedStatus: $sharedStatus, ')
          ..write('sharedDateUpdated: $sharedDateUpdated, ')
          ..write('sharedReferenceBudgetPk: $sharedReferenceBudgetPk, ')
          ..write('objectiveFk: $objectiveFk, ')
          ..write('objectiveLoanFk: $objectiveLoanFk, ')
          ..write('budgetFksExclude: $budgetFksExclude, ')
          ..write('payeeFk: $payeeFk, ')
          ..write('foreignAmount: $foreignAmount, ')
          ..write('foreignCurrency: $foreignCurrency, ')
          ..write('splitGroupFk: $splitGroupFk, ')
          ..write('splitOrder: $splitOrder, ')
          ..write('fireflyType: $fireflyType, ')
          ..write('billFk: $billFk, ')
          ..write('reconciled: $reconciled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        transactionPk,
        pairedTransactionFk,
        name,
        amount,
        note,
        categoryFk,
        subCategoryFk,
        walletFk,
        dateCreated,
        dateTimeModified,
        originalDateDue,
        income,
        periodLength,
        reoccurrence,
        endDate,
        upcomingTransactionNotification,
        type,
        paid,
        createdAnotherFutureTransaction,
        skipPaid,
        methodAdded,
        transactionOwnerEmail,
        transactionOriginalOwnerEmail,
        sharedKey,
        sharedOldKey,
        sharedStatus,
        sharedDateUpdated,
        sharedReferenceBudgetPk,
        objectiveFk,
        objectiveLoanFk,
        budgetFksExclude,
        payeeFk,
        foreignAmount,
        foreignCurrency,
        splitGroupFk,
        splitOrder,
        fireflyType,
        billFk,
        reconciled
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.transactionPk == this.transactionPk &&
          other.pairedTransactionFk == this.pairedTransactionFk &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.categoryFk == this.categoryFk &&
          other.subCategoryFk == this.subCategoryFk &&
          other.walletFk == this.walletFk &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified &&
          other.originalDateDue == this.originalDateDue &&
          other.income == this.income &&
          other.periodLength == this.periodLength &&
          other.reoccurrence == this.reoccurrence &&
          other.endDate == this.endDate &&
          other.upcomingTransactionNotification ==
              this.upcomingTransactionNotification &&
          other.type == this.type &&
          other.paid == this.paid &&
          other.createdAnotherFutureTransaction ==
              this.createdAnotherFutureTransaction &&
          other.skipPaid == this.skipPaid &&
          other.methodAdded == this.methodAdded &&
          other.transactionOwnerEmail == this.transactionOwnerEmail &&
          other.transactionOriginalOwnerEmail ==
              this.transactionOriginalOwnerEmail &&
          other.sharedKey == this.sharedKey &&
          other.sharedOldKey == this.sharedOldKey &&
          other.sharedStatus == this.sharedStatus &&
          other.sharedDateUpdated == this.sharedDateUpdated &&
          other.sharedReferenceBudgetPk == this.sharedReferenceBudgetPk &&
          other.objectiveFk == this.objectiveFk &&
          other.objectiveLoanFk == this.objectiveLoanFk &&
          other.budgetFksExclude == this.budgetFksExclude &&
          other.payeeFk == this.payeeFk &&
          other.foreignAmount == this.foreignAmount &&
          other.foreignCurrency == this.foreignCurrency &&
          other.splitGroupFk == this.splitGroupFk &&
          other.splitOrder == this.splitOrder &&
          other.fireflyType == this.fireflyType &&
          other.billFk == this.billFk &&
          other.reconciled == this.reconciled);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> transactionPk;
  final Value<String?> pairedTransactionFk;
  final Value<String> name;
  final Value<double> amount;
  final Value<String> note;
  final Value<String> categoryFk;
  final Value<String?> subCategoryFk;
  final Value<String> walletFk;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<DateTime?> originalDateDue;
  final Value<bool> income;
  final Value<int?> periodLength;
  final Value<BudgetReoccurence?> reoccurrence;
  final Value<DateTime?> endDate;
  final Value<bool?> upcomingTransactionNotification;
  final Value<TransactionSpecialType?> type;
  final Value<bool> paid;
  final Value<bool?> createdAnotherFutureTransaction;
  final Value<bool> skipPaid;
  final Value<MethodAdded?> methodAdded;
  final Value<String?> transactionOwnerEmail;
  final Value<String?> transactionOriginalOwnerEmail;
  final Value<String?> sharedKey;
  final Value<String?> sharedOldKey;
  final Value<SharedStatus?> sharedStatus;
  final Value<DateTime?> sharedDateUpdated;
  final Value<String?> sharedReferenceBudgetPk;
  final Value<String?> objectiveFk;
  final Value<String?> objectiveLoanFk;
  final Value<List<String>?> budgetFksExclude;
  final Value<String?> payeeFk;
  final Value<double?> foreignAmount;
  final Value<String?> foreignCurrency;
  final Value<String?> splitGroupFk;
  final Value<int?> splitOrder;
  final Value<FireflyTransactionType?> fireflyType;
  final Value<String?> billFk;
  final Value<bool> reconciled;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.transactionPk = const Value.absent(),
    this.pairedTransactionFk = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.categoryFk = const Value.absent(),
    this.subCategoryFk = const Value.absent(),
    this.walletFk = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.originalDateDue = const Value.absent(),
    this.income = const Value.absent(),
    this.periodLength = const Value.absent(),
    this.reoccurrence = const Value.absent(),
    this.endDate = const Value.absent(),
    this.upcomingTransactionNotification = const Value.absent(),
    this.type = const Value.absent(),
    this.paid = const Value.absent(),
    this.createdAnotherFutureTransaction = const Value.absent(),
    this.skipPaid = const Value.absent(),
    this.methodAdded = const Value.absent(),
    this.transactionOwnerEmail = const Value.absent(),
    this.transactionOriginalOwnerEmail = const Value.absent(),
    this.sharedKey = const Value.absent(),
    this.sharedOldKey = const Value.absent(),
    this.sharedStatus = const Value.absent(),
    this.sharedDateUpdated = const Value.absent(),
    this.sharedReferenceBudgetPk = const Value.absent(),
    this.objectiveFk = const Value.absent(),
    this.objectiveLoanFk = const Value.absent(),
    this.budgetFksExclude = const Value.absent(),
    this.payeeFk = const Value.absent(),
    this.foreignAmount = const Value.absent(),
    this.foreignCurrency = const Value.absent(),
    this.splitGroupFk = const Value.absent(),
    this.splitOrder = const Value.absent(),
    this.fireflyType = const Value.absent(),
    this.billFk = const Value.absent(),
    this.reconciled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.transactionPk = const Value.absent(),
    this.pairedTransactionFk = const Value.absent(),
    required String name,
    required double amount,
    required String note,
    required String categoryFk,
    this.subCategoryFk = const Value.absent(),
    this.walletFk = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.originalDateDue = const Value.absent(),
    this.income = const Value.absent(),
    this.periodLength = const Value.absent(),
    this.reoccurrence = const Value.absent(),
    this.endDate = const Value.absent(),
    this.upcomingTransactionNotification = const Value.absent(),
    this.type = const Value.absent(),
    this.paid = const Value.absent(),
    this.createdAnotherFutureTransaction = const Value.absent(),
    this.skipPaid = const Value.absent(),
    this.methodAdded = const Value.absent(),
    this.transactionOwnerEmail = const Value.absent(),
    this.transactionOriginalOwnerEmail = const Value.absent(),
    this.sharedKey = const Value.absent(),
    this.sharedOldKey = const Value.absent(),
    this.sharedStatus = const Value.absent(),
    this.sharedDateUpdated = const Value.absent(),
    this.sharedReferenceBudgetPk = const Value.absent(),
    this.objectiveFk = const Value.absent(),
    this.objectiveLoanFk = const Value.absent(),
    this.budgetFksExclude = const Value.absent(),
    this.payeeFk = const Value.absent(),
    this.foreignAmount = const Value.absent(),
    this.foreignCurrency = const Value.absent(),
    this.splitGroupFk = const Value.absent(),
    this.splitOrder = const Value.absent(),
    this.fireflyType = const Value.absent(),
    this.billFk = const Value.absent(),
    this.reconciled = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        amount = Value(amount),
        note = Value(note),
        categoryFk = Value(categoryFk);
  static Insertable<Transaction> custom({
    Expression<String>? transactionPk,
    Expression<String>? pairedTransactionFk,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<String>? categoryFk,
    Expression<String>? subCategoryFk,
    Expression<String>? walletFk,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<DateTime>? originalDateDue,
    Expression<bool>? income,
    Expression<int>? periodLength,
    Expression<int>? reoccurrence,
    Expression<DateTime>? endDate,
    Expression<bool>? upcomingTransactionNotification,
    Expression<int>? type,
    Expression<bool>? paid,
    Expression<bool>? createdAnotherFutureTransaction,
    Expression<bool>? skipPaid,
    Expression<int>? methodAdded,
    Expression<String>? transactionOwnerEmail,
    Expression<String>? transactionOriginalOwnerEmail,
    Expression<String>? sharedKey,
    Expression<String>? sharedOldKey,
    Expression<int>? sharedStatus,
    Expression<DateTime>? sharedDateUpdated,
    Expression<String>? sharedReferenceBudgetPk,
    Expression<String>? objectiveFk,
    Expression<String>? objectiveLoanFk,
    Expression<String>? budgetFksExclude,
    Expression<String>? payeeFk,
    Expression<double>? foreignAmount,
    Expression<String>? foreignCurrency,
    Expression<String>? splitGroupFk,
    Expression<int>? splitOrder,
    Expression<int>? fireflyType,
    Expression<String>? billFk,
    Expression<bool>? reconciled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionPk != null) 'transaction_pk': transactionPk,
      if (pairedTransactionFk != null)
        'paired_transaction_fk': pairedTransactionFk,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (categoryFk != null) 'category_fk': categoryFk,
      if (subCategoryFk != null) 'sub_category_fk': subCategoryFk,
      if (walletFk != null) 'wallet_fk': walletFk,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (originalDateDue != null) 'original_date_due': originalDateDue,
      if (income != null) 'income': income,
      if (periodLength != null) 'period_length': periodLength,
      if (reoccurrence != null) 'reoccurrence': reoccurrence,
      if (endDate != null) 'end_date': endDate,
      if (upcomingTransactionNotification != null)
        'upcoming_transaction_notification': upcomingTransactionNotification,
      if (type != null) 'type': type,
      if (paid != null) 'paid': paid,
      if (createdAnotherFutureTransaction != null)
        'created_another_future_transaction': createdAnotherFutureTransaction,
      if (skipPaid != null) 'skip_paid': skipPaid,
      if (methodAdded != null) 'method_added': methodAdded,
      if (transactionOwnerEmail != null)
        'transaction_owner_email': transactionOwnerEmail,
      if (transactionOriginalOwnerEmail != null)
        'transaction_original_owner_email': transactionOriginalOwnerEmail,
      if (sharedKey != null) 'shared_key': sharedKey,
      if (sharedOldKey != null) 'shared_old_key': sharedOldKey,
      if (sharedStatus != null) 'shared_status': sharedStatus,
      if (sharedDateUpdated != null) 'shared_date_updated': sharedDateUpdated,
      if (sharedReferenceBudgetPk != null)
        'shared_reference_budget_pk': sharedReferenceBudgetPk,
      if (objectiveFk != null) 'objective_fk': objectiveFk,
      if (objectiveLoanFk != null) 'objective_loan_fk': objectiveLoanFk,
      if (budgetFksExclude != null) 'budget_fks_exclude': budgetFksExclude,
      if (payeeFk != null) 'payee_fk': payeeFk,
      if (foreignAmount != null) 'foreign_amount': foreignAmount,
      if (foreignCurrency != null) 'foreign_currency': foreignCurrency,
      if (splitGroupFk != null) 'split_group_fk': splitGroupFk,
      if (splitOrder != null) 'split_order': splitOrder,
      if (fireflyType != null) 'firefly_type': fireflyType,
      if (billFk != null) 'bill_fk': billFk,
      if (reconciled != null) 'reconciled': reconciled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? transactionPk,
      Value<String?>? pairedTransactionFk,
      Value<String>? name,
      Value<double>? amount,
      Value<String>? note,
      Value<String>? categoryFk,
      Value<String?>? subCategoryFk,
      Value<String>? walletFk,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<DateTime?>? originalDateDue,
      Value<bool>? income,
      Value<int?>? periodLength,
      Value<BudgetReoccurence?>? reoccurrence,
      Value<DateTime?>? endDate,
      Value<bool?>? upcomingTransactionNotification,
      Value<TransactionSpecialType?>? type,
      Value<bool>? paid,
      Value<bool?>? createdAnotherFutureTransaction,
      Value<bool>? skipPaid,
      Value<MethodAdded?>? methodAdded,
      Value<String?>? transactionOwnerEmail,
      Value<String?>? transactionOriginalOwnerEmail,
      Value<String?>? sharedKey,
      Value<String?>? sharedOldKey,
      Value<SharedStatus?>? sharedStatus,
      Value<DateTime?>? sharedDateUpdated,
      Value<String?>? sharedReferenceBudgetPk,
      Value<String?>? objectiveFk,
      Value<String?>? objectiveLoanFk,
      Value<List<String>?>? budgetFksExclude,
      Value<String?>? payeeFk,
      Value<double?>? foreignAmount,
      Value<String?>? foreignCurrency,
      Value<String?>? splitGroupFk,
      Value<int?>? splitOrder,
      Value<FireflyTransactionType?>? fireflyType,
      Value<String?>? billFk,
      Value<bool>? reconciled,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      transactionPk: transactionPk ?? this.transactionPk,
      pairedTransactionFk: pairedTransactionFk ?? this.pairedTransactionFk,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      categoryFk: categoryFk ?? this.categoryFk,
      subCategoryFk: subCategoryFk ?? this.subCategoryFk,
      walletFk: walletFk ?? this.walletFk,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      originalDateDue: originalDateDue ?? this.originalDateDue,
      income: income ?? this.income,
      periodLength: periodLength ?? this.periodLength,
      reoccurrence: reoccurrence ?? this.reoccurrence,
      endDate: endDate ?? this.endDate,
      upcomingTransactionNotification: upcomingTransactionNotification ??
          this.upcomingTransactionNotification,
      type: type ?? this.type,
      paid: paid ?? this.paid,
      createdAnotherFutureTransaction: createdAnotherFutureTransaction ??
          this.createdAnotherFutureTransaction,
      skipPaid: skipPaid ?? this.skipPaid,
      methodAdded: methodAdded ?? this.methodAdded,
      transactionOwnerEmail:
          transactionOwnerEmail ?? this.transactionOwnerEmail,
      transactionOriginalOwnerEmail:
          transactionOriginalOwnerEmail ?? this.transactionOriginalOwnerEmail,
      sharedKey: sharedKey ?? this.sharedKey,
      sharedOldKey: sharedOldKey ?? this.sharedOldKey,
      sharedStatus: sharedStatus ?? this.sharedStatus,
      sharedDateUpdated: sharedDateUpdated ?? this.sharedDateUpdated,
      sharedReferenceBudgetPk:
          sharedReferenceBudgetPk ?? this.sharedReferenceBudgetPk,
      objectiveFk: objectiveFk ?? this.objectiveFk,
      objectiveLoanFk: objectiveLoanFk ?? this.objectiveLoanFk,
      budgetFksExclude: budgetFksExclude ?? this.budgetFksExclude,
      payeeFk: payeeFk ?? this.payeeFk,
      foreignAmount: foreignAmount ?? this.foreignAmount,
      foreignCurrency: foreignCurrency ?? this.foreignCurrency,
      splitGroupFk: splitGroupFk ?? this.splitGroupFk,
      splitOrder: splitOrder ?? this.splitOrder,
      fireflyType: fireflyType ?? this.fireflyType,
      billFk: billFk ?? this.billFk,
      reconciled: reconciled ?? this.reconciled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionPk.present) {
      map['transaction_pk'] = Variable<String>(transactionPk.value);
    }
    if (pairedTransactionFk.present) {
      map['paired_transaction_fk'] =
          Variable<String>(pairedTransactionFk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (categoryFk.present) {
      map['category_fk'] = Variable<String>(categoryFk.value);
    }
    if (subCategoryFk.present) {
      map['sub_category_fk'] = Variable<String>(subCategoryFk.value);
    }
    if (walletFk.present) {
      map['wallet_fk'] = Variable<String>(walletFk.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (originalDateDue.present) {
      map['original_date_due'] = Variable<DateTime>(originalDateDue.value);
    }
    if (income.present) {
      map['income'] = Variable<bool>(income.value);
    }
    if (periodLength.present) {
      map['period_length'] = Variable<int>(periodLength.value);
    }
    if (reoccurrence.present) {
      map['reoccurrence'] = Variable<int>(
          $TransactionsTable.$converterreoccurrencen.toSql(reoccurrence.value));
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (upcomingTransactionNotification.present) {
      map['upcoming_transaction_notification'] =
          Variable<bool>(upcomingTransactionNotification.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($TransactionsTable.$convertertypen.toSql(type.value));
    }
    if (paid.present) {
      map['paid'] = Variable<bool>(paid.value);
    }
    if (createdAnotherFutureTransaction.present) {
      map['created_another_future_transaction'] =
          Variable<bool>(createdAnotherFutureTransaction.value);
    }
    if (skipPaid.present) {
      map['skip_paid'] = Variable<bool>(skipPaid.value);
    }
    if (methodAdded.present) {
      map['method_added'] = Variable<int>(
          $TransactionsTable.$convertermethodAddedn.toSql(methodAdded.value));
    }
    if (transactionOwnerEmail.present) {
      map['transaction_owner_email'] =
          Variable<String>(transactionOwnerEmail.value);
    }
    if (transactionOriginalOwnerEmail.present) {
      map['transaction_original_owner_email'] =
          Variable<String>(transactionOriginalOwnerEmail.value);
    }
    if (sharedKey.present) {
      map['shared_key'] = Variable<String>(sharedKey.value);
    }
    if (sharedOldKey.present) {
      map['shared_old_key'] = Variable<String>(sharedOldKey.value);
    }
    if (sharedStatus.present) {
      map['shared_status'] = Variable<int>(
          $TransactionsTable.$convertersharedStatusn.toSql(sharedStatus.value));
    }
    if (sharedDateUpdated.present) {
      map['shared_date_updated'] = Variable<DateTime>(sharedDateUpdated.value);
    }
    if (sharedReferenceBudgetPk.present) {
      map['shared_reference_budget_pk'] =
          Variable<String>(sharedReferenceBudgetPk.value);
    }
    if (objectiveFk.present) {
      map['objective_fk'] = Variable<String>(objectiveFk.value);
    }
    if (objectiveLoanFk.present) {
      map['objective_loan_fk'] = Variable<String>(objectiveLoanFk.value);
    }
    if (budgetFksExclude.present) {
      map['budget_fks_exclude'] = Variable<String>($TransactionsTable
          .$converterbudgetFksExcluden
          .toSql(budgetFksExclude.value));
    }
    if (payeeFk.present) {
      map['payee_fk'] = Variable<String>(payeeFk.value);
    }
    if (foreignAmount.present) {
      map['foreign_amount'] = Variable<double>(foreignAmount.value);
    }
    if (foreignCurrency.present) {
      map['foreign_currency'] = Variable<String>(foreignCurrency.value);
    }
    if (splitGroupFk.present) {
      map['split_group_fk'] = Variable<String>(splitGroupFk.value);
    }
    if (splitOrder.present) {
      map['split_order'] = Variable<int>(splitOrder.value);
    }
    if (fireflyType.present) {
      map['firefly_type'] = Variable<int>(
          $TransactionsTable.$converterfireflyTypen.toSql(fireflyType.value));
    }
    if (billFk.present) {
      map['bill_fk'] = Variable<String>(billFk.value);
    }
    if (reconciled.present) {
      map['reconciled'] = Variable<bool>(reconciled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('transactionPk: $transactionPk, ')
          ..write('pairedTransactionFk: $pairedTransactionFk, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('categoryFk: $categoryFk, ')
          ..write('subCategoryFk: $subCategoryFk, ')
          ..write('walletFk: $walletFk, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('originalDateDue: $originalDateDue, ')
          ..write('income: $income, ')
          ..write('periodLength: $periodLength, ')
          ..write('reoccurrence: $reoccurrence, ')
          ..write('endDate: $endDate, ')
          ..write(
              'upcomingTransactionNotification: $upcomingTransactionNotification, ')
          ..write('type: $type, ')
          ..write('paid: $paid, ')
          ..write(
              'createdAnotherFutureTransaction: $createdAnotherFutureTransaction, ')
          ..write('skipPaid: $skipPaid, ')
          ..write('methodAdded: $methodAdded, ')
          ..write('transactionOwnerEmail: $transactionOwnerEmail, ')
          ..write(
              'transactionOriginalOwnerEmail: $transactionOriginalOwnerEmail, ')
          ..write('sharedKey: $sharedKey, ')
          ..write('sharedOldKey: $sharedOldKey, ')
          ..write('sharedStatus: $sharedStatus, ')
          ..write('sharedDateUpdated: $sharedDateUpdated, ')
          ..write('sharedReferenceBudgetPk: $sharedReferenceBudgetPk, ')
          ..write('objectiveFk: $objectiveFk, ')
          ..write('objectiveLoanFk: $objectiveLoanFk, ')
          ..write('budgetFksExclude: $budgetFksExclude, ')
          ..write('payeeFk: $payeeFk, ')
          ..write('foreignAmount: $foreignAmount, ')
          ..write('foreignCurrency: $foreignCurrency, ')
          ..write('splitGroupFk: $splitGroupFk, ')
          ..write('splitOrder: $splitOrder, ')
          ..write('fireflyType: $fireflyType, ')
          ..write('billFk: $billFk, ')
          ..write('reconciled: $reconciled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _budgetPkMeta =
      const VerificationMeta('budgetPk');
  @override
  late final GeneratedColumn<String> budgetPk = GeneratedColumn<String>(
      'budget_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
      'colour', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _walletFksMeta =
      const VerificationMeta('walletFks');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String> walletFks =
      GeneratedColumn<String>('wallet_fks', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>($BudgetsTable.$converterwalletFksn);
  static const VerificationMeta _categoryFksMeta =
      const VerificationMeta('categoryFks');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
      categoryFks = GeneratedColumn<String>('category_fks', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>($BudgetsTable.$convertercategoryFksn);
  static const VerificationMeta _categoryFksExcludeMeta =
      const VerificationMeta('categoryFksExclude');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
      categoryFksExclude = GeneratedColumn<String>(
              'category_fks_exclude', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>(
              $BudgetsTable.$convertercategoryFksExcluden);
  static const VerificationMeta _incomeMeta = const VerificationMeta('income');
  @override
  late final GeneratedColumn<bool> income = GeneratedColumn<bool>(
      'income', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("income" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _addedTransactionsOnlyMeta =
      const VerificationMeta('addedTransactionsOnly');
  @override
  late final GeneratedColumn<bool> addedTransactionsOnly =
      GeneratedColumn<bool>('added_transactions_only', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("added_transactions_only" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _periodLengthMeta =
      const VerificationMeta('periodLength');
  @override
  late final GeneratedColumn<int> periodLength = GeneratedColumn<int>(
      'period_length', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reoccurrenceMeta =
      const VerificationMeta('reoccurrence');
  @override
  late final GeneratedColumnWithTypeConverter<BudgetReoccurence?, int>
      reoccurrence = GeneratedColumn<int>('reoccurrence', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<BudgetReoccurence?>(
              $BudgetsTable.$converterreoccurrencen);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => new DateTime.now());
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _walletFkMeta =
      const VerificationMeta('walletFk');
  @override
  late final GeneratedColumn<String> walletFk = GeneratedColumn<String>(
      'wallet_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (wallet_pk)'),
      defaultValue: const Constant("0"));
  static const VerificationMeta _budgetTransactionFiltersMeta =
      const VerificationMeta('budgetTransactionFilters');
  @override
  late final GeneratedColumnWithTypeConverter<List<BudgetTransactionFilters>?,
      String> budgetTransactionFilters = GeneratedColumn<String>(
          'budget_transaction_filters', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(null))
      .withConverter<List<BudgetTransactionFilters>?>(
          $BudgetsTable.$converterbudgetTransactionFiltersn);
  static const VerificationMeta _memberTransactionFiltersMeta =
      const VerificationMeta('memberTransactionFilters');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
      memberTransactionFilters = GeneratedColumn<String>(
              'member_transaction_filters', aliasedName, true,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant(null))
          .withConverter<List<String>?>(
              $BudgetsTable.$convertermemberTransactionFiltersn);
  static const VerificationMeta _sharedKeyMeta =
      const VerificationMeta('sharedKey');
  @override
  late final GeneratedColumn<String> sharedKey = GeneratedColumn<String>(
      'shared_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sharedOwnerMemberMeta =
      const VerificationMeta('sharedOwnerMember');
  @override
  late final GeneratedColumnWithTypeConverter<SharedOwnerMember?, int>
      sharedOwnerMember = GeneratedColumn<int>(
              'shared_owner_member', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<SharedOwnerMember?>(
              $BudgetsTable.$convertersharedOwnerMembern);
  static const VerificationMeta _sharedDateUpdatedMeta =
      const VerificationMeta('sharedDateUpdated');
  @override
  late final GeneratedColumn<DateTime> sharedDateUpdated =
      GeneratedColumn<DateTime>('shared_date_updated', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sharedMembersMeta =
      const VerificationMeta('sharedMembers');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
      sharedMembers = GeneratedColumn<String>(
              'shared_members', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>($BudgetsTable.$convertersharedMembersn);
  static const VerificationMeta _sharedAllMembersEverMeta =
      const VerificationMeta('sharedAllMembersEver');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
      sharedAllMembersEver = GeneratedColumn<String>(
              'shared_all_members_ever', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>(
              $BudgetsTable.$convertersharedAllMembersEvern);
  static const VerificationMeta _isAbsoluteSpendingLimitMeta =
      const VerificationMeta('isAbsoluteSpendingLimit');
  @override
  late final GeneratedColumn<bool> isAbsoluteSpendingLimit =
      GeneratedColumn<bool>('is_absolute_spending_limit', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("is_absolute_spending_limit" IN (0, 1))'),
          defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        budgetPk,
        name,
        amount,
        colour,
        startDate,
        endDate,
        walletFks,
        categoryFks,
        categoryFksExclude,
        income,
        archived,
        addedTransactionsOnly,
        periodLength,
        reoccurrence,
        dateCreated,
        dateTimeModified,
        pinned,
        order,
        walletFk,
        budgetTransactionFilters,
        memberTransactionFilters,
        sharedKey,
        sharedOwnerMember,
        sharedDateUpdated,
        sharedMembers,
        sharedAllMembersEver,
        isAbsoluteSpendingLimit
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('budget_pk')) {
      context.handle(_budgetPkMeta,
          budgetPk.isAcceptableOrUnknown(data['budget_pk']!, _budgetPkMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('colour')) {
      context.handle(_colourMeta,
          colour.isAcceptableOrUnknown(data['colour']!, _colourMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    context.handle(_walletFksMeta, const VerificationResult.success());
    context.handle(_categoryFksMeta, const VerificationResult.success());
    context.handle(_categoryFksExcludeMeta, const VerificationResult.success());
    if (data.containsKey('income')) {
      context.handle(_incomeMeta,
          income.isAcceptableOrUnknown(data['income']!, _incomeMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('added_transactions_only')) {
      context.handle(
          _addedTransactionsOnlyMeta,
          addedTransactionsOnly.isAcceptableOrUnknown(
              data['added_transactions_only']!, _addedTransactionsOnlyMeta));
    }
    if (data.containsKey('period_length')) {
      context.handle(
          _periodLengthMeta,
          periodLength.isAcceptableOrUnknown(
              data['period_length']!, _periodLengthMeta));
    } else if (isInserting) {
      context.missing(_periodLengthMeta);
    }
    context.handle(_reoccurrenceMeta, const VerificationResult.success());
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('wallet_fk')) {
      context.handle(_walletFkMeta,
          walletFk.isAcceptableOrUnknown(data['wallet_fk']!, _walletFkMeta));
    }
    context.handle(
        _budgetTransactionFiltersMeta, const VerificationResult.success());
    context.handle(
        _memberTransactionFiltersMeta, const VerificationResult.success());
    if (data.containsKey('shared_key')) {
      context.handle(_sharedKeyMeta,
          sharedKey.isAcceptableOrUnknown(data['shared_key']!, _sharedKeyMeta));
    }
    context.handle(_sharedOwnerMemberMeta, const VerificationResult.success());
    if (data.containsKey('shared_date_updated')) {
      context.handle(
          _sharedDateUpdatedMeta,
          sharedDateUpdated.isAcceptableOrUnknown(
              data['shared_date_updated']!, _sharedDateUpdatedMeta));
    }
    context.handle(_sharedMembersMeta, const VerificationResult.success());
    context.handle(
        _sharedAllMembersEverMeta, const VerificationResult.success());
    if (data.containsKey('is_absolute_spending_limit')) {
      context.handle(
          _isAbsoluteSpendingLimitMeta,
          isAbsoluteSpendingLimit.isAcceptableOrUnknown(
              data['is_absolute_spending_limit']!,
              _isAbsoluteSpendingLimitMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {budgetPk};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      budgetPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}budget_pk'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      colour: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}colour']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date'])!,
      walletFks: $BudgetsTable.$converterwalletFksn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wallet_fks'])),
      categoryFks: $BudgetsTable.$convertercategoryFksn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_fks'])),
      categoryFksExclude: $BudgetsTable.$convertercategoryFksExcluden.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}category_fks_exclude'])),
      income: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}income'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      addedTransactionsOnly: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}added_transactions_only'])!,
      periodLength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_length'])!,
      reoccurrence: $BudgetsTable.$converterreoccurrencen.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}reoccurrence'])),
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      walletFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wallet_fk'])!,
      budgetTransactionFilters: $BudgetsTable
          .$converterbudgetTransactionFiltersn
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}budget_transaction_filters'])),
      memberTransactionFilters: $BudgetsTable
          .$convertermemberTransactionFiltersn
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}member_transaction_filters'])),
      sharedKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shared_key']),
      sharedOwnerMember: $BudgetsTable.$convertersharedOwnerMembern.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}shared_owner_member'])),
      sharedDateUpdated: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}shared_date_updated']),
      sharedMembers: $BudgetsTable.$convertersharedMembersn.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}shared_members'])),
      sharedAllMembersEver: $BudgetsTable.$convertersharedAllMembersEvern
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}shared_all_members_ever'])),
      isAbsoluteSpendingLimit: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}is_absolute_spending_limit'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterwalletFks =
      const StringListInColumnConverter();
  static TypeConverter<List<String>?, String?> $converterwalletFksn =
      NullAwareTypeConverter.wrap($converterwalletFks);
  static TypeConverter<List<String>, String> $convertercategoryFks =
      const StringListInColumnConverter();
  static TypeConverter<List<String>?, String?> $convertercategoryFksn =
      NullAwareTypeConverter.wrap($convertercategoryFks);
  static TypeConverter<List<String>, String> $convertercategoryFksExclude =
      const StringListInColumnConverter();
  static TypeConverter<List<String>?, String?> $convertercategoryFksExcluden =
      NullAwareTypeConverter.wrap($convertercategoryFksExclude);
  static JsonTypeConverter2<BudgetReoccurence, int, int>
      $converterreoccurrence =
      const EnumIndexConverter<BudgetReoccurence>(BudgetReoccurence.values);
  static JsonTypeConverter2<BudgetReoccurence?, int?, int?>
      $converterreoccurrencen =
      JsonTypeConverter2.asNullable($converterreoccurrence);
  static TypeConverter<List<BudgetTransactionFilters>, String>
      $converterbudgetTransactionFilters =
      const BudgetTransactionFiltersListInColumnConverter();
  static TypeConverter<List<BudgetTransactionFilters>?, String?>
      $converterbudgetTransactionFiltersn =
      NullAwareTypeConverter.wrap($converterbudgetTransactionFilters);
  static TypeConverter<List<String>, String>
      $convertermemberTransactionFilters = const StringListInColumnConverter();
  static TypeConverter<List<String>?, String?>
      $convertermemberTransactionFiltersn =
      NullAwareTypeConverter.wrap($convertermemberTransactionFilters);
  static JsonTypeConverter2<SharedOwnerMember, int, int>
      $convertersharedOwnerMember =
      const EnumIndexConverter<SharedOwnerMember>(SharedOwnerMember.values);
  static JsonTypeConverter2<SharedOwnerMember?, int?, int?>
      $convertersharedOwnerMembern =
      JsonTypeConverter2.asNullable($convertersharedOwnerMember);
  static TypeConverter<List<String>, String> $convertersharedMembers =
      const StringListInColumnConverter();
  static TypeConverter<List<String>?, String?> $convertersharedMembersn =
      NullAwareTypeConverter.wrap($convertersharedMembers);
  static TypeConverter<List<String>, String> $convertersharedAllMembersEver =
      const StringListInColumnConverter();
  static TypeConverter<List<String>?, String?> $convertersharedAllMembersEvern =
      NullAwareTypeConverter.wrap($convertersharedAllMembersEver);
}

class Budget extends DataClass implements Insertable<Budget> {
  final String budgetPk;
  final String name;
  final double amount;
  final String? colour;
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? walletFks;
  final List<String>? categoryFks;
  final List<String>? categoryFksExclude;
  final bool income;
  final bool archived;
  final bool addedTransactionsOnly;
  final int periodLength;
  final BudgetReoccurence? reoccurrence;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  final bool pinned;
  final int order;
  final String walletFk;
  final List<BudgetTransactionFilters>? budgetTransactionFilters;
  final List<String>? memberTransactionFilters;
  final String? sharedKey;
  final SharedOwnerMember? sharedOwnerMember;
  final DateTime? sharedDateUpdated;
  final List<String>? sharedMembers;
  final List<String>? sharedAllMembersEver;
  final bool isAbsoluteSpendingLimit;
  const Budget(
      {required this.budgetPk,
      required this.name,
      required this.amount,
      this.colour,
      required this.startDate,
      required this.endDate,
      this.walletFks,
      this.categoryFks,
      this.categoryFksExclude,
      required this.income,
      required this.archived,
      required this.addedTransactionsOnly,
      required this.periodLength,
      this.reoccurrence,
      required this.dateCreated,
      this.dateTimeModified,
      required this.pinned,
      required this.order,
      required this.walletFk,
      this.budgetTransactionFilters,
      this.memberTransactionFilters,
      this.sharedKey,
      this.sharedOwnerMember,
      this.sharedDateUpdated,
      this.sharedMembers,
      this.sharedAllMembersEver,
      required this.isAbsoluteSpendingLimit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['budget_pk'] = Variable<String>(budgetPk);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || colour != null) {
      map['colour'] = Variable<String>(colour);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    if (!nullToAbsent || walletFks != null) {
      map['wallet_fks'] =
          Variable<String>($BudgetsTable.$converterwalletFksn.toSql(walletFks));
    }
    if (!nullToAbsent || categoryFks != null) {
      map['category_fks'] = Variable<String>(
          $BudgetsTable.$convertercategoryFksn.toSql(categoryFks));
    }
    if (!nullToAbsent || categoryFksExclude != null) {
      map['category_fks_exclude'] = Variable<String>($BudgetsTable
          .$convertercategoryFksExcluden
          .toSql(categoryFksExclude));
    }
    map['income'] = Variable<bool>(income);
    map['archived'] = Variable<bool>(archived);
    map['added_transactions_only'] = Variable<bool>(addedTransactionsOnly);
    map['period_length'] = Variable<int>(periodLength);
    if (!nullToAbsent || reoccurrence != null) {
      map['reoccurrence'] = Variable<int>(
          $BudgetsTable.$converterreoccurrencen.toSql(reoccurrence));
    }
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    map['pinned'] = Variable<bool>(pinned);
    map['order'] = Variable<int>(order);
    map['wallet_fk'] = Variable<String>(walletFk);
    if (!nullToAbsent || budgetTransactionFilters != null) {
      map['budget_transaction_filters'] = Variable<String>($BudgetsTable
          .$converterbudgetTransactionFiltersn
          .toSql(budgetTransactionFilters));
    }
    if (!nullToAbsent || memberTransactionFilters != null) {
      map['member_transaction_filters'] = Variable<String>($BudgetsTable
          .$convertermemberTransactionFiltersn
          .toSql(memberTransactionFilters));
    }
    if (!nullToAbsent || sharedKey != null) {
      map['shared_key'] = Variable<String>(sharedKey);
    }
    if (!nullToAbsent || sharedOwnerMember != null) {
      map['shared_owner_member'] = Variable<int>(
          $BudgetsTable.$convertersharedOwnerMembern.toSql(sharedOwnerMember));
    }
    if (!nullToAbsent || sharedDateUpdated != null) {
      map['shared_date_updated'] = Variable<DateTime>(sharedDateUpdated);
    }
    if (!nullToAbsent || sharedMembers != null) {
      map['shared_members'] = Variable<String>(
          $BudgetsTable.$convertersharedMembersn.toSql(sharedMembers));
    }
    if (!nullToAbsent || sharedAllMembersEver != null) {
      map['shared_all_members_ever'] = Variable<String>($BudgetsTable
          .$convertersharedAllMembersEvern
          .toSql(sharedAllMembersEver));
    }
    map['is_absolute_spending_limit'] = Variable<bool>(isAbsoluteSpendingLimit);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      budgetPk: Value(budgetPk),
      name: Value(name),
      amount: Value(amount),
      colour:
          colour == null && nullToAbsent ? const Value.absent() : Value(colour),
      startDate: Value(startDate),
      endDate: Value(endDate),
      walletFks: walletFks == null && nullToAbsent
          ? const Value.absent()
          : Value(walletFks),
      categoryFks: categoryFks == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryFks),
      categoryFksExclude: categoryFksExclude == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryFksExclude),
      income: Value(income),
      archived: Value(archived),
      addedTransactionsOnly: Value(addedTransactionsOnly),
      periodLength: Value(periodLength),
      reoccurrence: reoccurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(reoccurrence),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
      pinned: Value(pinned),
      order: Value(order),
      walletFk: Value(walletFk),
      budgetTransactionFilters: budgetTransactionFilters == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetTransactionFilters),
      memberTransactionFilters: memberTransactionFilters == null && nullToAbsent
          ? const Value.absent()
          : Value(memberTransactionFilters),
      sharedKey: sharedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedKey),
      sharedOwnerMember: sharedOwnerMember == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedOwnerMember),
      sharedDateUpdated: sharedDateUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedDateUpdated),
      sharedMembers: sharedMembers == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedMembers),
      sharedAllMembersEver: sharedAllMembersEver == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedAllMembersEver),
      isAbsoluteSpendingLimit: Value(isAbsoluteSpendingLimit),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      budgetPk: serializer.fromJson<String>(json['budgetPk']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      colour: serializer.fromJson<String?>(json['colour']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      walletFks: serializer.fromJson<List<String>?>(json['walletFks']),
      categoryFks: serializer.fromJson<List<String>?>(json['categoryFks']),
      categoryFksExclude:
          serializer.fromJson<List<String>?>(json['categoryFksExclude']),
      income: serializer.fromJson<bool>(json['income']),
      archived: serializer.fromJson<bool>(json['archived']),
      addedTransactionsOnly:
          serializer.fromJson<bool>(json['addedTransactionsOnly']),
      periodLength: serializer.fromJson<int>(json['periodLength']),
      reoccurrence: $BudgetsTable.$converterreoccurrencen
          .fromJson(serializer.fromJson<int?>(json['reoccurrence'])),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      order: serializer.fromJson<int>(json['order']),
      walletFk: serializer.fromJson<String>(json['walletFk']),
      budgetTransactionFilters:
          serializer.fromJson<List<BudgetTransactionFilters>?>(
              json['budgetTransactionFilters']),
      memberTransactionFilters:
          serializer.fromJson<List<String>?>(json['memberTransactionFilters']),
      sharedKey: serializer.fromJson<String?>(json['sharedKey']),
      sharedOwnerMember: $BudgetsTable.$convertersharedOwnerMembern
          .fromJson(serializer.fromJson<int?>(json['sharedOwnerMember'])),
      sharedDateUpdated:
          serializer.fromJson<DateTime?>(json['sharedDateUpdated']),
      sharedMembers: serializer.fromJson<List<String>?>(json['sharedMembers']),
      sharedAllMembersEver:
          serializer.fromJson<List<String>?>(json['sharedAllMembersEver']),
      isAbsoluteSpendingLimit:
          serializer.fromJson<bool>(json['isAbsoluteSpendingLimit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'budgetPk': serializer.toJson<String>(budgetPk),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'colour': serializer.toJson<String?>(colour),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'walletFks': serializer.toJson<List<String>?>(walletFks),
      'categoryFks': serializer.toJson<List<String>?>(categoryFks),
      'categoryFksExclude':
          serializer.toJson<List<String>?>(categoryFksExclude),
      'income': serializer.toJson<bool>(income),
      'archived': serializer.toJson<bool>(archived),
      'addedTransactionsOnly': serializer.toJson<bool>(addedTransactionsOnly),
      'periodLength': serializer.toJson<int>(periodLength),
      'reoccurrence': serializer.toJson<int?>(
          $BudgetsTable.$converterreoccurrencen.toJson(reoccurrence)),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
      'pinned': serializer.toJson<bool>(pinned),
      'order': serializer.toJson<int>(order),
      'walletFk': serializer.toJson<String>(walletFk),
      'budgetTransactionFilters': serializer
          .toJson<List<BudgetTransactionFilters>?>(budgetTransactionFilters),
      'memberTransactionFilters':
          serializer.toJson<List<String>?>(memberTransactionFilters),
      'sharedKey': serializer.toJson<String?>(sharedKey),
      'sharedOwnerMember': serializer.toJson<int?>(
          $BudgetsTable.$convertersharedOwnerMembern.toJson(sharedOwnerMember)),
      'sharedDateUpdated': serializer.toJson<DateTime?>(sharedDateUpdated),
      'sharedMembers': serializer.toJson<List<String>?>(sharedMembers),
      'sharedAllMembersEver':
          serializer.toJson<List<String>?>(sharedAllMembersEver),
      'isAbsoluteSpendingLimit':
          serializer.toJson<bool>(isAbsoluteSpendingLimit),
    };
  }

  Budget copyWith(
          {String? budgetPk,
          String? name,
          double? amount,
          Value<String?> colour = const Value.absent(),
          DateTime? startDate,
          DateTime? endDate,
          Value<List<String>?> walletFks = const Value.absent(),
          Value<List<String>?> categoryFks = const Value.absent(),
          Value<List<String>?> categoryFksExclude = const Value.absent(),
          bool? income,
          bool? archived,
          bool? addedTransactionsOnly,
          int? periodLength,
          Value<BudgetReoccurence?> reoccurrence = const Value.absent(),
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent(),
          bool? pinned,
          int? order,
          String? walletFk,
          Value<List<BudgetTransactionFilters>?> budgetTransactionFilters =
              const Value.absent(),
          Value<List<String>?> memberTransactionFilters = const Value.absent(),
          Value<String?> sharedKey = const Value.absent(),
          Value<SharedOwnerMember?> sharedOwnerMember = const Value.absent(),
          Value<DateTime?> sharedDateUpdated = const Value.absent(),
          Value<List<String>?> sharedMembers = const Value.absent(),
          Value<List<String>?> sharedAllMembersEver = const Value.absent(),
          bool? isAbsoluteSpendingLimit}) =>
      Budget(
        budgetPk: budgetPk ?? this.budgetPk,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        colour: colour.present ? colour.value : this.colour,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        walletFks: walletFks.present ? walletFks.value : this.walletFks,
        categoryFks: categoryFks.present ? categoryFks.value : this.categoryFks,
        categoryFksExclude: categoryFksExclude.present
            ? categoryFksExclude.value
            : this.categoryFksExclude,
        income: income ?? this.income,
        archived: archived ?? this.archived,
        addedTransactionsOnly:
            addedTransactionsOnly ?? this.addedTransactionsOnly,
        periodLength: periodLength ?? this.periodLength,
        reoccurrence:
            reoccurrence.present ? reoccurrence.value : this.reoccurrence,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
        pinned: pinned ?? this.pinned,
        order: order ?? this.order,
        walletFk: walletFk ?? this.walletFk,
        budgetTransactionFilters: budgetTransactionFilters.present
            ? budgetTransactionFilters.value
            : this.budgetTransactionFilters,
        memberTransactionFilters: memberTransactionFilters.present
            ? memberTransactionFilters.value
            : this.memberTransactionFilters,
        sharedKey: sharedKey.present ? sharedKey.value : this.sharedKey,
        sharedOwnerMember: sharedOwnerMember.present
            ? sharedOwnerMember.value
            : this.sharedOwnerMember,
        sharedDateUpdated: sharedDateUpdated.present
            ? sharedDateUpdated.value
            : this.sharedDateUpdated,
        sharedMembers:
            sharedMembers.present ? sharedMembers.value : this.sharedMembers,
        sharedAllMembersEver: sharedAllMembersEver.present
            ? sharedAllMembersEver.value
            : this.sharedAllMembersEver,
        isAbsoluteSpendingLimit:
            isAbsoluteSpendingLimit ?? this.isAbsoluteSpendingLimit,
      );
  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('budgetPk: $budgetPk, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('colour: $colour, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('walletFks: $walletFks, ')
          ..write('categoryFks: $categoryFks, ')
          ..write('categoryFksExclude: $categoryFksExclude, ')
          ..write('income: $income, ')
          ..write('archived: $archived, ')
          ..write('addedTransactionsOnly: $addedTransactionsOnly, ')
          ..write('periodLength: $periodLength, ')
          ..write('reoccurrence: $reoccurrence, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('pinned: $pinned, ')
          ..write('order: $order, ')
          ..write('walletFk: $walletFk, ')
          ..write('budgetTransactionFilters: $budgetTransactionFilters, ')
          ..write('memberTransactionFilters: $memberTransactionFilters, ')
          ..write('sharedKey: $sharedKey, ')
          ..write('sharedOwnerMember: $sharedOwnerMember, ')
          ..write('sharedDateUpdated: $sharedDateUpdated, ')
          ..write('sharedMembers: $sharedMembers, ')
          ..write('sharedAllMembersEver: $sharedAllMembersEver, ')
          ..write('isAbsoluteSpendingLimit: $isAbsoluteSpendingLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        budgetPk,
        name,
        amount,
        colour,
        startDate,
        endDate,
        walletFks,
        categoryFks,
        categoryFksExclude,
        income,
        archived,
        addedTransactionsOnly,
        periodLength,
        reoccurrence,
        dateCreated,
        dateTimeModified,
        pinned,
        order,
        walletFk,
        budgetTransactionFilters,
        memberTransactionFilters,
        sharedKey,
        sharedOwnerMember,
        sharedDateUpdated,
        sharedMembers,
        sharedAllMembersEver,
        isAbsoluteSpendingLimit
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.budgetPk == this.budgetPk &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.colour == this.colour &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.walletFks == this.walletFks &&
          other.categoryFks == this.categoryFks &&
          other.categoryFksExclude == this.categoryFksExclude &&
          other.income == this.income &&
          other.archived == this.archived &&
          other.addedTransactionsOnly == this.addedTransactionsOnly &&
          other.periodLength == this.periodLength &&
          other.reoccurrence == this.reoccurrence &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified &&
          other.pinned == this.pinned &&
          other.order == this.order &&
          other.walletFk == this.walletFk &&
          other.budgetTransactionFilters == this.budgetTransactionFilters &&
          other.memberTransactionFilters == this.memberTransactionFilters &&
          other.sharedKey == this.sharedKey &&
          other.sharedOwnerMember == this.sharedOwnerMember &&
          other.sharedDateUpdated == this.sharedDateUpdated &&
          other.sharedMembers == this.sharedMembers &&
          other.sharedAllMembersEver == this.sharedAllMembersEver &&
          other.isAbsoluteSpendingLimit == this.isAbsoluteSpendingLimit);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> budgetPk;
  final Value<String> name;
  final Value<double> amount;
  final Value<String?> colour;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<List<String>?> walletFks;
  final Value<List<String>?> categoryFks;
  final Value<List<String>?> categoryFksExclude;
  final Value<bool> income;
  final Value<bool> archived;
  final Value<bool> addedTransactionsOnly;
  final Value<int> periodLength;
  final Value<BudgetReoccurence?> reoccurrence;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<bool> pinned;
  final Value<int> order;
  final Value<String> walletFk;
  final Value<List<BudgetTransactionFilters>?> budgetTransactionFilters;
  final Value<List<String>?> memberTransactionFilters;
  final Value<String?> sharedKey;
  final Value<SharedOwnerMember?> sharedOwnerMember;
  final Value<DateTime?> sharedDateUpdated;
  final Value<List<String>?> sharedMembers;
  final Value<List<String>?> sharedAllMembersEver;
  final Value<bool> isAbsoluteSpendingLimit;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.budgetPk = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.colour = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.walletFks = const Value.absent(),
    this.categoryFks = const Value.absent(),
    this.categoryFksExclude = const Value.absent(),
    this.income = const Value.absent(),
    this.archived = const Value.absent(),
    this.addedTransactionsOnly = const Value.absent(),
    this.periodLength = const Value.absent(),
    this.reoccurrence = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.pinned = const Value.absent(),
    this.order = const Value.absent(),
    this.walletFk = const Value.absent(),
    this.budgetTransactionFilters = const Value.absent(),
    this.memberTransactionFilters = const Value.absent(),
    this.sharedKey = const Value.absent(),
    this.sharedOwnerMember = const Value.absent(),
    this.sharedDateUpdated = const Value.absent(),
    this.sharedMembers = const Value.absent(),
    this.sharedAllMembersEver = const Value.absent(),
    this.isAbsoluteSpendingLimit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.budgetPk = const Value.absent(),
    required String name,
    required double amount,
    this.colour = const Value.absent(),
    required DateTime startDate,
    required DateTime endDate,
    this.walletFks = const Value.absent(),
    this.categoryFks = const Value.absent(),
    this.categoryFksExclude = const Value.absent(),
    this.income = const Value.absent(),
    this.archived = const Value.absent(),
    this.addedTransactionsOnly = const Value.absent(),
    required int periodLength,
    this.reoccurrence = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.pinned = const Value.absent(),
    required int order,
    this.walletFk = const Value.absent(),
    this.budgetTransactionFilters = const Value.absent(),
    this.memberTransactionFilters = const Value.absent(),
    this.sharedKey = const Value.absent(),
    this.sharedOwnerMember = const Value.absent(),
    this.sharedDateUpdated = const Value.absent(),
    this.sharedMembers = const Value.absent(),
    this.sharedAllMembersEver = const Value.absent(),
    this.isAbsoluteSpendingLimit = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        amount = Value(amount),
        startDate = Value(startDate),
        endDate = Value(endDate),
        periodLength = Value(periodLength),
        order = Value(order);
  static Insertable<Budget> custom({
    Expression<String>? budgetPk,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? colour,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? walletFks,
    Expression<String>? categoryFks,
    Expression<String>? categoryFksExclude,
    Expression<bool>? income,
    Expression<bool>? archived,
    Expression<bool>? addedTransactionsOnly,
    Expression<int>? periodLength,
    Expression<int>? reoccurrence,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<bool>? pinned,
    Expression<int>? order,
    Expression<String>? walletFk,
    Expression<String>? budgetTransactionFilters,
    Expression<String>? memberTransactionFilters,
    Expression<String>? sharedKey,
    Expression<int>? sharedOwnerMember,
    Expression<DateTime>? sharedDateUpdated,
    Expression<String>? sharedMembers,
    Expression<String>? sharedAllMembersEver,
    Expression<bool>? isAbsoluteSpendingLimit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (budgetPk != null) 'budget_pk': budgetPk,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (colour != null) 'colour': colour,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (walletFks != null) 'wallet_fks': walletFks,
      if (categoryFks != null) 'category_fks': categoryFks,
      if (categoryFksExclude != null)
        'category_fks_exclude': categoryFksExclude,
      if (income != null) 'income': income,
      if (archived != null) 'archived': archived,
      if (addedTransactionsOnly != null)
        'added_transactions_only': addedTransactionsOnly,
      if (periodLength != null) 'period_length': periodLength,
      if (reoccurrence != null) 'reoccurrence': reoccurrence,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (pinned != null) 'pinned': pinned,
      if (order != null) 'order': order,
      if (walletFk != null) 'wallet_fk': walletFk,
      if (budgetTransactionFilters != null)
        'budget_transaction_filters': budgetTransactionFilters,
      if (memberTransactionFilters != null)
        'member_transaction_filters': memberTransactionFilters,
      if (sharedKey != null) 'shared_key': sharedKey,
      if (sharedOwnerMember != null) 'shared_owner_member': sharedOwnerMember,
      if (sharedDateUpdated != null) 'shared_date_updated': sharedDateUpdated,
      if (sharedMembers != null) 'shared_members': sharedMembers,
      if (sharedAllMembersEver != null)
        'shared_all_members_ever': sharedAllMembersEver,
      if (isAbsoluteSpendingLimit != null)
        'is_absolute_spending_limit': isAbsoluteSpendingLimit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? budgetPk,
      Value<String>? name,
      Value<double>? amount,
      Value<String?>? colour,
      Value<DateTime>? startDate,
      Value<DateTime>? endDate,
      Value<List<String>?>? walletFks,
      Value<List<String>?>? categoryFks,
      Value<List<String>?>? categoryFksExclude,
      Value<bool>? income,
      Value<bool>? archived,
      Value<bool>? addedTransactionsOnly,
      Value<int>? periodLength,
      Value<BudgetReoccurence?>? reoccurrence,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<bool>? pinned,
      Value<int>? order,
      Value<String>? walletFk,
      Value<List<BudgetTransactionFilters>?>? budgetTransactionFilters,
      Value<List<String>?>? memberTransactionFilters,
      Value<String?>? sharedKey,
      Value<SharedOwnerMember?>? sharedOwnerMember,
      Value<DateTime?>? sharedDateUpdated,
      Value<List<String>?>? sharedMembers,
      Value<List<String>?>? sharedAllMembersEver,
      Value<bool>? isAbsoluteSpendingLimit,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      budgetPk: budgetPk ?? this.budgetPk,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      colour: colour ?? this.colour,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      walletFks: walletFks ?? this.walletFks,
      categoryFks: categoryFks ?? this.categoryFks,
      categoryFksExclude: categoryFksExclude ?? this.categoryFksExclude,
      income: income ?? this.income,
      archived: archived ?? this.archived,
      addedTransactionsOnly:
          addedTransactionsOnly ?? this.addedTransactionsOnly,
      periodLength: periodLength ?? this.periodLength,
      reoccurrence: reoccurrence ?? this.reoccurrence,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      pinned: pinned ?? this.pinned,
      order: order ?? this.order,
      walletFk: walletFk ?? this.walletFk,
      budgetTransactionFilters:
          budgetTransactionFilters ?? this.budgetTransactionFilters,
      memberTransactionFilters:
          memberTransactionFilters ?? this.memberTransactionFilters,
      sharedKey: sharedKey ?? this.sharedKey,
      sharedOwnerMember: sharedOwnerMember ?? this.sharedOwnerMember,
      sharedDateUpdated: sharedDateUpdated ?? this.sharedDateUpdated,
      sharedMembers: sharedMembers ?? this.sharedMembers,
      sharedAllMembersEver: sharedAllMembersEver ?? this.sharedAllMembersEver,
      isAbsoluteSpendingLimit:
          isAbsoluteSpendingLimit ?? this.isAbsoluteSpendingLimit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (budgetPk.present) {
      map['budget_pk'] = Variable<String>(budgetPk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (walletFks.present) {
      map['wallet_fks'] = Variable<String>(
          $BudgetsTable.$converterwalletFksn.toSql(walletFks.value));
    }
    if (categoryFks.present) {
      map['category_fks'] = Variable<String>(
          $BudgetsTable.$convertercategoryFksn.toSql(categoryFks.value));
    }
    if (categoryFksExclude.present) {
      map['category_fks_exclude'] = Variable<String>($BudgetsTable
          .$convertercategoryFksExcluden
          .toSql(categoryFksExclude.value));
    }
    if (income.present) {
      map['income'] = Variable<bool>(income.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (addedTransactionsOnly.present) {
      map['added_transactions_only'] =
          Variable<bool>(addedTransactionsOnly.value);
    }
    if (periodLength.present) {
      map['period_length'] = Variable<int>(periodLength.value);
    }
    if (reoccurrence.present) {
      map['reoccurrence'] = Variable<int>(
          $BudgetsTable.$converterreoccurrencen.toSql(reoccurrence.value));
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (walletFk.present) {
      map['wallet_fk'] = Variable<String>(walletFk.value);
    }
    if (budgetTransactionFilters.present) {
      map['budget_transaction_filters'] = Variable<String>($BudgetsTable
          .$converterbudgetTransactionFiltersn
          .toSql(budgetTransactionFilters.value));
    }
    if (memberTransactionFilters.present) {
      map['member_transaction_filters'] = Variable<String>($BudgetsTable
          .$convertermemberTransactionFiltersn
          .toSql(memberTransactionFilters.value));
    }
    if (sharedKey.present) {
      map['shared_key'] = Variable<String>(sharedKey.value);
    }
    if (sharedOwnerMember.present) {
      map['shared_owner_member'] = Variable<int>($BudgetsTable
          .$convertersharedOwnerMembern
          .toSql(sharedOwnerMember.value));
    }
    if (sharedDateUpdated.present) {
      map['shared_date_updated'] = Variable<DateTime>(sharedDateUpdated.value);
    }
    if (sharedMembers.present) {
      map['shared_members'] = Variable<String>(
          $BudgetsTable.$convertersharedMembersn.toSql(sharedMembers.value));
    }
    if (sharedAllMembersEver.present) {
      map['shared_all_members_ever'] = Variable<String>($BudgetsTable
          .$convertersharedAllMembersEvern
          .toSql(sharedAllMembersEver.value));
    }
    if (isAbsoluteSpendingLimit.present) {
      map['is_absolute_spending_limit'] =
          Variable<bool>(isAbsoluteSpendingLimit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('budgetPk: $budgetPk, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('colour: $colour, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('walletFks: $walletFks, ')
          ..write('categoryFks: $categoryFks, ')
          ..write('categoryFksExclude: $categoryFksExclude, ')
          ..write('income: $income, ')
          ..write('archived: $archived, ')
          ..write('addedTransactionsOnly: $addedTransactionsOnly, ')
          ..write('periodLength: $periodLength, ')
          ..write('reoccurrence: $reoccurrence, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('pinned: $pinned, ')
          ..write('order: $order, ')
          ..write('walletFk: $walletFk, ')
          ..write('budgetTransactionFilters: $budgetTransactionFilters, ')
          ..write('memberTransactionFilters: $memberTransactionFilters, ')
          ..write('sharedKey: $sharedKey, ')
          ..write('sharedOwnerMember: $sharedOwnerMember, ')
          ..write('sharedDateUpdated: $sharedDateUpdated, ')
          ..write('sharedMembers: $sharedMembers, ')
          ..write('sharedAllMembersEver: $sharedAllMembersEver, ')
          ..write('isAbsoluteSpendingLimit: $isAbsoluteSpendingLimit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryBudgetLimitsTable extends CategoryBudgetLimits
    with TableInfo<$CategoryBudgetLimitsTable, CategoryBudgetLimit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryBudgetLimitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryLimitPkMeta =
      const VerificationMeta('categoryLimitPk');
  @override
  late final GeneratedColumn<String> categoryLimitPk = GeneratedColumn<String>(
      'category_limit_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _categoryFkMeta =
      const VerificationMeta('categoryFk');
  @override
  late final GeneratedColumn<String> categoryFk = GeneratedColumn<String>(
      'category_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (category_pk)'));
  static const VerificationMeta _budgetFkMeta =
      const VerificationMeta('budgetFk');
  @override
  late final GeneratedColumn<String> budgetFk = GeneratedColumn<String>(
      'budget_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES budgets (budget_pk)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _walletFkMeta =
      const VerificationMeta('walletFk');
  @override
  late final GeneratedColumn<String> walletFk = GeneratedColumn<String>(
      'wallet_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (wallet_pk)'),
      defaultValue: const Constant("0"));
  @override
  List<GeneratedColumn> get $columns => [
        categoryLimitPk,
        categoryFk,
        budgetFk,
        amount,
        dateTimeModified,
        walletFk
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_budget_limits';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoryBudgetLimit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_limit_pk')) {
      context.handle(
          _categoryLimitPkMeta,
          categoryLimitPk.isAcceptableOrUnknown(
              data['category_limit_pk']!, _categoryLimitPkMeta));
    }
    if (data.containsKey('category_fk')) {
      context.handle(
          _categoryFkMeta,
          categoryFk.isAcceptableOrUnknown(
              data['category_fk']!, _categoryFkMeta));
    } else if (isInserting) {
      context.missing(_categoryFkMeta);
    }
    if (data.containsKey('budget_fk')) {
      context.handle(_budgetFkMeta,
          budgetFk.isAcceptableOrUnknown(data['budget_fk']!, _budgetFkMeta));
    } else if (isInserting) {
      context.missing(_budgetFkMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    if (data.containsKey('wallet_fk')) {
      context.handle(_walletFkMeta,
          walletFk.isAcceptableOrUnknown(data['wallet_fk']!, _walletFkMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {categoryLimitPk};
  @override
  CategoryBudgetLimit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryBudgetLimit(
      categoryLimitPk: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_limit_pk'])!,
      categoryFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_fk'])!,
      budgetFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}budget_fk'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
      walletFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wallet_fk'])!,
    );
  }

  @override
  $CategoryBudgetLimitsTable createAlias(String alias) {
    return $CategoryBudgetLimitsTable(attachedDatabase, alias);
  }
}

class CategoryBudgetLimit extends DataClass
    implements Insertable<CategoryBudgetLimit> {
  final String categoryLimitPk;
  final String categoryFk;
  final String budgetFk;
  final double amount;
  final DateTime? dateTimeModified;
  final String walletFk;
  const CategoryBudgetLimit(
      {required this.categoryLimitPk,
      required this.categoryFk,
      required this.budgetFk,
      required this.amount,
      this.dateTimeModified,
      required this.walletFk});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_limit_pk'] = Variable<String>(categoryLimitPk);
    map['category_fk'] = Variable<String>(categoryFk);
    map['budget_fk'] = Variable<String>(budgetFk);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    map['wallet_fk'] = Variable<String>(walletFk);
    return map;
  }

  CategoryBudgetLimitsCompanion toCompanion(bool nullToAbsent) {
    return CategoryBudgetLimitsCompanion(
      categoryLimitPk: Value(categoryLimitPk),
      categoryFk: Value(categoryFk),
      budgetFk: Value(budgetFk),
      amount: Value(amount),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
      walletFk: Value(walletFk),
    );
  }

  factory CategoryBudgetLimit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryBudgetLimit(
      categoryLimitPk: serializer.fromJson<String>(json['categoryLimitPk']),
      categoryFk: serializer.fromJson<String>(json['categoryFk']),
      budgetFk: serializer.fromJson<String>(json['budgetFk']),
      amount: serializer.fromJson<double>(json['amount']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
      walletFk: serializer.fromJson<String>(json['walletFk']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryLimitPk': serializer.toJson<String>(categoryLimitPk),
      'categoryFk': serializer.toJson<String>(categoryFk),
      'budgetFk': serializer.toJson<String>(budgetFk),
      'amount': serializer.toJson<double>(amount),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
      'walletFk': serializer.toJson<String>(walletFk),
    };
  }

  CategoryBudgetLimit copyWith(
          {String? categoryLimitPk,
          String? categoryFk,
          String? budgetFk,
          double? amount,
          Value<DateTime?> dateTimeModified = const Value.absent(),
          String? walletFk}) =>
      CategoryBudgetLimit(
        categoryLimitPk: categoryLimitPk ?? this.categoryLimitPk,
        categoryFk: categoryFk ?? this.categoryFk,
        budgetFk: budgetFk ?? this.budgetFk,
        amount: amount ?? this.amount,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
        walletFk: walletFk ?? this.walletFk,
      );
  @override
  String toString() {
    return (StringBuffer('CategoryBudgetLimit(')
          ..write('categoryLimitPk: $categoryLimitPk, ')
          ..write('categoryFk: $categoryFk, ')
          ..write('budgetFk: $budgetFk, ')
          ..write('amount: $amount, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('walletFk: $walletFk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryLimitPk, categoryFk, budgetFk, amount,
      dateTimeModified, walletFk);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryBudgetLimit &&
          other.categoryLimitPk == this.categoryLimitPk &&
          other.categoryFk == this.categoryFk &&
          other.budgetFk == this.budgetFk &&
          other.amount == this.amount &&
          other.dateTimeModified == this.dateTimeModified &&
          other.walletFk == this.walletFk);
}

class CategoryBudgetLimitsCompanion
    extends UpdateCompanion<CategoryBudgetLimit> {
  final Value<String> categoryLimitPk;
  final Value<String> categoryFk;
  final Value<String> budgetFk;
  final Value<double> amount;
  final Value<DateTime?> dateTimeModified;
  final Value<String> walletFk;
  final Value<int> rowid;
  const CategoryBudgetLimitsCompanion({
    this.categoryLimitPk = const Value.absent(),
    this.categoryFk = const Value.absent(),
    this.budgetFk = const Value.absent(),
    this.amount = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.walletFk = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryBudgetLimitsCompanion.insert({
    this.categoryLimitPk = const Value.absent(),
    required String categoryFk,
    required String budgetFk,
    required double amount,
    this.dateTimeModified = const Value.absent(),
    this.walletFk = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : categoryFk = Value(categoryFk),
        budgetFk = Value(budgetFk),
        amount = Value(amount);
  static Insertable<CategoryBudgetLimit> custom({
    Expression<String>? categoryLimitPk,
    Expression<String>? categoryFk,
    Expression<String>? budgetFk,
    Expression<double>? amount,
    Expression<DateTime>? dateTimeModified,
    Expression<String>? walletFk,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryLimitPk != null) 'category_limit_pk': categoryLimitPk,
      if (categoryFk != null) 'category_fk': categoryFk,
      if (budgetFk != null) 'budget_fk': budgetFk,
      if (amount != null) 'amount': amount,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (walletFk != null) 'wallet_fk': walletFk,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryBudgetLimitsCompanion copyWith(
      {Value<String>? categoryLimitPk,
      Value<String>? categoryFk,
      Value<String>? budgetFk,
      Value<double>? amount,
      Value<DateTime?>? dateTimeModified,
      Value<String>? walletFk,
      Value<int>? rowid}) {
    return CategoryBudgetLimitsCompanion(
      categoryLimitPk: categoryLimitPk ?? this.categoryLimitPk,
      categoryFk: categoryFk ?? this.categoryFk,
      budgetFk: budgetFk ?? this.budgetFk,
      amount: amount ?? this.amount,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      walletFk: walletFk ?? this.walletFk,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryLimitPk.present) {
      map['category_limit_pk'] = Variable<String>(categoryLimitPk.value);
    }
    if (categoryFk.present) {
      map['category_fk'] = Variable<String>(categoryFk.value);
    }
    if (budgetFk.present) {
      map['budget_fk'] = Variable<String>(budgetFk.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (walletFk.present) {
      map['wallet_fk'] = Variable<String>(walletFk.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudgetLimitsCompanion(')
          ..write('categoryLimitPk: $categoryLimitPk, ')
          ..write('categoryFk: $categoryFk, ')
          ..write('budgetFk: $budgetFk, ')
          ..write('amount: $amount, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('walletFk: $walletFk, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssociatedTitlesTable extends AssociatedTitles
    with TableInfo<$AssociatedTitlesTable, TransactionAssociatedTitle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssociatedTitlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _associatedTitlePkMeta =
      const VerificationMeta('associatedTitlePk');
  @override
  late final GeneratedColumn<String> associatedTitlePk =
      GeneratedColumn<String>('associated_title_pk', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          clientDefault: () => uuid.v4());
  static const VerificationMeta _categoryFkMeta =
      const VerificationMeta('categoryFk');
  @override
  late final GeneratedColumn<String> categoryFk = GeneratedColumn<String>(
      'category_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (category_pk)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => new DateTime.now());
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isExactMatchMeta =
      const VerificationMeta('isExactMatch');
  @override
  late final GeneratedColumn<bool> isExactMatch = GeneratedColumn<bool>(
      'is_exact_match', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_exact_match" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        associatedTitlePk,
        categoryFk,
        title,
        dateCreated,
        dateTimeModified,
        order,
        isExactMatch
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'associated_titles';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransactionAssociatedTitle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('associated_title_pk')) {
      context.handle(
          _associatedTitlePkMeta,
          associatedTitlePk.isAcceptableOrUnknown(
              data['associated_title_pk']!, _associatedTitlePkMeta));
    }
    if (data.containsKey('category_fk')) {
      context.handle(
          _categoryFkMeta,
          categoryFk.isAcceptableOrUnknown(
              data['category_fk']!, _categoryFkMeta));
    } else if (isInserting) {
      context.missing(_categoryFkMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('is_exact_match')) {
      context.handle(
          _isExactMatchMeta,
          isExactMatch.isAcceptableOrUnknown(
              data['is_exact_match']!, _isExactMatchMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {associatedTitlePk};
  @override
  TransactionAssociatedTitle map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionAssociatedTitle(
      associatedTitlePk: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}associated_title_pk'])!,
      categoryFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_fk'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      isExactMatch: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_exact_match'])!,
    );
  }

  @override
  $AssociatedTitlesTable createAlias(String alias) {
    return $AssociatedTitlesTable(attachedDatabase, alias);
  }
}

class TransactionAssociatedTitle extends DataClass
    implements Insertable<TransactionAssociatedTitle> {
  final String associatedTitlePk;
  final String categoryFk;
  final String title;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  final int order;
  final bool isExactMatch;
  const TransactionAssociatedTitle(
      {required this.associatedTitlePk,
      required this.categoryFk,
      required this.title,
      required this.dateCreated,
      this.dateTimeModified,
      required this.order,
      required this.isExactMatch});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['associated_title_pk'] = Variable<String>(associatedTitlePk);
    map['category_fk'] = Variable<String>(categoryFk);
    map['title'] = Variable<String>(title);
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    map['order'] = Variable<int>(order);
    map['is_exact_match'] = Variable<bool>(isExactMatch);
    return map;
  }

  AssociatedTitlesCompanion toCompanion(bool nullToAbsent) {
    return AssociatedTitlesCompanion(
      associatedTitlePk: Value(associatedTitlePk),
      categoryFk: Value(categoryFk),
      title: Value(title),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
      order: Value(order),
      isExactMatch: Value(isExactMatch),
    );
  }

  factory TransactionAssociatedTitle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionAssociatedTitle(
      associatedTitlePk: serializer.fromJson<String>(json['associatedTitlePk']),
      categoryFk: serializer.fromJson<String>(json['categoryFk']),
      title: serializer.fromJson<String>(json['title']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
      order: serializer.fromJson<int>(json['order']),
      isExactMatch: serializer.fromJson<bool>(json['isExactMatch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'associatedTitlePk': serializer.toJson<String>(associatedTitlePk),
      'categoryFk': serializer.toJson<String>(categoryFk),
      'title': serializer.toJson<String>(title),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
      'order': serializer.toJson<int>(order),
      'isExactMatch': serializer.toJson<bool>(isExactMatch),
    };
  }

  TransactionAssociatedTitle copyWith(
          {String? associatedTitlePk,
          String? categoryFk,
          String? title,
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent(),
          int? order,
          bool? isExactMatch}) =>
      TransactionAssociatedTitle(
        associatedTitlePk: associatedTitlePk ?? this.associatedTitlePk,
        categoryFk: categoryFk ?? this.categoryFk,
        title: title ?? this.title,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
        order: order ?? this.order,
        isExactMatch: isExactMatch ?? this.isExactMatch,
      );
  @override
  String toString() {
    return (StringBuffer('TransactionAssociatedTitle(')
          ..write('associatedTitlePk: $associatedTitlePk, ')
          ..write('categoryFk: $categoryFk, ')
          ..write('title: $title, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('order: $order, ')
          ..write('isExactMatch: $isExactMatch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(associatedTitlePk, categoryFk, title,
      dateCreated, dateTimeModified, order, isExactMatch);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionAssociatedTitle &&
          other.associatedTitlePk == this.associatedTitlePk &&
          other.categoryFk == this.categoryFk &&
          other.title == this.title &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified &&
          other.order == this.order &&
          other.isExactMatch == this.isExactMatch);
}

class AssociatedTitlesCompanion
    extends UpdateCompanion<TransactionAssociatedTitle> {
  final Value<String> associatedTitlePk;
  final Value<String> categoryFk;
  final Value<String> title;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<int> order;
  final Value<bool> isExactMatch;
  final Value<int> rowid;
  const AssociatedTitlesCompanion({
    this.associatedTitlePk = const Value.absent(),
    this.categoryFk = const Value.absent(),
    this.title = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.order = const Value.absent(),
    this.isExactMatch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssociatedTitlesCompanion.insert({
    this.associatedTitlePk = const Value.absent(),
    required String categoryFk,
    required String title,
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    required int order,
    this.isExactMatch = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : categoryFk = Value(categoryFk),
        title = Value(title),
        order = Value(order);
  static Insertable<TransactionAssociatedTitle> custom({
    Expression<String>? associatedTitlePk,
    Expression<String>? categoryFk,
    Expression<String>? title,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? order,
    Expression<bool>? isExactMatch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (associatedTitlePk != null) 'associated_title_pk': associatedTitlePk,
      if (categoryFk != null) 'category_fk': categoryFk,
      if (title != null) 'title': title,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (order != null) 'order': order,
      if (isExactMatch != null) 'is_exact_match': isExactMatch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssociatedTitlesCompanion copyWith(
      {Value<String>? associatedTitlePk,
      Value<String>? categoryFk,
      Value<String>? title,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<int>? order,
      Value<bool>? isExactMatch,
      Value<int>? rowid}) {
    return AssociatedTitlesCompanion(
      associatedTitlePk: associatedTitlePk ?? this.associatedTitlePk,
      categoryFk: categoryFk ?? this.categoryFk,
      title: title ?? this.title,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      order: order ?? this.order,
      isExactMatch: isExactMatch ?? this.isExactMatch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (associatedTitlePk.present) {
      map['associated_title_pk'] = Variable<String>(associatedTitlePk.value);
    }
    if (categoryFk.present) {
      map['category_fk'] = Variable<String>(categoryFk.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (isExactMatch.present) {
      map['is_exact_match'] = Variable<bool>(isExactMatch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssociatedTitlesCompanion(')
          ..write('associatedTitlePk: $associatedTitlePk, ')
          ..write('categoryFk: $categoryFk, ')
          ..write('title: $title, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('order: $order, ')
          ..write('isExactMatch: $isExactMatch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingsPkMeta =
      const VerificationMeta('settingsPk');
  @override
  late final GeneratedColumn<int> settingsPk = GeneratedColumn<int>(
      'settings_pk', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _settingsJSONMeta =
      const VerificationMeta('settingsJSON');
  @override
  late final GeneratedColumn<String> settingsJSON = GeneratedColumn<String>(
      'settings_j_s_o_n', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateUpdatedMeta =
      const VerificationMeta('dateUpdated');
  @override
  late final GeneratedColumn<DateTime> dateUpdated = GeneratedColumn<DateTime>(
      'date_updated', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => new DateTime.now());
  @override
  List<GeneratedColumn> get $columns => [settingsPk, settingsJSON, dateUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('settings_pk')) {
      context.handle(
          _settingsPkMeta,
          settingsPk.isAcceptableOrUnknown(
              data['settings_pk']!, _settingsPkMeta));
    }
    if (data.containsKey('settings_j_s_o_n')) {
      context.handle(
          _settingsJSONMeta,
          settingsJSON.isAcceptableOrUnknown(
              data['settings_j_s_o_n']!, _settingsJSONMeta));
    } else if (isInserting) {
      context.missing(_settingsJSONMeta);
    }
    if (data.containsKey('date_updated')) {
      context.handle(
          _dateUpdatedMeta,
          dateUpdated.isAcceptableOrUnknown(
              data['date_updated']!, _dateUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingsPk};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      settingsPk: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}settings_pk'])!,
      settingsJSON: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}settings_j_s_o_n'])!,
      dateUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_updated'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int settingsPk;
  final String settingsJSON;
  final DateTime dateUpdated;
  const AppSetting(
      {required this.settingsPk,
      required this.settingsJSON,
      required this.dateUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['settings_pk'] = Variable<int>(settingsPk);
    map['settings_j_s_o_n'] = Variable<String>(settingsJSON);
    map['date_updated'] = Variable<DateTime>(dateUpdated);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      settingsPk: Value(settingsPk),
      settingsJSON: Value(settingsJSON),
      dateUpdated: Value(dateUpdated),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      settingsPk: serializer.fromJson<int>(json['settingsPk']),
      settingsJSON: serializer.fromJson<String>(json['settingsJSON']),
      dateUpdated: serializer.fromJson<DateTime>(json['dateUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingsPk': serializer.toJson<int>(settingsPk),
      'settingsJSON': serializer.toJson<String>(settingsJSON),
      'dateUpdated': serializer.toJson<DateTime>(dateUpdated),
    };
  }

  AppSetting copyWith(
          {int? settingsPk, String? settingsJSON, DateTime? dateUpdated}) =>
      AppSetting(
        settingsPk: settingsPk ?? this.settingsPk,
        settingsJSON: settingsJSON ?? this.settingsJSON,
        dateUpdated: dateUpdated ?? this.dateUpdated,
      );
  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('settingsPk: $settingsPk, ')
          ..write('settingsJSON: $settingsJSON, ')
          ..write('dateUpdated: $dateUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingsPk, settingsJSON, dateUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.settingsPk == this.settingsPk &&
          other.settingsJSON == this.settingsJSON &&
          other.dateUpdated == this.dateUpdated);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> settingsPk;
  final Value<String> settingsJSON;
  final Value<DateTime> dateUpdated;
  const AppSettingsCompanion({
    this.settingsPk = const Value.absent(),
    this.settingsJSON = const Value.absent(),
    this.dateUpdated = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.settingsPk = const Value.absent(),
    required String settingsJSON,
    this.dateUpdated = const Value.absent(),
  }) : settingsJSON = Value(settingsJSON);
  static Insertable<AppSetting> custom({
    Expression<int>? settingsPk,
    Expression<String>? settingsJSON,
    Expression<DateTime>? dateUpdated,
  }) {
    return RawValuesInsertable({
      if (settingsPk != null) 'settings_pk': settingsPk,
      if (settingsJSON != null) 'settings_j_s_o_n': settingsJSON,
      if (dateUpdated != null) 'date_updated': dateUpdated,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? settingsPk,
      Value<String>? settingsJSON,
      Value<DateTime>? dateUpdated}) {
    return AppSettingsCompanion(
      settingsPk: settingsPk ?? this.settingsPk,
      settingsJSON: settingsJSON ?? this.settingsJSON,
      dateUpdated: dateUpdated ?? this.dateUpdated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingsPk.present) {
      map['settings_pk'] = Variable<int>(settingsPk.value);
    }
    if (settingsJSON.present) {
      map['settings_j_s_o_n'] = Variable<String>(settingsJSON.value);
    }
    if (dateUpdated.present) {
      map['date_updated'] = Variable<DateTime>(dateUpdated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingsPk: $settingsPk, ')
          ..write('settingsJSON: $settingsJSON, ')
          ..write('dateUpdated: $dateUpdated')
          ..write(')'))
        .toString();
  }
}

class $ScannerTemplatesTable extends ScannerTemplates
    with TableInfo<$ScannerTemplatesTable, ScannerTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScannerTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scannerTemplatePkMeta =
      const VerificationMeta('scannerTemplatePk');
  @override
  late final GeneratedColumn<String> scannerTemplatePk =
      GeneratedColumn<String>('scanner_template_pk', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          clientDefault: () => uuid.v4());
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => new DateTime.now());
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  static const VerificationMeta _templateNameMeta =
      const VerificationMeta('templateName');
  @override
  late final GeneratedColumn<String> templateName = GeneratedColumn<String>(
      'template_name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _containsMeta =
      const VerificationMeta('contains');
  @override
  late final GeneratedColumn<String> contains = GeneratedColumn<String>(
      'contains', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _titleTransactionBeforeMeta =
      const VerificationMeta('titleTransactionBefore');
  @override
  late final GeneratedColumn<String> titleTransactionBefore =
      GeneratedColumn<String>('title_transaction_before', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _titleTransactionAfterMeta =
      const VerificationMeta('titleTransactionAfter');
  @override
  late final GeneratedColumn<String> titleTransactionAfter =
      GeneratedColumn<String>('title_transaction_after', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _amountTransactionBeforeMeta =
      const VerificationMeta('amountTransactionBefore');
  @override
  late final GeneratedColumn<String> amountTransactionBefore =
      GeneratedColumn<String>('amount_transaction_before', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _amountTransactionAfterMeta =
      const VerificationMeta('amountTransactionAfter');
  @override
  late final GeneratedColumn<String> amountTransactionAfter =
      GeneratedColumn<String>('amount_transaction_after', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _defaultCategoryFkMeta =
      const VerificationMeta('defaultCategoryFk');
  @override
  late final GeneratedColumn<String> defaultCategoryFk =
      GeneratedColumn<String>('default_category_fk', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'REFERENCES categories (category_pk)'));
  static const VerificationMeta _walletFkMeta =
      const VerificationMeta('walletFk');
  @override
  late final GeneratedColumn<String> walletFk = GeneratedColumn<String>(
      'wallet_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (wallet_pk)'),
      defaultValue: const Constant("0"));
  static const VerificationMeta _ignoreMeta = const VerificationMeta('ignore');
  @override
  late final GeneratedColumn<bool> ignore = GeneratedColumn<bool>(
      'ignore', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ignore" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        scannerTemplatePk,
        dateCreated,
        dateTimeModified,
        templateName,
        contains,
        titleTransactionBefore,
        titleTransactionAfter,
        amountTransactionBefore,
        amountTransactionAfter,
        defaultCategoryFk,
        walletFk,
        ignore
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scanner_templates';
  @override
  VerificationContext validateIntegrity(Insertable<ScannerTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scanner_template_pk')) {
      context.handle(
          _scannerTemplatePkMeta,
          scannerTemplatePk.isAcceptableOrUnknown(
              data['scanner_template_pk']!, _scannerTemplatePkMeta));
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    if (data.containsKey('template_name')) {
      context.handle(
          _templateNameMeta,
          templateName.isAcceptableOrUnknown(
              data['template_name']!, _templateNameMeta));
    } else if (isInserting) {
      context.missing(_templateNameMeta);
    }
    if (data.containsKey('contains')) {
      context.handle(_containsMeta,
          contains.isAcceptableOrUnknown(data['contains']!, _containsMeta));
    } else if (isInserting) {
      context.missing(_containsMeta);
    }
    if (data.containsKey('title_transaction_before')) {
      context.handle(
          _titleTransactionBeforeMeta,
          titleTransactionBefore.isAcceptableOrUnknown(
              data['title_transaction_before']!, _titleTransactionBeforeMeta));
    } else if (isInserting) {
      context.missing(_titleTransactionBeforeMeta);
    }
    if (data.containsKey('title_transaction_after')) {
      context.handle(
          _titleTransactionAfterMeta,
          titleTransactionAfter.isAcceptableOrUnknown(
              data['title_transaction_after']!, _titleTransactionAfterMeta));
    } else if (isInserting) {
      context.missing(_titleTransactionAfterMeta);
    }
    if (data.containsKey('amount_transaction_before')) {
      context.handle(
          _amountTransactionBeforeMeta,
          amountTransactionBefore.isAcceptableOrUnknown(
              data['amount_transaction_before']!,
              _amountTransactionBeforeMeta));
    } else if (isInserting) {
      context.missing(_amountTransactionBeforeMeta);
    }
    if (data.containsKey('amount_transaction_after')) {
      context.handle(
          _amountTransactionAfterMeta,
          amountTransactionAfter.isAcceptableOrUnknown(
              data['amount_transaction_after']!, _amountTransactionAfterMeta));
    } else if (isInserting) {
      context.missing(_amountTransactionAfterMeta);
    }
    if (data.containsKey('default_category_fk')) {
      context.handle(
          _defaultCategoryFkMeta,
          defaultCategoryFk.isAcceptableOrUnknown(
              data['default_category_fk']!, _defaultCategoryFkMeta));
    } else if (isInserting) {
      context.missing(_defaultCategoryFkMeta);
    }
    if (data.containsKey('wallet_fk')) {
      context.handle(_walletFkMeta,
          walletFk.isAcceptableOrUnknown(data['wallet_fk']!, _walletFkMeta));
    }
    if (data.containsKey('ignore')) {
      context.handle(_ignoreMeta,
          ignore.isAcceptableOrUnknown(data['ignore']!, _ignoreMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scannerTemplatePk};
  @override
  ScannerTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScannerTemplate(
      scannerTemplatePk: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}scanner_template_pk'])!,
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
      templateName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_name'])!,
      contains: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contains'])!,
      titleTransactionBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}title_transaction_before'])!,
      titleTransactionAfter: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}title_transaction_after'])!,
      amountTransactionBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount_transaction_before'])!,
      amountTransactionAfter: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount_transaction_after'])!,
      defaultCategoryFk: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}default_category_fk'])!,
      walletFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wallet_fk'])!,
      ignore: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ignore'])!,
    );
  }

  @override
  $ScannerTemplatesTable createAlias(String alias) {
    return $ScannerTemplatesTable(attachedDatabase, alias);
  }
}

class ScannerTemplate extends DataClass implements Insertable<ScannerTemplate> {
  final String scannerTemplatePk;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  final String templateName;
  final String contains;
  final String titleTransactionBefore;
  final String titleTransactionAfter;
  final String amountTransactionBefore;
  final String amountTransactionAfter;
  final String defaultCategoryFk;
  final String walletFk;
  final bool ignore;
  const ScannerTemplate(
      {required this.scannerTemplatePk,
      required this.dateCreated,
      this.dateTimeModified,
      required this.templateName,
      required this.contains,
      required this.titleTransactionBefore,
      required this.titleTransactionAfter,
      required this.amountTransactionBefore,
      required this.amountTransactionAfter,
      required this.defaultCategoryFk,
      required this.walletFk,
      required this.ignore});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scanner_template_pk'] = Variable<String>(scannerTemplatePk);
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    map['template_name'] = Variable<String>(templateName);
    map['contains'] = Variable<String>(contains);
    map['title_transaction_before'] = Variable<String>(titleTransactionBefore);
    map['title_transaction_after'] = Variable<String>(titleTransactionAfter);
    map['amount_transaction_before'] =
        Variable<String>(amountTransactionBefore);
    map['amount_transaction_after'] = Variable<String>(amountTransactionAfter);
    map['default_category_fk'] = Variable<String>(defaultCategoryFk);
    map['wallet_fk'] = Variable<String>(walletFk);
    map['ignore'] = Variable<bool>(ignore);
    return map;
  }

  ScannerTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ScannerTemplatesCompanion(
      scannerTemplatePk: Value(scannerTemplatePk),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
      templateName: Value(templateName),
      contains: Value(contains),
      titleTransactionBefore: Value(titleTransactionBefore),
      titleTransactionAfter: Value(titleTransactionAfter),
      amountTransactionBefore: Value(amountTransactionBefore),
      amountTransactionAfter: Value(amountTransactionAfter),
      defaultCategoryFk: Value(defaultCategoryFk),
      walletFk: Value(walletFk),
      ignore: Value(ignore),
    );
  }

  factory ScannerTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScannerTemplate(
      scannerTemplatePk: serializer.fromJson<String>(json['scannerTemplatePk']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
      templateName: serializer.fromJson<String>(json['templateName']),
      contains: serializer.fromJson<String>(json['contains']),
      titleTransactionBefore:
          serializer.fromJson<String>(json['titleTransactionBefore']),
      titleTransactionAfter:
          serializer.fromJson<String>(json['titleTransactionAfter']),
      amountTransactionBefore:
          serializer.fromJson<String>(json['amountTransactionBefore']),
      amountTransactionAfter:
          serializer.fromJson<String>(json['amountTransactionAfter']),
      defaultCategoryFk: serializer.fromJson<String>(json['defaultCategoryFk']),
      walletFk: serializer.fromJson<String>(json['walletFk']),
      ignore: serializer.fromJson<bool>(json['ignore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scannerTemplatePk': serializer.toJson<String>(scannerTemplatePk),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
      'templateName': serializer.toJson<String>(templateName),
      'contains': serializer.toJson<String>(contains),
      'titleTransactionBefore':
          serializer.toJson<String>(titleTransactionBefore),
      'titleTransactionAfter': serializer.toJson<String>(titleTransactionAfter),
      'amountTransactionBefore':
          serializer.toJson<String>(amountTransactionBefore),
      'amountTransactionAfter':
          serializer.toJson<String>(amountTransactionAfter),
      'defaultCategoryFk': serializer.toJson<String>(defaultCategoryFk),
      'walletFk': serializer.toJson<String>(walletFk),
      'ignore': serializer.toJson<bool>(ignore),
    };
  }

  ScannerTemplate copyWith(
          {String? scannerTemplatePk,
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent(),
          String? templateName,
          String? contains,
          String? titleTransactionBefore,
          String? titleTransactionAfter,
          String? amountTransactionBefore,
          String? amountTransactionAfter,
          String? defaultCategoryFk,
          String? walletFk,
          bool? ignore}) =>
      ScannerTemplate(
        scannerTemplatePk: scannerTemplatePk ?? this.scannerTemplatePk,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
        templateName: templateName ?? this.templateName,
        contains: contains ?? this.contains,
        titleTransactionBefore:
            titleTransactionBefore ?? this.titleTransactionBefore,
        titleTransactionAfter:
            titleTransactionAfter ?? this.titleTransactionAfter,
        amountTransactionBefore:
            amountTransactionBefore ?? this.amountTransactionBefore,
        amountTransactionAfter:
            amountTransactionAfter ?? this.amountTransactionAfter,
        defaultCategoryFk: defaultCategoryFk ?? this.defaultCategoryFk,
        walletFk: walletFk ?? this.walletFk,
        ignore: ignore ?? this.ignore,
      );
  @override
  String toString() {
    return (StringBuffer('ScannerTemplate(')
          ..write('scannerTemplatePk: $scannerTemplatePk, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('templateName: $templateName, ')
          ..write('contains: $contains, ')
          ..write('titleTransactionBefore: $titleTransactionBefore, ')
          ..write('titleTransactionAfter: $titleTransactionAfter, ')
          ..write('amountTransactionBefore: $amountTransactionBefore, ')
          ..write('amountTransactionAfter: $amountTransactionAfter, ')
          ..write('defaultCategoryFk: $defaultCategoryFk, ')
          ..write('walletFk: $walletFk, ')
          ..write('ignore: $ignore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      scannerTemplatePk,
      dateCreated,
      dateTimeModified,
      templateName,
      contains,
      titleTransactionBefore,
      titleTransactionAfter,
      amountTransactionBefore,
      amountTransactionAfter,
      defaultCategoryFk,
      walletFk,
      ignore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScannerTemplate &&
          other.scannerTemplatePk == this.scannerTemplatePk &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified &&
          other.templateName == this.templateName &&
          other.contains == this.contains &&
          other.titleTransactionBefore == this.titleTransactionBefore &&
          other.titleTransactionAfter == this.titleTransactionAfter &&
          other.amountTransactionBefore == this.amountTransactionBefore &&
          other.amountTransactionAfter == this.amountTransactionAfter &&
          other.defaultCategoryFk == this.defaultCategoryFk &&
          other.walletFk == this.walletFk &&
          other.ignore == this.ignore);
}

class ScannerTemplatesCompanion extends UpdateCompanion<ScannerTemplate> {
  final Value<String> scannerTemplatePk;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<String> templateName;
  final Value<String> contains;
  final Value<String> titleTransactionBefore;
  final Value<String> titleTransactionAfter;
  final Value<String> amountTransactionBefore;
  final Value<String> amountTransactionAfter;
  final Value<String> defaultCategoryFk;
  final Value<String> walletFk;
  final Value<bool> ignore;
  final Value<int> rowid;
  const ScannerTemplatesCompanion({
    this.scannerTemplatePk = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.templateName = const Value.absent(),
    this.contains = const Value.absent(),
    this.titleTransactionBefore = const Value.absent(),
    this.titleTransactionAfter = const Value.absent(),
    this.amountTransactionBefore = const Value.absent(),
    this.amountTransactionAfter = const Value.absent(),
    this.defaultCategoryFk = const Value.absent(),
    this.walletFk = const Value.absent(),
    this.ignore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScannerTemplatesCompanion.insert({
    this.scannerTemplatePk = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    required String templateName,
    required String contains,
    required String titleTransactionBefore,
    required String titleTransactionAfter,
    required String amountTransactionBefore,
    required String amountTransactionAfter,
    required String defaultCategoryFk,
    this.walletFk = const Value.absent(),
    this.ignore = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : templateName = Value(templateName),
        contains = Value(contains),
        titleTransactionBefore = Value(titleTransactionBefore),
        titleTransactionAfter = Value(titleTransactionAfter),
        amountTransactionBefore = Value(amountTransactionBefore),
        amountTransactionAfter = Value(amountTransactionAfter),
        defaultCategoryFk = Value(defaultCategoryFk);
  static Insertable<ScannerTemplate> custom({
    Expression<String>? scannerTemplatePk,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<String>? templateName,
    Expression<String>? contains,
    Expression<String>? titleTransactionBefore,
    Expression<String>? titleTransactionAfter,
    Expression<String>? amountTransactionBefore,
    Expression<String>? amountTransactionAfter,
    Expression<String>? defaultCategoryFk,
    Expression<String>? walletFk,
    Expression<bool>? ignore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scannerTemplatePk != null) 'scanner_template_pk': scannerTemplatePk,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (templateName != null) 'template_name': templateName,
      if (contains != null) 'contains': contains,
      if (titleTransactionBefore != null)
        'title_transaction_before': titleTransactionBefore,
      if (titleTransactionAfter != null)
        'title_transaction_after': titleTransactionAfter,
      if (amountTransactionBefore != null)
        'amount_transaction_before': amountTransactionBefore,
      if (amountTransactionAfter != null)
        'amount_transaction_after': amountTransactionAfter,
      if (defaultCategoryFk != null) 'default_category_fk': defaultCategoryFk,
      if (walletFk != null) 'wallet_fk': walletFk,
      if (ignore != null) 'ignore': ignore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScannerTemplatesCompanion copyWith(
      {Value<String>? scannerTemplatePk,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<String>? templateName,
      Value<String>? contains,
      Value<String>? titleTransactionBefore,
      Value<String>? titleTransactionAfter,
      Value<String>? amountTransactionBefore,
      Value<String>? amountTransactionAfter,
      Value<String>? defaultCategoryFk,
      Value<String>? walletFk,
      Value<bool>? ignore,
      Value<int>? rowid}) {
    return ScannerTemplatesCompanion(
      scannerTemplatePk: scannerTemplatePk ?? this.scannerTemplatePk,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      templateName: templateName ?? this.templateName,
      contains: contains ?? this.contains,
      titleTransactionBefore:
          titleTransactionBefore ?? this.titleTransactionBefore,
      titleTransactionAfter:
          titleTransactionAfter ?? this.titleTransactionAfter,
      amountTransactionBefore:
          amountTransactionBefore ?? this.amountTransactionBefore,
      amountTransactionAfter:
          amountTransactionAfter ?? this.amountTransactionAfter,
      defaultCategoryFk: defaultCategoryFk ?? this.defaultCategoryFk,
      walletFk: walletFk ?? this.walletFk,
      ignore: ignore ?? this.ignore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scannerTemplatePk.present) {
      map['scanner_template_pk'] = Variable<String>(scannerTemplatePk.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (templateName.present) {
      map['template_name'] = Variable<String>(templateName.value);
    }
    if (contains.present) {
      map['contains'] = Variable<String>(contains.value);
    }
    if (titleTransactionBefore.present) {
      map['title_transaction_before'] =
          Variable<String>(titleTransactionBefore.value);
    }
    if (titleTransactionAfter.present) {
      map['title_transaction_after'] =
          Variable<String>(titleTransactionAfter.value);
    }
    if (amountTransactionBefore.present) {
      map['amount_transaction_before'] =
          Variable<String>(amountTransactionBefore.value);
    }
    if (amountTransactionAfter.present) {
      map['amount_transaction_after'] =
          Variable<String>(amountTransactionAfter.value);
    }
    if (defaultCategoryFk.present) {
      map['default_category_fk'] = Variable<String>(defaultCategoryFk.value);
    }
    if (walletFk.present) {
      map['wallet_fk'] = Variable<String>(walletFk.value);
    }
    if (ignore.present) {
      map['ignore'] = Variable<bool>(ignore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScannerTemplatesCompanion(')
          ..write('scannerTemplatePk: $scannerTemplatePk, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('templateName: $templateName, ')
          ..write('contains: $contains, ')
          ..write('titleTransactionBefore: $titleTransactionBefore, ')
          ..write('titleTransactionAfter: $titleTransactionAfter, ')
          ..write('amountTransactionBefore: $amountTransactionBefore, ')
          ..write('amountTransactionAfter: $amountTransactionAfter, ')
          ..write('defaultCategoryFk: $defaultCategoryFk, ')
          ..write('walletFk: $walletFk, ')
          ..write('ignore: $ignore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeleteLogsTable extends DeleteLogs
    with TableInfo<$DeleteLogsTable, DeleteLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeleteLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deleteLogPkMeta =
      const VerificationMeta('deleteLogPk');
  @override
  late final GeneratedColumn<String> deleteLogPk = GeneratedColumn<String>(
      'delete_log_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _entryPkMeta =
      const VerificationMeta('entryPk');
  @override
  late final GeneratedColumn<String> entryPk = GeneratedColumn<String>(
      'entry_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<DeleteLogType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DeleteLogType>($DeleteLogsTable.$convertertype);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: Constant(DateTime.now()));
  @override
  List<GeneratedColumn> get $columns =>
      [deleteLogPk, entryPk, type, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delete_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DeleteLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('delete_log_pk')) {
      context.handle(
          _deleteLogPkMeta,
          deleteLogPk.isAcceptableOrUnknown(
              data['delete_log_pk']!, _deleteLogPkMeta));
    }
    if (data.containsKey('entry_pk')) {
      context.handle(_entryPkMeta,
          entryPk.isAcceptableOrUnknown(data['entry_pk']!, _entryPkMeta));
    } else if (isInserting) {
      context.missing(_entryPkMeta);
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deleteLogPk};
  @override
  DeleteLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeleteLog(
      deleteLogPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delete_log_pk'])!,
      entryPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_pk'])!,
      type: $DeleteLogsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $DeleteLogsTable createAlias(String alias) {
    return $DeleteLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DeleteLogType, int, int> $convertertype =
      const EnumIndexConverter<DeleteLogType>(DeleteLogType.values);
}

class DeleteLog extends DataClass implements Insertable<DeleteLog> {
  final String deleteLogPk;
  final String entryPk;
  final DeleteLogType type;
  final DateTime dateTimeModified;
  const DeleteLog(
      {required this.deleteLogPk,
      required this.entryPk,
      required this.type,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['delete_log_pk'] = Variable<String>(deleteLogPk);
    map['entry_pk'] = Variable<String>(entryPk);
    {
      map['type'] = Variable<int>($DeleteLogsTable.$convertertype.toSql(type));
    }
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  DeleteLogsCompanion toCompanion(bool nullToAbsent) {
    return DeleteLogsCompanion(
      deleteLogPk: Value(deleteLogPk),
      entryPk: Value(entryPk),
      type: Value(type),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory DeleteLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeleteLog(
      deleteLogPk: serializer.fromJson<String>(json['deleteLogPk']),
      entryPk: serializer.fromJson<String>(json['entryPk']),
      type: $DeleteLogsTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deleteLogPk': serializer.toJson<String>(deleteLogPk),
      'entryPk': serializer.toJson<String>(entryPk),
      'type':
          serializer.toJson<int>($DeleteLogsTable.$convertertype.toJson(type)),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  DeleteLog copyWith(
          {String? deleteLogPk,
          String? entryPk,
          DeleteLogType? type,
          DateTime? dateTimeModified}) =>
      DeleteLog(
        deleteLogPk: deleteLogPk ?? this.deleteLogPk,
        entryPk: entryPk ?? this.entryPk,
        type: type ?? this.type,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('DeleteLog(')
          ..write('deleteLogPk: $deleteLogPk, ')
          ..write('entryPk: $entryPk, ')
          ..write('type: $type, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deleteLogPk, entryPk, type, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeleteLog &&
          other.deleteLogPk == this.deleteLogPk &&
          other.entryPk == this.entryPk &&
          other.type == this.type &&
          other.dateTimeModified == this.dateTimeModified);
}

class DeleteLogsCompanion extends UpdateCompanion<DeleteLog> {
  final Value<String> deleteLogPk;
  final Value<String> entryPk;
  final Value<DeleteLogType> type;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const DeleteLogsCompanion({
    this.deleteLogPk = const Value.absent(),
    this.entryPk = const Value.absent(),
    this.type = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeleteLogsCompanion.insert({
    this.deleteLogPk = const Value.absent(),
    required String entryPk,
    required DeleteLogType type,
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : entryPk = Value(entryPk),
        type = Value(type);
  static Insertable<DeleteLog> custom({
    Expression<String>? deleteLogPk,
    Expression<String>? entryPk,
    Expression<int>? type,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deleteLogPk != null) 'delete_log_pk': deleteLogPk,
      if (entryPk != null) 'entry_pk': entryPk,
      if (type != null) 'type': type,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeleteLogsCompanion copyWith(
      {Value<String>? deleteLogPk,
      Value<String>? entryPk,
      Value<DeleteLogType>? type,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return DeleteLogsCompanion(
      deleteLogPk: deleteLogPk ?? this.deleteLogPk,
      entryPk: entryPk ?? this.entryPk,
      type: type ?? this.type,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deleteLogPk.present) {
      map['delete_log_pk'] = Variable<String>(deleteLogPk.value);
    }
    if (entryPk.present) {
      map['entry_pk'] = Variable<String>(entryPk.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($DeleteLogsTable.$convertertype.toSql(type.value));
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeleteLogsCompanion(')
          ..write('deleteLogPk: $deleteLogPk, ')
          ..write('entryPk: $entryPk, ')
          ..write('type: $type, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FireflyIdMapTable extends FireflyIdMap
    with TableInfo<$FireflyIdMapTable, FireflyIdMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FireflyIdMapTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumnWithTypeConverter<FireflyEntityType, int>
      entityType = GeneratedColumn<int>('entity_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<FireflyEntityType>(
              $FireflyIdMapTable.$converterentityType);
  static const VerificationMeta _localPkMeta =
      const VerificationMeta('localPk');
  @override
  late final GeneratedColumn<String> localPk = GeneratedColumn<String>(
      'local_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteSubIdMeta =
      const VerificationMeta('remoteSubId');
  @override
  late final GeneratedColumn<String> remoteSubId = GeneratedColumn<String>(
      'remote_sub_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _remoteRoleMeta =
      const VerificationMeta('remoteRole');
  @override
  late final GeneratedColumn<int> remoteRole = GeneratedColumn<int>(
      'remote_role', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _remoteUpdatedAtMeta =
      const VerificationMeta('remoteUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> remoteUpdatedAt =
      GeneratedColumn<DateTime>('remote_updated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _localVersionAtMeta =
      const VerificationMeta('localVersionAt');
  @override
  late final GeneratedColumn<DateTime> localVersionAt =
      GeneratedColumn<DateTime>('local_version_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedHashMeta =
      const VerificationMeta('syncedHash');
  @override
  late final GeneratedColumn<String> syncedHash = GeneratedColumn<String>(
      'synced_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lossyFieldsMeta =
      const VerificationMeta('lossyFields');
  @override
  late final GeneratedColumn<String> lossyFields = GeneratedColumn<String>(
      'lossy_fields', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumnWithTypeConverter<FireflySyncState, int> state =
      GeneratedColumn<int>('state', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<FireflySyncState>($FireflyIdMapTable.$converterstate);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        entityType,
        localPk,
        remoteId,
        remoteSubId,
        remoteRole,
        remoteUpdatedAt,
        localVersionAt,
        syncedHash,
        lossyFields,
        state,
        attempts,
        lastError,
        lastAttemptAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'firefly_id_map';
  @override
  VerificationContext validateIntegrity(Insertable<FireflyIdMapping> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    context.handle(_entityTypeMeta, const VerificationResult.success());
    if (data.containsKey('local_pk')) {
      context.handle(_localPkMeta,
          localPk.isAcceptableOrUnknown(data['local_pk']!, _localPkMeta));
    } else if (isInserting) {
      context.missing(_localPkMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('remote_sub_id')) {
      context.handle(
          _remoteSubIdMeta,
          remoteSubId.isAcceptableOrUnknown(
              data['remote_sub_id']!, _remoteSubIdMeta));
    }
    if (data.containsKey('remote_role')) {
      context.handle(
          _remoteRoleMeta,
          remoteRole.isAcceptableOrUnknown(
              data['remote_role']!, _remoteRoleMeta));
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
          _remoteUpdatedAtMeta,
          remoteUpdatedAt.isAcceptableOrUnknown(
              data['remote_updated_at']!, _remoteUpdatedAtMeta));
    }
    if (data.containsKey('local_version_at')) {
      context.handle(
          _localVersionAtMeta,
          localVersionAt.isAcceptableOrUnknown(
              data['local_version_at']!, _localVersionAtMeta));
    }
    if (data.containsKey('synced_hash')) {
      context.handle(
          _syncedHashMeta,
          syncedHash.isAcceptableOrUnknown(
              data['synced_hash']!, _syncedHashMeta));
    }
    if (data.containsKey('lossy_fields')) {
      context.handle(
          _lossyFieldsMeta,
          lossyFields.isAcceptableOrUnknown(
              data['lossy_fields']!, _lossyFieldsMeta));
    }
    context.handle(_stateMeta, const VerificationResult.success());
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, localPk};
  @override
  FireflyIdMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FireflyIdMapping(
      entityType: $FireflyIdMapTable.$converterentityType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}entity_type'])!),
      localPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_pk'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id'])!,
      remoteSubId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_sub_id'])!,
      remoteRole: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remote_role'])!,
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}remote_updated_at']),
      localVersionAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_version_at']),
      syncedHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synced_hash']),
      lossyFields: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lossy_fields']),
      state: $FireflyIdMapTable.$converterstate.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state'])!),
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
    );
  }

  @override
  $FireflyIdMapTable createAlias(String alias) {
    return $FireflyIdMapTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FireflyEntityType, int, int> $converterentityType =
      const EnumIndexConverter<FireflyEntityType>(FireflyEntityType.values);
  static JsonTypeConverter2<FireflySyncState, int, int> $converterstate =
      const EnumIndexConverter<FireflySyncState>(FireflySyncState.values);
}

class FireflyIdMapping extends DataClass
    implements Insertable<FireflyIdMapping> {
  final FireflyEntityType entityType;
  final String localPk;
  final String remoteId;
  final String remoteSubId;
  final int remoteRole;
  final DateTime? remoteUpdatedAt;
  final DateTime? localVersionAt;
  final String? syncedHash;
  final String? lossyFields;
  final FireflySyncState state;
  final int attempts;
  final String? lastError;
  final DateTime? lastAttemptAt;
  const FireflyIdMapping(
      {required this.entityType,
      required this.localPk,
      required this.remoteId,
      required this.remoteSubId,
      required this.remoteRole,
      this.remoteUpdatedAt,
      this.localVersionAt,
      this.syncedHash,
      this.lossyFields,
      required this.state,
      required this.attempts,
      this.lastError,
      this.lastAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['entity_type'] = Variable<int>(
          $FireflyIdMapTable.$converterentityType.toSql(entityType));
    }
    map['local_pk'] = Variable<String>(localPk);
    map['remote_id'] = Variable<String>(remoteId);
    map['remote_sub_id'] = Variable<String>(remoteSubId);
    map['remote_role'] = Variable<int>(remoteRole);
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt);
    }
    if (!nullToAbsent || localVersionAt != null) {
      map['local_version_at'] = Variable<DateTime>(localVersionAt);
    }
    if (!nullToAbsent || syncedHash != null) {
      map['synced_hash'] = Variable<String>(syncedHash);
    }
    if (!nullToAbsent || lossyFields != null) {
      map['lossy_fields'] = Variable<String>(lossyFields);
    }
    {
      map['state'] =
          Variable<int>($FireflyIdMapTable.$converterstate.toSql(state));
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  FireflyIdMapCompanion toCompanion(bool nullToAbsent) {
    return FireflyIdMapCompanion(
      entityType: Value(entityType),
      localPk: Value(localPk),
      remoteId: Value(remoteId),
      remoteSubId: Value(remoteSubId),
      remoteRole: Value(remoteRole),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      localVersionAt: localVersionAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localVersionAt),
      syncedHash: syncedHash == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedHash),
      lossyFields: lossyFields == null && nullToAbsent
          ? const Value.absent()
          : Value(lossyFields),
      state: Value(state),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory FireflyIdMapping.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FireflyIdMapping(
      entityType: $FireflyIdMapTable.$converterentityType
          .fromJson(serializer.fromJson<int>(json['entityType'])),
      localPk: serializer.fromJson<String>(json['localPk']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      remoteSubId: serializer.fromJson<String>(json['remoteSubId']),
      remoteRole: serializer.fromJson<int>(json['remoteRole']),
      remoteUpdatedAt: serializer.fromJson<DateTime?>(json['remoteUpdatedAt']),
      localVersionAt: serializer.fromJson<DateTime?>(json['localVersionAt']),
      syncedHash: serializer.fromJson<String?>(json['syncedHash']),
      lossyFields: serializer.fromJson<String?>(json['lossyFields']),
      state: $FireflyIdMapTable.$converterstate
          .fromJson(serializer.fromJson<int>(json['state'])),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<int>(
          $FireflyIdMapTable.$converterentityType.toJson(entityType)),
      'localPk': serializer.toJson<String>(localPk),
      'remoteId': serializer.toJson<String>(remoteId),
      'remoteSubId': serializer.toJson<String>(remoteSubId),
      'remoteRole': serializer.toJson<int>(remoteRole),
      'remoteUpdatedAt': serializer.toJson<DateTime?>(remoteUpdatedAt),
      'localVersionAt': serializer.toJson<DateTime?>(localVersionAt),
      'syncedHash': serializer.toJson<String?>(syncedHash),
      'lossyFields': serializer.toJson<String?>(lossyFields),
      'state': serializer
          .toJson<int>($FireflyIdMapTable.$converterstate.toJson(state)),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  FireflyIdMapping copyWith(
          {FireflyEntityType? entityType,
          String? localPk,
          String? remoteId,
          String? remoteSubId,
          int? remoteRole,
          Value<DateTime?> remoteUpdatedAt = const Value.absent(),
          Value<DateTime?> localVersionAt = const Value.absent(),
          Value<String?> syncedHash = const Value.absent(),
          Value<String?> lossyFields = const Value.absent(),
          FireflySyncState? state,
          int? attempts,
          Value<String?> lastError = const Value.absent(),
          Value<DateTime?> lastAttemptAt = const Value.absent()}) =>
      FireflyIdMapping(
        entityType: entityType ?? this.entityType,
        localPk: localPk ?? this.localPk,
        remoteId: remoteId ?? this.remoteId,
        remoteSubId: remoteSubId ?? this.remoteSubId,
        remoteRole: remoteRole ?? this.remoteRole,
        remoteUpdatedAt: remoteUpdatedAt.present
            ? remoteUpdatedAt.value
            : this.remoteUpdatedAt,
        localVersionAt:
            localVersionAt.present ? localVersionAt.value : this.localVersionAt,
        syncedHash: syncedHash.present ? syncedHash.value : this.syncedHash,
        lossyFields: lossyFields.present ? lossyFields.value : this.lossyFields,
        state: state ?? this.state,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
      );
  @override
  String toString() {
    return (StringBuffer('FireflyIdMapping(')
          ..write('entityType: $entityType, ')
          ..write('localPk: $localPk, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteSubId: $remoteSubId, ')
          ..write('remoteRole: $remoteRole, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('localVersionAt: $localVersionAt, ')
          ..write('syncedHash: $syncedHash, ')
          ..write('lossyFields: $lossyFields, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      entityType,
      localPk,
      remoteId,
      remoteSubId,
      remoteRole,
      remoteUpdatedAt,
      localVersionAt,
      syncedHash,
      lossyFields,
      state,
      attempts,
      lastError,
      lastAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FireflyIdMapping &&
          other.entityType == this.entityType &&
          other.localPk == this.localPk &&
          other.remoteId == this.remoteId &&
          other.remoteSubId == this.remoteSubId &&
          other.remoteRole == this.remoteRole &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.localVersionAt == this.localVersionAt &&
          other.syncedHash == this.syncedHash &&
          other.lossyFields == this.lossyFields &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class FireflyIdMapCompanion extends UpdateCompanion<FireflyIdMapping> {
  final Value<FireflyEntityType> entityType;
  final Value<String> localPk;
  final Value<String> remoteId;
  final Value<String> remoteSubId;
  final Value<int> remoteRole;
  final Value<DateTime?> remoteUpdatedAt;
  final Value<DateTime?> localVersionAt;
  final Value<String?> syncedHash;
  final Value<String?> lossyFields;
  final Value<FireflySyncState> state;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> rowid;
  const FireflyIdMapCompanion({
    this.entityType = const Value.absent(),
    this.localPk = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteSubId = const Value.absent(),
    this.remoteRole = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.localVersionAt = const Value.absent(),
    this.syncedHash = const Value.absent(),
    this.lossyFields = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FireflyIdMapCompanion.insert({
    required FireflyEntityType entityType,
    required String localPk,
    required String remoteId,
    this.remoteSubId = const Value.absent(),
    this.remoteRole = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.localVersionAt = const Value.absent(),
    this.syncedHash = const Value.absent(),
    this.lossyFields = const Value.absent(),
    required FireflySyncState state,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : entityType = Value(entityType),
        localPk = Value(localPk),
        remoteId = Value(remoteId),
        state = Value(state);
  static Insertable<FireflyIdMapping> custom({
    Expression<int>? entityType,
    Expression<String>? localPk,
    Expression<String>? remoteId,
    Expression<String>? remoteSubId,
    Expression<int>? remoteRole,
    Expression<DateTime>? remoteUpdatedAt,
    Expression<DateTime>? localVersionAt,
    Expression<String>? syncedHash,
    Expression<String>? lossyFields,
    Expression<int>? state,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (localPk != null) 'local_pk': localPk,
      if (remoteId != null) 'remote_id': remoteId,
      if (remoteSubId != null) 'remote_sub_id': remoteSubId,
      if (remoteRole != null) 'remote_role': remoteRole,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (localVersionAt != null) 'local_version_at': localVersionAt,
      if (syncedHash != null) 'synced_hash': syncedHash,
      if (lossyFields != null) 'lossy_fields': lossyFields,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FireflyIdMapCompanion copyWith(
      {Value<FireflyEntityType>? entityType,
      Value<String>? localPk,
      Value<String>? remoteId,
      Value<String>? remoteSubId,
      Value<int>? remoteRole,
      Value<DateTime?>? remoteUpdatedAt,
      Value<DateTime?>? localVersionAt,
      Value<String?>? syncedHash,
      Value<String?>? lossyFields,
      Value<FireflySyncState>? state,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<DateTime?>? lastAttemptAt,
      Value<int>? rowid}) {
    return FireflyIdMapCompanion(
      entityType: entityType ?? this.entityType,
      localPk: localPk ?? this.localPk,
      remoteId: remoteId ?? this.remoteId,
      remoteSubId: remoteSubId ?? this.remoteSubId,
      remoteRole: remoteRole ?? this.remoteRole,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      localVersionAt: localVersionAt ?? this.localVersionAt,
      syncedHash: syncedHash ?? this.syncedHash,
      lossyFields: lossyFields ?? this.lossyFields,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<int>(
          $FireflyIdMapTable.$converterentityType.toSql(entityType.value));
    }
    if (localPk.present) {
      map['local_pk'] = Variable<String>(localPk.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (remoteSubId.present) {
      map['remote_sub_id'] = Variable<String>(remoteSubId.value);
    }
    if (remoteRole.present) {
      map['remote_role'] = Variable<int>(remoteRole.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt.value);
    }
    if (localVersionAt.present) {
      map['local_version_at'] = Variable<DateTime>(localVersionAt.value);
    }
    if (syncedHash.present) {
      map['synced_hash'] = Variable<String>(syncedHash.value);
    }
    if (lossyFields.present) {
      map['lossy_fields'] = Variable<String>(lossyFields.value);
    }
    if (state.present) {
      map['state'] =
          Variable<int>($FireflyIdMapTable.$converterstate.toSql(state.value));
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FireflyIdMapCompanion(')
          ..write('entityType: $entityType, ')
          ..write('localPk: $localPk, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteSubId: $remoteSubId, ')
          ..write('remoteRole: $remoteRole, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('localVersionAt: $localVersionAt, ')
          ..write('syncedHash: $syncedHash, ')
          ..write('lossyFields: $lossyFields, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FireflySyncMetaTable extends FireflySyncMeta
    with TableInfo<$FireflySyncMetaTable, FireflySyncMetaEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FireflySyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'firefly_sync_meta';
  @override
  VerificationContext validateIntegrity(
      Insertable<FireflySyncMetaEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  FireflySyncMetaEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FireflySyncMetaEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $FireflySyncMetaTable createAlias(String alias) {
    return $FireflySyncMetaTable(attachedDatabase, alias);
  }
}

class FireflySyncMetaEntry extends DataClass
    implements Insertable<FireflySyncMetaEntry> {
  final String key;
  final String value;
  const FireflySyncMetaEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  FireflySyncMetaCompanion toCompanion(bool nullToAbsent) {
    return FireflySyncMetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory FireflySyncMetaEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FireflySyncMetaEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  FireflySyncMetaEntry copyWith({String? key, String? value}) =>
      FireflySyncMetaEntry(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  @override
  String toString() {
    return (StringBuffer('FireflySyncMetaEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FireflySyncMetaEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class FireflySyncMetaCompanion extends UpdateCompanion<FireflySyncMetaEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const FireflySyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FireflySyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<FireflySyncMetaEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FireflySyncMetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return FireflySyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FireflySyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FireflyConflictsTable extends FireflyConflicts
    with TableInfo<$FireflyConflictsTable, FireflyConflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FireflyConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conflictPkMeta =
      const VerificationMeta('conflictPk');
  @override
  late final GeneratedColumn<String> conflictPk = GeneratedColumn<String>(
      'conflict_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumnWithTypeConverter<FireflyEntityType, int>
      entityType = GeneratedColumn<int>('entity_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<FireflyEntityType>(
              $FireflyConflictsTable.$converterentityType);
  static const VerificationMeta _localPkMeta =
      const VerificationMeta('localPk');
  @override
  late final GeneratedColumn<String> localPk = GeneratedColumn<String>(
      'local_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localJsonMeta =
      const VerificationMeta('localJson');
  @override
  late final GeneratedColumn<String> localJson = GeneratedColumn<String>(
      'local_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteJsonMeta =
      const VerificationMeta('remoteJson');
  @override
  late final GeneratedColumn<String> remoteJson = GeneratedColumn<String>(
      'remote_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _resolutionMeta =
      const VerificationMeta('resolution');
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
      'resolution', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: DateTime.now);
  static const VerificationMeta _acknowledgedMeta =
      const VerificationMeta('acknowledged');
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
      'acknowledged', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("acknowledged" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        conflictPk,
        entityType,
        localPk,
        remoteId,
        localJson,
        remoteJson,
        resolution,
        dateCreated,
        acknowledged
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'firefly_conflicts';
  @override
  VerificationContext validateIntegrity(Insertable<FireflyConflict> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conflict_pk')) {
      context.handle(
          _conflictPkMeta,
          conflictPk.isAcceptableOrUnknown(
              data['conflict_pk']!, _conflictPkMeta));
    }
    context.handle(_entityTypeMeta, const VerificationResult.success());
    if (data.containsKey('local_pk')) {
      context.handle(_localPkMeta,
          localPk.isAcceptableOrUnknown(data['local_pk']!, _localPkMeta));
    } else if (isInserting) {
      context.missing(_localPkMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('local_json')) {
      context.handle(_localJsonMeta,
          localJson.isAcceptableOrUnknown(data['local_json']!, _localJsonMeta));
    } else if (isInserting) {
      context.missing(_localJsonMeta);
    }
    if (data.containsKey('remote_json')) {
      context.handle(
          _remoteJsonMeta,
          remoteJson.isAcceptableOrUnknown(
              data['remote_json']!, _remoteJsonMeta));
    }
    if (data.containsKey('resolution')) {
      context.handle(
          _resolutionMeta,
          resolution.isAcceptableOrUnknown(
              data['resolution']!, _resolutionMeta));
    } else if (isInserting) {
      context.missing(_resolutionMeta);
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
          _acknowledgedMeta,
          acknowledged.isAcceptableOrUnknown(
              data['acknowledged']!, _acknowledgedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conflictPk};
  @override
  FireflyConflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FireflyConflict(
      conflictPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conflict_pk'])!,
      entityType: $FireflyConflictsTable.$converterentityType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}entity_type'])!),
      localPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_pk'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id'])!,
      localJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_json'])!,
      remoteJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_json']),
      resolution: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resolution'])!,
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      acknowledged: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}acknowledged'])!,
    );
  }

  @override
  $FireflyConflictsTable createAlias(String alias) {
    return $FireflyConflictsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FireflyEntityType, int, int> $converterentityType =
      const EnumIndexConverter<FireflyEntityType>(FireflyEntityType.values);
}

class FireflyConflict extends DataClass implements Insertable<FireflyConflict> {
  final String conflictPk;
  final FireflyEntityType entityType;
  final String localPk;
  final String remoteId;
  final String localJson;
  final String? remoteJson;
  final String resolution;
  final DateTime dateCreated;
  final bool acknowledged;
  const FireflyConflict(
      {required this.conflictPk,
      required this.entityType,
      required this.localPk,
      required this.remoteId,
      required this.localJson,
      this.remoteJson,
      required this.resolution,
      required this.dateCreated,
      required this.acknowledged});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conflict_pk'] = Variable<String>(conflictPk);
    {
      map['entity_type'] = Variable<int>(
          $FireflyConflictsTable.$converterentityType.toSql(entityType));
    }
    map['local_pk'] = Variable<String>(localPk);
    map['remote_id'] = Variable<String>(remoteId);
    map['local_json'] = Variable<String>(localJson);
    if (!nullToAbsent || remoteJson != null) {
      map['remote_json'] = Variable<String>(remoteJson);
    }
    map['resolution'] = Variable<String>(resolution);
    map['date_created'] = Variable<DateTime>(dateCreated);
    map['acknowledged'] = Variable<bool>(acknowledged);
    return map;
  }

  FireflyConflictsCompanion toCompanion(bool nullToAbsent) {
    return FireflyConflictsCompanion(
      conflictPk: Value(conflictPk),
      entityType: Value(entityType),
      localPk: Value(localPk),
      remoteId: Value(remoteId),
      localJson: Value(localJson),
      remoteJson: remoteJson == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteJson),
      resolution: Value(resolution),
      dateCreated: Value(dateCreated),
      acknowledged: Value(acknowledged),
    );
  }

  factory FireflyConflict.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FireflyConflict(
      conflictPk: serializer.fromJson<String>(json['conflictPk']),
      entityType: $FireflyConflictsTable.$converterentityType
          .fromJson(serializer.fromJson<int>(json['entityType'])),
      localPk: serializer.fromJson<String>(json['localPk']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      localJson: serializer.fromJson<String>(json['localJson']),
      remoteJson: serializer.fromJson<String?>(json['remoteJson']),
      resolution: serializer.fromJson<String>(json['resolution']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conflictPk': serializer.toJson<String>(conflictPk),
      'entityType': serializer.toJson<int>(
          $FireflyConflictsTable.$converterentityType.toJson(entityType)),
      'localPk': serializer.toJson<String>(localPk),
      'remoteId': serializer.toJson<String>(remoteId),
      'localJson': serializer.toJson<String>(localJson),
      'remoteJson': serializer.toJson<String?>(remoteJson),
      'resolution': serializer.toJson<String>(resolution),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'acknowledged': serializer.toJson<bool>(acknowledged),
    };
  }

  FireflyConflict copyWith(
          {String? conflictPk,
          FireflyEntityType? entityType,
          String? localPk,
          String? remoteId,
          String? localJson,
          Value<String?> remoteJson = const Value.absent(),
          String? resolution,
          DateTime? dateCreated,
          bool? acknowledged}) =>
      FireflyConflict(
        conflictPk: conflictPk ?? this.conflictPk,
        entityType: entityType ?? this.entityType,
        localPk: localPk ?? this.localPk,
        remoteId: remoteId ?? this.remoteId,
        localJson: localJson ?? this.localJson,
        remoteJson: remoteJson.present ? remoteJson.value : this.remoteJson,
        resolution: resolution ?? this.resolution,
        dateCreated: dateCreated ?? this.dateCreated,
        acknowledged: acknowledged ?? this.acknowledged,
      );
  @override
  String toString() {
    return (StringBuffer('FireflyConflict(')
          ..write('conflictPk: $conflictPk, ')
          ..write('entityType: $entityType, ')
          ..write('localPk: $localPk, ')
          ..write('remoteId: $remoteId, ')
          ..write('localJson: $localJson, ')
          ..write('remoteJson: $remoteJson, ')
          ..write('resolution: $resolution, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('acknowledged: $acknowledged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(conflictPk, entityType, localPk, remoteId,
      localJson, remoteJson, resolution, dateCreated, acknowledged);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FireflyConflict &&
          other.conflictPk == this.conflictPk &&
          other.entityType == this.entityType &&
          other.localPk == this.localPk &&
          other.remoteId == this.remoteId &&
          other.localJson == this.localJson &&
          other.remoteJson == this.remoteJson &&
          other.resolution == this.resolution &&
          other.dateCreated == this.dateCreated &&
          other.acknowledged == this.acknowledged);
}

class FireflyConflictsCompanion extends UpdateCompanion<FireflyConflict> {
  final Value<String> conflictPk;
  final Value<FireflyEntityType> entityType;
  final Value<String> localPk;
  final Value<String> remoteId;
  final Value<String> localJson;
  final Value<String?> remoteJson;
  final Value<String> resolution;
  final Value<DateTime> dateCreated;
  final Value<bool> acknowledged;
  final Value<int> rowid;
  const FireflyConflictsCompanion({
    this.conflictPk = const Value.absent(),
    this.entityType = const Value.absent(),
    this.localPk = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.localJson = const Value.absent(),
    this.remoteJson = const Value.absent(),
    this.resolution = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FireflyConflictsCompanion.insert({
    this.conflictPk = const Value.absent(),
    required FireflyEntityType entityType,
    required String localPk,
    required String remoteId,
    required String localJson,
    this.remoteJson = const Value.absent(),
    required String resolution,
    this.dateCreated = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : entityType = Value(entityType),
        localPk = Value(localPk),
        remoteId = Value(remoteId),
        localJson = Value(localJson),
        resolution = Value(resolution);
  static Insertable<FireflyConflict> custom({
    Expression<String>? conflictPk,
    Expression<int>? entityType,
    Expression<String>? localPk,
    Expression<String>? remoteId,
    Expression<String>? localJson,
    Expression<String>? remoteJson,
    Expression<String>? resolution,
    Expression<DateTime>? dateCreated,
    Expression<bool>? acknowledged,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conflictPk != null) 'conflict_pk': conflictPk,
      if (entityType != null) 'entity_type': entityType,
      if (localPk != null) 'local_pk': localPk,
      if (remoteId != null) 'remote_id': remoteId,
      if (localJson != null) 'local_json': localJson,
      if (remoteJson != null) 'remote_json': remoteJson,
      if (resolution != null) 'resolution': resolution,
      if (dateCreated != null) 'date_created': dateCreated,
      if (acknowledged != null) 'acknowledged': acknowledged,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FireflyConflictsCompanion copyWith(
      {Value<String>? conflictPk,
      Value<FireflyEntityType>? entityType,
      Value<String>? localPk,
      Value<String>? remoteId,
      Value<String>? localJson,
      Value<String?>? remoteJson,
      Value<String>? resolution,
      Value<DateTime>? dateCreated,
      Value<bool>? acknowledged,
      Value<int>? rowid}) {
    return FireflyConflictsCompanion(
      conflictPk: conflictPk ?? this.conflictPk,
      entityType: entityType ?? this.entityType,
      localPk: localPk ?? this.localPk,
      remoteId: remoteId ?? this.remoteId,
      localJson: localJson ?? this.localJson,
      remoteJson: remoteJson ?? this.remoteJson,
      resolution: resolution ?? this.resolution,
      dateCreated: dateCreated ?? this.dateCreated,
      acknowledged: acknowledged ?? this.acknowledged,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conflictPk.present) {
      map['conflict_pk'] = Variable<String>(conflictPk.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<int>(
          $FireflyConflictsTable.$converterentityType.toSql(entityType.value));
    }
    if (localPk.present) {
      map['local_pk'] = Variable<String>(localPk.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (localJson.present) {
      map['local_json'] = Variable<String>(localJson.value);
    }
    if (remoteJson.present) {
      map['remote_json'] = Variable<String>(remoteJson.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FireflyConflictsCompanion(')
          ..write('conflictPk: $conflictPk, ')
          ..write('entityType: $entityType, ')
          ..write('localPk: $localPk, ')
          ..write('remoteId: $remoteId, ')
          ..write('localJson: $localJson, ')
          ..write('remoteJson: $remoteJson, ')
          ..write('resolution: $resolution, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FireflyResourceCacheTable extends FireflyResourceCache
    with TableInfo<$FireflyResourceCacheTable, FireflyCachedResource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FireflyResourceCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourcePkMeta =
      const VerificationMeta('resourcePk');
  @override
  late final GeneratedColumn<String> resourcePk = GeneratedColumn<String>(
      'resource_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumnWithTypeConverter<FireflyEntityType, int>
      entityType = GeneratedColumn<int>('entity_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<FireflyEntityType>(
              $FireflyResourceCacheTable.$converterentityType);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [resourcePk, entityType, json, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'firefly_resource_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<FireflyCachedResource> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_pk')) {
      context.handle(
          _resourcePkMeta,
          resourcePk.isAcceptableOrUnknown(
              data['resource_pk']!, _resourcePkMeta));
    } else if (isInserting) {
      context.missing(_resourcePkMeta);
    }
    context.handle(_entityTypeMeta, const VerificationResult.success());
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourcePk};
  @override
  FireflyCachedResource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FireflyCachedResource(
      resourcePk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_pk'])!,
      entityType: $FireflyResourceCacheTable.$converterentityType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}entity_type'])!),
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
    );
  }

  @override
  $FireflyResourceCacheTable createAlias(String alias) {
    return $FireflyResourceCacheTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FireflyEntityType, int, int> $converterentityType =
      const EnumIndexConverter<FireflyEntityType>(FireflyEntityType.values);
}

class FireflyCachedResource extends DataClass
    implements Insertable<FireflyCachedResource> {
  final String resourcePk;
  final FireflyEntityType entityType;
  final String json;
  final DateTime? dateTimeModified;
  const FireflyCachedResource(
      {required this.resourcePk,
      required this.entityType,
      required this.json,
      this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_pk'] = Variable<String>(resourcePk);
    {
      map['entity_type'] = Variable<int>(
          $FireflyResourceCacheTable.$converterentityType.toSql(entityType));
    }
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    return map;
  }

  FireflyResourceCacheCompanion toCompanion(bool nullToAbsent) {
    return FireflyResourceCacheCompanion(
      resourcePk: Value(resourcePk),
      entityType: Value(entityType),
      json: Value(json),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
    );
  }

  factory FireflyCachedResource.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FireflyCachedResource(
      resourcePk: serializer.fromJson<String>(json['resourcePk']),
      entityType: $FireflyResourceCacheTable.$converterentityType
          .fromJson(serializer.fromJson<int>(json['entityType'])),
      json: serializer.fromJson<String>(json['json']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourcePk': serializer.toJson<String>(resourcePk),
      'entityType': serializer.toJson<int>(
          $FireflyResourceCacheTable.$converterentityType.toJson(entityType)),
      'json': serializer.toJson<String>(json),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
    };
  }

  FireflyCachedResource copyWith(
          {String? resourcePk,
          FireflyEntityType? entityType,
          String? json,
          Value<DateTime?> dateTimeModified = const Value.absent()}) =>
      FireflyCachedResource(
        resourcePk: resourcePk ?? this.resourcePk,
        entityType: entityType ?? this.entityType,
        json: json ?? this.json,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('FireflyCachedResource(')
          ..write('resourcePk: $resourcePk, ')
          ..write('entityType: $entityType, ')
          ..write('json: $json, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(resourcePk, entityType, json, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FireflyCachedResource &&
          other.resourcePk == this.resourcePk &&
          other.entityType == this.entityType &&
          other.json == this.json &&
          other.dateTimeModified == this.dateTimeModified);
}

class FireflyResourceCacheCompanion
    extends UpdateCompanion<FireflyCachedResource> {
  final Value<String> resourcePk;
  final Value<FireflyEntityType> entityType;
  final Value<String> json;
  final Value<DateTime?> dateTimeModified;
  final Value<int> rowid;
  const FireflyResourceCacheCompanion({
    this.resourcePk = const Value.absent(),
    this.entityType = const Value.absent(),
    this.json = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FireflyResourceCacheCompanion.insert({
    required String resourcePk,
    required FireflyEntityType entityType,
    required String json,
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : resourcePk = Value(resourcePk),
        entityType = Value(entityType),
        json = Value(json);
  static Insertable<FireflyCachedResource> custom({
    Expression<String>? resourcePk,
    Expression<int>? entityType,
    Expression<String>? json,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourcePk != null) 'resource_pk': resourcePk,
      if (entityType != null) 'entity_type': entityType,
      if (json != null) 'json': json,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FireflyResourceCacheCompanion copyWith(
      {Value<String>? resourcePk,
      Value<FireflyEntityType>? entityType,
      Value<String>? json,
      Value<DateTime?>? dateTimeModified,
      Value<int>? rowid}) {
    return FireflyResourceCacheCompanion(
      resourcePk: resourcePk ?? this.resourcePk,
      entityType: entityType ?? this.entityType,
      json: json ?? this.json,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourcePk.present) {
      map['resource_pk'] = Variable<String>(resourcePk.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<int>($FireflyResourceCacheTable
          .$converterentityType
          .toSql(entityType.value));
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FireflyResourceCacheCompanion(')
          ..write('resourcePk: $resourcePk, ')
          ..write('entityType: $entityType, ')
          ..write('json: $json, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tagPkMeta = const VerificationMeta('tagPk');
  @override
  late final GeneratedColumn<String> tagPk = GeneratedColumn<String>(
      'tag_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: DateTime.now);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [tagPk, name, description, date, dateCreated, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tag_pk')) {
      context.handle(
          _tagPkMeta, tagPk.isAcceptableOrUnknown(data['tag_pk']!, _tagPkMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tagPk};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      tagPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_pk'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date']),
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String tagPk;
  final String name;
  final String? description;
  final DateTime? date;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  const Tag(
      {required this.tagPk,
      required this.name,
      this.description,
      this.date,
      required this.dateCreated,
      this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tag_pk'] = Variable<String>(tagPk);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<DateTime>(date);
    }
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      tagPk: Value(tagPk),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      tagPk: serializer.fromJson<String>(json['tagPk']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      date: serializer.fromJson<DateTime?>(json['date']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tagPk': serializer.toJson<String>(tagPk),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'date': serializer.toJson<DateTime?>(date),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
    };
  }

  Tag copyWith(
          {String? tagPk,
          String? name,
          Value<String?> description = const Value.absent(),
          Value<DateTime?> date = const Value.absent(),
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent()}) =>
      Tag(
        tagPk: tagPk ?? this.tagPk,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        date: date.present ? date.value : this.date,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('tagPk: $tagPk, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      tagPk, name, description, date, dateCreated, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.tagPk == this.tagPk &&
          other.name == this.name &&
          other.description == this.description &&
          other.date == this.date &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> tagPk;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime?> date;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<int> rowid;
  const TagsCompanion({
    this.tagPk = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.date = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    this.tagPk = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.date = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? tagPk,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? date,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tagPk != null) 'tag_pk': tagPk,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (date != null) 'date': date,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith(
      {Value<String>? tagPk,
      Value<String>? name,
      Value<String?>? description,
      Value<DateTime?>? date,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<int>? rowid}) {
    return TagsCompanion(
      tagPk: tagPk ?? this.tagPk,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tagPk.present) {
      map['tag_pk'] = Variable<String>(tagPk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('tagPk: $tagPk, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionTagsTable extends TransactionTags
    with TableInfo<$TransactionTagsTable, TransactionTagLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionFkMeta =
      const VerificationMeta('transactionFk');
  @override
  late final GeneratedColumn<String> transactionFk = GeneratedColumn<String>(
      'transaction_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES transactions (transaction_pk) ON DELETE CASCADE'));
  static const VerificationMeta _tagFkMeta = const VerificationMeta('tagFk');
  @override
  late final GeneratedColumn<String> tagFk = GeneratedColumn<String>(
      'tag_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tags (tag_pk) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [transactionFk, tagFk];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_tags';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionTagLink> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_fk')) {
      context.handle(
          _transactionFkMeta,
          transactionFk.isAcceptableOrUnknown(
              data['transaction_fk']!, _transactionFkMeta));
    } else if (isInserting) {
      context.missing(_transactionFkMeta);
    }
    if (data.containsKey('tag_fk')) {
      context.handle(
          _tagFkMeta, tagFk.isAcceptableOrUnknown(data['tag_fk']!, _tagFkMeta));
    } else if (isInserting) {
      context.missing(_tagFkMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionFk, tagFk};
  @override
  TransactionTagLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionTagLink(
      transactionFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_fk'])!,
      tagFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_fk'])!,
    );
  }

  @override
  $TransactionTagsTable createAlias(String alias) {
    return $TransactionTagsTable(attachedDatabase, alias);
  }
}

class TransactionTagLink extends DataClass
    implements Insertable<TransactionTagLink> {
  final String transactionFk;
  final String tagFk;
  const TransactionTagLink({required this.transactionFk, required this.tagFk});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_fk'] = Variable<String>(transactionFk);
    map['tag_fk'] = Variable<String>(tagFk);
    return map;
  }

  TransactionTagsCompanion toCompanion(bool nullToAbsent) {
    return TransactionTagsCompanion(
      transactionFk: Value(transactionFk),
      tagFk: Value(tagFk),
    );
  }

  factory TransactionTagLink.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionTagLink(
      transactionFk: serializer.fromJson<String>(json['transactionFk']),
      tagFk: serializer.fromJson<String>(json['tagFk']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionFk': serializer.toJson<String>(transactionFk),
      'tagFk': serializer.toJson<String>(tagFk),
    };
  }

  TransactionTagLink copyWith({String? transactionFk, String? tagFk}) =>
      TransactionTagLink(
        transactionFk: transactionFk ?? this.transactionFk,
        tagFk: tagFk ?? this.tagFk,
      );
  @override
  String toString() {
    return (StringBuffer('TransactionTagLink(')
          ..write('transactionFk: $transactionFk, ')
          ..write('tagFk: $tagFk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(transactionFk, tagFk);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionTagLink &&
          other.transactionFk == this.transactionFk &&
          other.tagFk == this.tagFk);
}

class TransactionTagsCompanion extends UpdateCompanion<TransactionTagLink> {
  final Value<String> transactionFk;
  final Value<String> tagFk;
  final Value<int> rowid;
  const TransactionTagsCompanion({
    this.transactionFk = const Value.absent(),
    this.tagFk = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionTagsCompanion.insert({
    required String transactionFk,
    required String tagFk,
    this.rowid = const Value.absent(),
  })  : transactionFk = Value(transactionFk),
        tagFk = Value(tagFk);
  static Insertable<TransactionTagLink> custom({
    Expression<String>? transactionFk,
    Expression<String>? tagFk,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionFk != null) 'transaction_fk': transactionFk,
      if (tagFk != null) 'tag_fk': tagFk,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionTagsCompanion copyWith(
      {Value<String>? transactionFk, Value<String>? tagFk, Value<int>? rowid}) {
    return TransactionTagsCompanion(
      transactionFk: transactionFk ?? this.transactionFk,
      tagFk: tagFk ?? this.tagFk,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionFk.present) {
      map['transaction_fk'] = Variable<String>(transactionFk.value);
    }
    if (tagFk.present) {
      map['tag_fk'] = Variable<String>(tagFk.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTagsCompanion(')
          ..write('transactionFk: $transactionFk, ')
          ..write('tagFk: $tagFk, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentPkMeta =
      const VerificationMeta('attachmentPk');
  @override
  late final GeneratedColumn<String> attachmentPk = GeneratedColumn<String>(
      'attachment_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _attachableTypeMeta =
      const VerificationMeta('attachableType');
  @override
  late final GeneratedColumn<String> attachableType = GeneratedColumn<String>(
      'attachable_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attachableFkMeta =
      const VerificationMeta('attachableFk');
  @override
  late final GeneratedColumn<String> attachableFk = GeneratedColumn<String>(
      'attachable_fk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
      'mime', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
      'hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _uploadStateMeta =
      const VerificationMeta('uploadState');
  @override
  late final GeneratedColumn<String> uploadState = GeneratedColumn<String>(
      'upload_state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: DateTime.now);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        attachmentPk,
        attachableType,
        attachableFk,
        filename,
        title,
        mime,
        size,
        localPath,
        hash,
        uploadState,
        dateCreated,
        dateTimeModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(Insertable<Attachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_pk')) {
      context.handle(
          _attachmentPkMeta,
          attachmentPk.isAcceptableOrUnknown(
              data['attachment_pk']!, _attachmentPkMeta));
    }
    if (data.containsKey('attachable_type')) {
      context.handle(
          _attachableTypeMeta,
          attachableType.isAcceptableOrUnknown(
              data['attachable_type']!, _attachableTypeMeta));
    } else if (isInserting) {
      context.missing(_attachableTypeMeta);
    }
    if (data.containsKey('attachable_fk')) {
      context.handle(
          _attachableFkMeta,
          attachableFk.isAcceptableOrUnknown(
              data['attachable_fk']!, _attachableFkMeta));
    } else if (isInserting) {
      context.missing(_attachableFkMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('mime')) {
      context.handle(
          _mimeMeta, mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta));
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    }
    if (data.containsKey('upload_state')) {
      context.handle(
          _uploadStateMeta,
          uploadState.isAcceptableOrUnknown(
              data['upload_state']!, _uploadStateMeta));
    } else if (isInserting) {
      context.missing(_uploadStateMeta);
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentPk};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      attachmentPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachment_pk'])!,
      attachableType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}attachable_type'])!,
      attachableFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachable_fk'])!,
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      mime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime']),
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size']),
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash']),
      uploadState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}upload_state'])!,
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String attachmentPk;
  final String attachableType;
  final String attachableFk;
  final String filename;
  final String? title;
  final String? mime;
  final int? size;
  final String? localPath;
  final String? hash;
  final String uploadState;
  final DateTime dateCreated;
  final DateTime? dateTimeModified;
  const Attachment(
      {required this.attachmentPk,
      required this.attachableType,
      required this.attachableFk,
      required this.filename,
      this.title,
      this.mime,
      this.size,
      this.localPath,
      this.hash,
      required this.uploadState,
      required this.dateCreated,
      this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_pk'] = Variable<String>(attachmentPk);
    map['attachable_type'] = Variable<String>(attachableType);
    map['attachable_fk'] = Variable<String>(attachableFk);
    map['filename'] = Variable<String>(filename);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || mime != null) {
      map['mime'] = Variable<String>(mime);
    }
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<int>(size);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || hash != null) {
      map['hash'] = Variable<String>(hash);
    }
    map['upload_state'] = Variable<String>(uploadState);
    map['date_created'] = Variable<DateTime>(dateCreated);
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      attachmentPk: Value(attachmentPk),
      attachableType: Value(attachableType),
      attachableFk: Value(attachableFk),
      filename: Value(filename),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      mime: mime == null && nullToAbsent ? const Value.absent() : Value(mime),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      hash: hash == null && nullToAbsent ? const Value.absent() : Value(hash),
      uploadState: Value(uploadState),
      dateCreated: Value(dateCreated),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
    );
  }

  factory Attachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      attachmentPk: serializer.fromJson<String>(json['attachmentPk']),
      attachableType: serializer.fromJson<String>(json['attachableType']),
      attachableFk: serializer.fromJson<String>(json['attachableFk']),
      filename: serializer.fromJson<String>(json['filename']),
      title: serializer.fromJson<String?>(json['title']),
      mime: serializer.fromJson<String?>(json['mime']),
      size: serializer.fromJson<int?>(json['size']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      hash: serializer.fromJson<String?>(json['hash']),
      uploadState: serializer.fromJson<String>(json['uploadState']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentPk': serializer.toJson<String>(attachmentPk),
      'attachableType': serializer.toJson<String>(attachableType),
      'attachableFk': serializer.toJson<String>(attachableFk),
      'filename': serializer.toJson<String>(filename),
      'title': serializer.toJson<String?>(title),
      'mime': serializer.toJson<String?>(mime),
      'size': serializer.toJson<int?>(size),
      'localPath': serializer.toJson<String?>(localPath),
      'hash': serializer.toJson<String?>(hash),
      'uploadState': serializer.toJson<String>(uploadState),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
    };
  }

  Attachment copyWith(
          {String? attachmentPk,
          String? attachableType,
          String? attachableFk,
          String? filename,
          Value<String?> title = const Value.absent(),
          Value<String?> mime = const Value.absent(),
          Value<int?> size = const Value.absent(),
          Value<String?> localPath = const Value.absent(),
          Value<String?> hash = const Value.absent(),
          String? uploadState,
          DateTime? dateCreated,
          Value<DateTime?> dateTimeModified = const Value.absent()}) =>
      Attachment(
        attachmentPk: attachmentPk ?? this.attachmentPk,
        attachableType: attachableType ?? this.attachableType,
        attachableFk: attachableFk ?? this.attachableFk,
        filename: filename ?? this.filename,
        title: title.present ? title.value : this.title,
        mime: mime.present ? mime.value : this.mime,
        size: size.present ? size.value : this.size,
        localPath: localPath.present ? localPath.value : this.localPath,
        hash: hash.present ? hash.value : this.hash,
        uploadState: uploadState ?? this.uploadState,
        dateCreated: dateCreated ?? this.dateCreated,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('attachmentPk: $attachmentPk, ')
          ..write('attachableType: $attachableType, ')
          ..write('attachableFk: $attachableFk, ')
          ..write('filename: $filename, ')
          ..write('title: $title, ')
          ..write('mime: $mime, ')
          ..write('size: $size, ')
          ..write('localPath: $localPath, ')
          ..write('hash: $hash, ')
          ..write('uploadState: $uploadState, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      attachmentPk,
      attachableType,
      attachableFk,
      filename,
      title,
      mime,
      size,
      localPath,
      hash,
      uploadState,
      dateCreated,
      dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.attachmentPk == this.attachmentPk &&
          other.attachableType == this.attachableType &&
          other.attachableFk == this.attachableFk &&
          other.filename == this.filename &&
          other.title == this.title &&
          other.mime == this.mime &&
          other.size == this.size &&
          other.localPath == this.localPath &&
          other.hash == this.hash &&
          other.uploadState == this.uploadState &&
          other.dateCreated == this.dateCreated &&
          other.dateTimeModified == this.dateTimeModified);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> attachmentPk;
  final Value<String> attachableType;
  final Value<String> attachableFk;
  final Value<String> filename;
  final Value<String?> title;
  final Value<String?> mime;
  final Value<int?> size;
  final Value<String?> localPath;
  final Value<String?> hash;
  final Value<String> uploadState;
  final Value<DateTime> dateCreated;
  final Value<DateTime?> dateTimeModified;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.attachmentPk = const Value.absent(),
    this.attachableType = const Value.absent(),
    this.attachableFk = const Value.absent(),
    this.filename = const Value.absent(),
    this.title = const Value.absent(),
    this.mime = const Value.absent(),
    this.size = const Value.absent(),
    this.localPath = const Value.absent(),
    this.hash = const Value.absent(),
    this.uploadState = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    this.attachmentPk = const Value.absent(),
    required String attachableType,
    required String attachableFk,
    required String filename,
    this.title = const Value.absent(),
    this.mime = const Value.absent(),
    this.size = const Value.absent(),
    this.localPath = const Value.absent(),
    this.hash = const Value.absent(),
    required String uploadState,
    this.dateCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : attachableType = Value(attachableType),
        attachableFk = Value(attachableFk),
        filename = Value(filename),
        uploadState = Value(uploadState);
  static Insertable<Attachment> custom({
    Expression<String>? attachmentPk,
    Expression<String>? attachableType,
    Expression<String>? attachableFk,
    Expression<String>? filename,
    Expression<String>? title,
    Expression<String>? mime,
    Expression<int>? size,
    Expression<String>? localPath,
    Expression<String>? hash,
    Expression<String>? uploadState,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentPk != null) 'attachment_pk': attachmentPk,
      if (attachableType != null) 'attachable_type': attachableType,
      if (attachableFk != null) 'attachable_fk': attachableFk,
      if (filename != null) 'filename': filename,
      if (title != null) 'title': title,
      if (mime != null) 'mime': mime,
      if (size != null) 'size': size,
      if (localPath != null) 'local_path': localPath,
      if (hash != null) 'hash': hash,
      if (uploadState != null) 'upload_state': uploadState,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<String>? attachmentPk,
      Value<String>? attachableType,
      Value<String>? attachableFk,
      Value<String>? filename,
      Value<String?>? title,
      Value<String?>? mime,
      Value<int?>? size,
      Value<String?>? localPath,
      Value<String?>? hash,
      Value<String>? uploadState,
      Value<DateTime>? dateCreated,
      Value<DateTime?>? dateTimeModified,
      Value<int>? rowid}) {
    return AttachmentsCompanion(
      attachmentPk: attachmentPk ?? this.attachmentPk,
      attachableType: attachableType ?? this.attachableType,
      attachableFk: attachableFk ?? this.attachableFk,
      filename: filename ?? this.filename,
      title: title ?? this.title,
      mime: mime ?? this.mime,
      size: size ?? this.size,
      localPath: localPath ?? this.localPath,
      hash: hash ?? this.hash,
      uploadState: uploadState ?? this.uploadState,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentPk.present) {
      map['attachment_pk'] = Variable<String>(attachmentPk.value);
    }
    if (attachableType.present) {
      map['attachable_type'] = Variable<String>(attachableType.value);
    }
    if (attachableFk.present) {
      map['attachable_fk'] = Variable<String>(attachableFk.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (uploadState.present) {
      map['upload_state'] = Variable<String>(uploadState.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('attachmentPk: $attachmentPk, ')
          ..write('attachableType: $attachableType, ')
          ..write('attachableFk: $attachableFk, ')
          ..write('filename: $filename, ')
          ..write('title: $title, ')
          ..write('mime: $mime, ')
          ..write('size: $size, ')
          ..write('localPath: $localPath, ')
          ..write('hash: $hash, ')
          ..write('uploadState: $uploadState, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountDetailsTable extends AccountDetails
    with TableInfo<$AccountDetailsTable, AccountDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _walletFkMeta =
      const VerificationMeta('walletFk');
  @override
  late final GeneratedColumn<String> walletFk = GeneratedColumn<String>(
      'wallet_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (wallet_pk)'));
  static const VerificationMeta _accountRoleMeta =
      const VerificationMeta('accountRole');
  @override
  late final GeneratedColumn<String> accountRole = GeneratedColumn<String>(
      'account_role', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _liabilityTypeMeta =
      const VerificationMeta('liabilityType');
  @override
  late final GeneratedColumn<String> liabilityType = GeneratedColumn<String>(
      'liability_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _liabilityDirectionMeta =
      const VerificationMeta('liabilityDirection');
  @override
  late final GeneratedColumn<String> liabilityDirection =
      GeneratedColumn<String>('liability_direction', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _interestMeta =
      const VerificationMeta('interest');
  @override
  late final GeneratedColumn<double> interest = GeneratedColumn<double>(
      'interest', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _interestPeriodMeta =
      const VerificationMeta('interestPeriod');
  @override
  late final GeneratedColumn<String> interestPeriod = GeneratedColumn<String>(
      'interest_period', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ibanMeta = const VerificationMeta('iban');
  @override
  late final GeneratedColumn<String> iban = GeneratedColumn<String>(
      'iban', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bicMeta = const VerificationMeta('bic');
  @override
  late final GeneratedColumn<String> bic = GeneratedColumn<String>(
      'bic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accountNumberMeta =
      const VerificationMeta('accountNumber');
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
      'account_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _includeNetWorthMeta =
      const VerificationMeta('includeNetWorth');
  @override
  late final GeneratedColumn<bool> includeNetWorth = GeneratedColumn<bool>(
      'include_net_worth', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("include_net_worth" IN (0, 1))'));
  static const VerificationMeta _virtualBalanceMeta =
      const VerificationMeta('virtualBalance');
  @override
  late final GeneratedColumn<double> virtualBalance = GeneratedColumn<double>(
      'virtual_balance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _serverBalanceMeta =
      const VerificationMeta('serverBalance');
  @override
  late final GeneratedColumn<double> serverBalance = GeneratedColumn<double>(
      'server_balance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _serverBalanceDateMeta =
      const VerificationMeta('serverBalanceDate');
  @override
  late final GeneratedColumn<DateTime> serverBalanceDate =
      GeneratedColumn<DateTime>('server_balance_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        walletFk,
        accountRole,
        liabilityType,
        liabilityDirection,
        interest,
        interestPeriod,
        iban,
        bic,
        accountNumber,
        notes,
        includeNetWorth,
        virtualBalance,
        serverBalance,
        serverBalanceDate,
        dateTimeModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_details';
  @override
  VerificationContext validateIntegrity(Insertable<AccountDetail> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('wallet_fk')) {
      context.handle(_walletFkMeta,
          walletFk.isAcceptableOrUnknown(data['wallet_fk']!, _walletFkMeta));
    } else if (isInserting) {
      context.missing(_walletFkMeta);
    }
    if (data.containsKey('account_role')) {
      context.handle(
          _accountRoleMeta,
          accountRole.isAcceptableOrUnknown(
              data['account_role']!, _accountRoleMeta));
    }
    if (data.containsKey('liability_type')) {
      context.handle(
          _liabilityTypeMeta,
          liabilityType.isAcceptableOrUnknown(
              data['liability_type']!, _liabilityTypeMeta));
    }
    if (data.containsKey('liability_direction')) {
      context.handle(
          _liabilityDirectionMeta,
          liabilityDirection.isAcceptableOrUnknown(
              data['liability_direction']!, _liabilityDirectionMeta));
    }
    if (data.containsKey('interest')) {
      context.handle(_interestMeta,
          interest.isAcceptableOrUnknown(data['interest']!, _interestMeta));
    }
    if (data.containsKey('interest_period')) {
      context.handle(
          _interestPeriodMeta,
          interestPeriod.isAcceptableOrUnknown(
              data['interest_period']!, _interestPeriodMeta));
    }
    if (data.containsKey('iban')) {
      context.handle(
          _ibanMeta, iban.isAcceptableOrUnknown(data['iban']!, _ibanMeta));
    }
    if (data.containsKey('bic')) {
      context.handle(
          _bicMeta, bic.isAcceptableOrUnknown(data['bic']!, _bicMeta));
    }
    if (data.containsKey('account_number')) {
      context.handle(
          _accountNumberMeta,
          accountNumber.isAcceptableOrUnknown(
              data['account_number']!, _accountNumberMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('include_net_worth')) {
      context.handle(
          _includeNetWorthMeta,
          includeNetWorth.isAcceptableOrUnknown(
              data['include_net_worth']!, _includeNetWorthMeta));
    }
    if (data.containsKey('virtual_balance')) {
      context.handle(
          _virtualBalanceMeta,
          virtualBalance.isAcceptableOrUnknown(
              data['virtual_balance']!, _virtualBalanceMeta));
    }
    if (data.containsKey('server_balance')) {
      context.handle(
          _serverBalanceMeta,
          serverBalance.isAcceptableOrUnknown(
              data['server_balance']!, _serverBalanceMeta));
    }
    if (data.containsKey('server_balance_date')) {
      context.handle(
          _serverBalanceDateMeta,
          serverBalanceDate.isAcceptableOrUnknown(
              data['server_balance_date']!, _serverBalanceDateMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {walletFk};
  @override
  AccountDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountDetail(
      walletFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wallet_fk'])!,
      accountRole: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_role']),
      liabilityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}liability_type']),
      liabilityDirection: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}liability_direction']),
      interest: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}interest']),
      interestPeriod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}interest_period']),
      iban: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}iban']),
      bic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bic']),
      accountNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_number']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      includeNetWorth: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}include_net_worth']),
      virtualBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}virtual_balance']),
      serverBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}server_balance']),
      serverBalanceDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}server_balance_date']),
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
    );
  }

  @override
  $AccountDetailsTable createAlias(String alias) {
    return $AccountDetailsTable(attachedDatabase, alias);
  }
}

class AccountDetail extends DataClass implements Insertable<AccountDetail> {
  final String walletFk;
  final String? accountRole;
  final String? liabilityType;
  final String? liabilityDirection;
  final double? interest;
  final String? interestPeriod;
  final String? iban;
  final String? bic;
  final String? accountNumber;
  final String? notes;
  final bool? includeNetWorth;
  final double? virtualBalance;
  final double? serverBalance;
  final DateTime? serverBalanceDate;
  final DateTime? dateTimeModified;
  const AccountDetail(
      {required this.walletFk,
      this.accountRole,
      this.liabilityType,
      this.liabilityDirection,
      this.interest,
      this.interestPeriod,
      this.iban,
      this.bic,
      this.accountNumber,
      this.notes,
      this.includeNetWorth,
      this.virtualBalance,
      this.serverBalance,
      this.serverBalanceDate,
      this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['wallet_fk'] = Variable<String>(walletFk);
    if (!nullToAbsent || accountRole != null) {
      map['account_role'] = Variable<String>(accountRole);
    }
    if (!nullToAbsent || liabilityType != null) {
      map['liability_type'] = Variable<String>(liabilityType);
    }
    if (!nullToAbsent || liabilityDirection != null) {
      map['liability_direction'] = Variable<String>(liabilityDirection);
    }
    if (!nullToAbsent || interest != null) {
      map['interest'] = Variable<double>(interest);
    }
    if (!nullToAbsent || interestPeriod != null) {
      map['interest_period'] = Variable<String>(interestPeriod);
    }
    if (!nullToAbsent || iban != null) {
      map['iban'] = Variable<String>(iban);
    }
    if (!nullToAbsent || bic != null) {
      map['bic'] = Variable<String>(bic);
    }
    if (!nullToAbsent || accountNumber != null) {
      map['account_number'] = Variable<String>(accountNumber);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || includeNetWorth != null) {
      map['include_net_worth'] = Variable<bool>(includeNetWorth);
    }
    if (!nullToAbsent || virtualBalance != null) {
      map['virtual_balance'] = Variable<double>(virtualBalance);
    }
    if (!nullToAbsent || serverBalance != null) {
      map['server_balance'] = Variable<double>(serverBalance);
    }
    if (!nullToAbsent || serverBalanceDate != null) {
      map['server_balance_date'] = Variable<DateTime>(serverBalanceDate);
    }
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    return map;
  }

  AccountDetailsCompanion toCompanion(bool nullToAbsent) {
    return AccountDetailsCompanion(
      walletFk: Value(walletFk),
      accountRole: accountRole == null && nullToAbsent
          ? const Value.absent()
          : Value(accountRole),
      liabilityType: liabilityType == null && nullToAbsent
          ? const Value.absent()
          : Value(liabilityType),
      liabilityDirection: liabilityDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(liabilityDirection),
      interest: interest == null && nullToAbsent
          ? const Value.absent()
          : Value(interest),
      interestPeriod: interestPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(interestPeriod),
      iban: iban == null && nullToAbsent ? const Value.absent() : Value(iban),
      bic: bic == null && nullToAbsent ? const Value.absent() : Value(bic),
      accountNumber: accountNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(accountNumber),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      includeNetWorth: includeNetWorth == null && nullToAbsent
          ? const Value.absent()
          : Value(includeNetWorth),
      virtualBalance: virtualBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(virtualBalance),
      serverBalance: serverBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(serverBalance),
      serverBalanceDate: serverBalanceDate == null && nullToAbsent
          ? const Value.absent()
          : Value(serverBalanceDate),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
    );
  }

  factory AccountDetail.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountDetail(
      walletFk: serializer.fromJson<String>(json['walletFk']),
      accountRole: serializer.fromJson<String?>(json['accountRole']),
      liabilityType: serializer.fromJson<String?>(json['liabilityType']),
      liabilityDirection:
          serializer.fromJson<String?>(json['liabilityDirection']),
      interest: serializer.fromJson<double?>(json['interest']),
      interestPeriod: serializer.fromJson<String?>(json['interestPeriod']),
      iban: serializer.fromJson<String?>(json['iban']),
      bic: serializer.fromJson<String?>(json['bic']),
      accountNumber: serializer.fromJson<String?>(json['accountNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      includeNetWorth: serializer.fromJson<bool?>(json['includeNetWorth']),
      virtualBalance: serializer.fromJson<double?>(json['virtualBalance']),
      serverBalance: serializer.fromJson<double?>(json['serverBalance']),
      serverBalanceDate:
          serializer.fromJson<DateTime?>(json['serverBalanceDate']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'walletFk': serializer.toJson<String>(walletFk),
      'accountRole': serializer.toJson<String?>(accountRole),
      'liabilityType': serializer.toJson<String?>(liabilityType),
      'liabilityDirection': serializer.toJson<String?>(liabilityDirection),
      'interest': serializer.toJson<double?>(interest),
      'interestPeriod': serializer.toJson<String?>(interestPeriod),
      'iban': serializer.toJson<String?>(iban),
      'bic': serializer.toJson<String?>(bic),
      'accountNumber': serializer.toJson<String?>(accountNumber),
      'notes': serializer.toJson<String?>(notes),
      'includeNetWorth': serializer.toJson<bool?>(includeNetWorth),
      'virtualBalance': serializer.toJson<double?>(virtualBalance),
      'serverBalance': serializer.toJson<double?>(serverBalance),
      'serverBalanceDate': serializer.toJson<DateTime?>(serverBalanceDate),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
    };
  }

  AccountDetail copyWith(
          {String? walletFk,
          Value<String?> accountRole = const Value.absent(),
          Value<String?> liabilityType = const Value.absent(),
          Value<String?> liabilityDirection = const Value.absent(),
          Value<double?> interest = const Value.absent(),
          Value<String?> interestPeriod = const Value.absent(),
          Value<String?> iban = const Value.absent(),
          Value<String?> bic = const Value.absent(),
          Value<String?> accountNumber = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<bool?> includeNetWorth = const Value.absent(),
          Value<double?> virtualBalance = const Value.absent(),
          Value<double?> serverBalance = const Value.absent(),
          Value<DateTime?> serverBalanceDate = const Value.absent(),
          Value<DateTime?> dateTimeModified = const Value.absent()}) =>
      AccountDetail(
        walletFk: walletFk ?? this.walletFk,
        accountRole: accountRole.present ? accountRole.value : this.accountRole,
        liabilityType:
            liabilityType.present ? liabilityType.value : this.liabilityType,
        liabilityDirection: liabilityDirection.present
            ? liabilityDirection.value
            : this.liabilityDirection,
        interest: interest.present ? interest.value : this.interest,
        interestPeriod:
            interestPeriod.present ? interestPeriod.value : this.interestPeriod,
        iban: iban.present ? iban.value : this.iban,
        bic: bic.present ? bic.value : this.bic,
        accountNumber:
            accountNumber.present ? accountNumber.value : this.accountNumber,
        notes: notes.present ? notes.value : this.notes,
        includeNetWorth: includeNetWorth.present
            ? includeNetWorth.value
            : this.includeNetWorth,
        virtualBalance:
            virtualBalance.present ? virtualBalance.value : this.virtualBalance,
        serverBalance:
            serverBalance.present ? serverBalance.value : this.serverBalance,
        serverBalanceDate: serverBalanceDate.present
            ? serverBalanceDate.value
            : this.serverBalanceDate,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('AccountDetail(')
          ..write('walletFk: $walletFk, ')
          ..write('accountRole: $accountRole, ')
          ..write('liabilityType: $liabilityType, ')
          ..write('liabilityDirection: $liabilityDirection, ')
          ..write('interest: $interest, ')
          ..write('interestPeriod: $interestPeriod, ')
          ..write('iban: $iban, ')
          ..write('bic: $bic, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('notes: $notes, ')
          ..write('includeNetWorth: $includeNetWorth, ')
          ..write('virtualBalance: $virtualBalance, ')
          ..write('serverBalance: $serverBalance, ')
          ..write('serverBalanceDate: $serverBalanceDate, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      walletFk,
      accountRole,
      liabilityType,
      liabilityDirection,
      interest,
      interestPeriod,
      iban,
      bic,
      accountNumber,
      notes,
      includeNetWorth,
      virtualBalance,
      serverBalance,
      serverBalanceDate,
      dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountDetail &&
          other.walletFk == this.walletFk &&
          other.accountRole == this.accountRole &&
          other.liabilityType == this.liabilityType &&
          other.liabilityDirection == this.liabilityDirection &&
          other.interest == this.interest &&
          other.interestPeriod == this.interestPeriod &&
          other.iban == this.iban &&
          other.bic == this.bic &&
          other.accountNumber == this.accountNumber &&
          other.notes == this.notes &&
          other.includeNetWorth == this.includeNetWorth &&
          other.virtualBalance == this.virtualBalance &&
          other.serverBalance == this.serverBalance &&
          other.serverBalanceDate == this.serverBalanceDate &&
          other.dateTimeModified == this.dateTimeModified);
}

class AccountDetailsCompanion extends UpdateCompanion<AccountDetail> {
  final Value<String> walletFk;
  final Value<String?> accountRole;
  final Value<String?> liabilityType;
  final Value<String?> liabilityDirection;
  final Value<double?> interest;
  final Value<String?> interestPeriod;
  final Value<String?> iban;
  final Value<String?> bic;
  final Value<String?> accountNumber;
  final Value<String?> notes;
  final Value<bool?> includeNetWorth;
  final Value<double?> virtualBalance;
  final Value<double?> serverBalance;
  final Value<DateTime?> serverBalanceDate;
  final Value<DateTime?> dateTimeModified;
  final Value<int> rowid;
  const AccountDetailsCompanion({
    this.walletFk = const Value.absent(),
    this.accountRole = const Value.absent(),
    this.liabilityType = const Value.absent(),
    this.liabilityDirection = const Value.absent(),
    this.interest = const Value.absent(),
    this.interestPeriod = const Value.absent(),
    this.iban = const Value.absent(),
    this.bic = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.includeNetWorth = const Value.absent(),
    this.virtualBalance = const Value.absent(),
    this.serverBalance = const Value.absent(),
    this.serverBalanceDate = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountDetailsCompanion.insert({
    required String walletFk,
    this.accountRole = const Value.absent(),
    this.liabilityType = const Value.absent(),
    this.liabilityDirection = const Value.absent(),
    this.interest = const Value.absent(),
    this.interestPeriod = const Value.absent(),
    this.iban = const Value.absent(),
    this.bic = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.includeNetWorth = const Value.absent(),
    this.virtualBalance = const Value.absent(),
    this.serverBalance = const Value.absent(),
    this.serverBalanceDate = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : walletFk = Value(walletFk);
  static Insertable<AccountDetail> custom({
    Expression<String>? walletFk,
    Expression<String>? accountRole,
    Expression<String>? liabilityType,
    Expression<String>? liabilityDirection,
    Expression<double>? interest,
    Expression<String>? interestPeriod,
    Expression<String>? iban,
    Expression<String>? bic,
    Expression<String>? accountNumber,
    Expression<String>? notes,
    Expression<bool>? includeNetWorth,
    Expression<double>? virtualBalance,
    Expression<double>? serverBalance,
    Expression<DateTime>? serverBalanceDate,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (walletFk != null) 'wallet_fk': walletFk,
      if (accountRole != null) 'account_role': accountRole,
      if (liabilityType != null) 'liability_type': liabilityType,
      if (liabilityDirection != null) 'liability_direction': liabilityDirection,
      if (interest != null) 'interest': interest,
      if (interestPeriod != null) 'interest_period': interestPeriod,
      if (iban != null) 'iban': iban,
      if (bic != null) 'bic': bic,
      if (accountNumber != null) 'account_number': accountNumber,
      if (notes != null) 'notes': notes,
      if (includeNetWorth != null) 'include_net_worth': includeNetWorth,
      if (virtualBalance != null) 'virtual_balance': virtualBalance,
      if (serverBalance != null) 'server_balance': serverBalance,
      if (serverBalanceDate != null) 'server_balance_date': serverBalanceDate,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountDetailsCompanion copyWith(
      {Value<String>? walletFk,
      Value<String?>? accountRole,
      Value<String?>? liabilityType,
      Value<String?>? liabilityDirection,
      Value<double?>? interest,
      Value<String?>? interestPeriod,
      Value<String?>? iban,
      Value<String?>? bic,
      Value<String?>? accountNumber,
      Value<String?>? notes,
      Value<bool?>? includeNetWorth,
      Value<double?>? virtualBalance,
      Value<double?>? serverBalance,
      Value<DateTime?>? serverBalanceDate,
      Value<DateTime?>? dateTimeModified,
      Value<int>? rowid}) {
    return AccountDetailsCompanion(
      walletFk: walletFk ?? this.walletFk,
      accountRole: accountRole ?? this.accountRole,
      liabilityType: liabilityType ?? this.liabilityType,
      liabilityDirection: liabilityDirection ?? this.liabilityDirection,
      interest: interest ?? this.interest,
      interestPeriod: interestPeriod ?? this.interestPeriod,
      iban: iban ?? this.iban,
      bic: bic ?? this.bic,
      accountNumber: accountNumber ?? this.accountNumber,
      notes: notes ?? this.notes,
      includeNetWorth: includeNetWorth ?? this.includeNetWorth,
      virtualBalance: virtualBalance ?? this.virtualBalance,
      serverBalance: serverBalance ?? this.serverBalance,
      serverBalanceDate: serverBalanceDate ?? this.serverBalanceDate,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (walletFk.present) {
      map['wallet_fk'] = Variable<String>(walletFk.value);
    }
    if (accountRole.present) {
      map['account_role'] = Variable<String>(accountRole.value);
    }
    if (liabilityType.present) {
      map['liability_type'] = Variable<String>(liabilityType.value);
    }
    if (liabilityDirection.present) {
      map['liability_direction'] = Variable<String>(liabilityDirection.value);
    }
    if (interest.present) {
      map['interest'] = Variable<double>(interest.value);
    }
    if (interestPeriod.present) {
      map['interest_period'] = Variable<String>(interestPeriod.value);
    }
    if (iban.present) {
      map['iban'] = Variable<String>(iban.value);
    }
    if (bic.present) {
      map['bic'] = Variable<String>(bic.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (includeNetWorth.present) {
      map['include_net_worth'] = Variable<bool>(includeNetWorth.value);
    }
    if (virtualBalance.present) {
      map['virtual_balance'] = Variable<double>(virtualBalance.value);
    }
    if (serverBalance.present) {
      map['server_balance'] = Variable<double>(serverBalance.value);
    }
    if (serverBalanceDate.present) {
      map['server_balance_date'] = Variable<DateTime>(serverBalanceDate.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountDetailsCompanion(')
          ..write('walletFk: $walletFk, ')
          ..write('accountRole: $accountRole, ')
          ..write('liabilityType: $liabilityType, ')
          ..write('liabilityDirection: $liabilityDirection, ')
          ..write('interest: $interest, ')
          ..write('interestPeriod: $interestPeriod, ')
          ..write('iban: $iban, ')
          ..write('bic: $bic, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('notes: $notes, ')
          ..write('includeNetWorth: $includeNetWorth, ')
          ..write('virtualBalance: $virtualBalance, ')
          ..write('serverBalance: $serverBalance, ')
          ..write('serverBalanceDate: $serverBalanceDate, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetLimitsTable extends BudgetLimits
    with TableInfo<$BudgetLimitsTable, BudgetLimit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetLimitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _budgetLimitPkMeta =
      const VerificationMeta('budgetLimitPk');
  @override
  late final GeneratedColumn<String> budgetLimitPk = GeneratedColumn<String>(
      'budget_limit_pk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => uuid.v4());
  static const VerificationMeta _budgetFkMeta =
      const VerificationMeta('budgetFk');
  @override
  late final GeneratedColumn<String> budgetFk = GeneratedColumn<String>(
      'budget_fk', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES budgets (budget_pk)'));
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
      'start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
      'end', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        budgetLimitPk,
        budgetFk,
        start,
        end,
        amount,
        currency,
        notes,
        dateTimeModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_limits';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetLimit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('budget_limit_pk')) {
      context.handle(
          _budgetLimitPkMeta,
          budgetLimitPk.isAcceptableOrUnknown(
              data['budget_limit_pk']!, _budgetLimitPkMeta));
    }
    if (data.containsKey('budget_fk')) {
      context.handle(_budgetFkMeta,
          budgetFk.isAcceptableOrUnknown(data['budget_fk']!, _budgetFkMeta));
    } else if (isInserting) {
      context.missing(_budgetFkMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
          _startMeta, start.isAcceptableOrUnknown(data['start']!, _startMeta));
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
          _endMeta, end.isAcceptableOrUnknown(data['end']!, _endMeta));
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {budgetLimitPk};
  @override
  BudgetLimit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetLimit(
      budgetLimitPk: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}budget_limit_pk'])!,
      budgetFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}budget_fk'])!,
      start: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start'])!,
      end: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified']),
    );
  }

  @override
  $BudgetLimitsTable createAlias(String alias) {
    return $BudgetLimitsTable(attachedDatabase, alias);
  }
}

class BudgetLimit extends DataClass implements Insertable<BudgetLimit> {
  final String budgetLimitPk;
  final String budgetFk;
  final DateTime start;
  final DateTime end;
  final double amount;
  final String currency;
  final String? notes;
  final DateTime? dateTimeModified;
  const BudgetLimit(
      {required this.budgetLimitPk,
      required this.budgetFk,
      required this.start,
      required this.end,
      required this.amount,
      required this.currency,
      this.notes,
      this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['budget_limit_pk'] = Variable<String>(budgetLimitPk);
    map['budget_fk'] = Variable<String>(budgetFk);
    map['start'] = Variable<DateTime>(start);
    map['end'] = Variable<DateTime>(end);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || dateTimeModified != null) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    }
    return map;
  }

  BudgetLimitsCompanion toCompanion(bool nullToAbsent) {
    return BudgetLimitsCompanion(
      budgetLimitPk: Value(budgetLimitPk),
      budgetFk: Value(budgetFk),
      start: Value(start),
      end: Value(end),
      amount: Value(amount),
      currency: Value(currency),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      dateTimeModified: dateTimeModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeModified),
    );
  }

  factory BudgetLimit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetLimit(
      budgetLimitPk: serializer.fromJson<String>(json['budgetLimitPk']),
      budgetFk: serializer.fromJson<String>(json['budgetFk']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime>(json['end']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      notes: serializer.fromJson<String?>(json['notes']),
      dateTimeModified:
          serializer.fromJson<DateTime?>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'budgetLimitPk': serializer.toJson<String>(budgetLimitPk),
      'budgetFk': serializer.toJson<String>(budgetFk),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime>(end),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'notes': serializer.toJson<String?>(notes),
      'dateTimeModified': serializer.toJson<DateTime?>(dateTimeModified),
    };
  }

  BudgetLimit copyWith(
          {String? budgetLimitPk,
          String? budgetFk,
          DateTime? start,
          DateTime? end,
          double? amount,
          String? currency,
          Value<String?> notes = const Value.absent(),
          Value<DateTime?> dateTimeModified = const Value.absent()}) =>
      BudgetLimit(
        budgetLimitPk: budgetLimitPk ?? this.budgetLimitPk,
        budgetFk: budgetFk ?? this.budgetFk,
        start: start ?? this.start,
        end: end ?? this.end,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        notes: notes.present ? notes.value : this.notes,
        dateTimeModified: dateTimeModified.present
            ? dateTimeModified.value
            : this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('BudgetLimit(')
          ..write('budgetLimitPk: $budgetLimitPk, ')
          ..write('budgetFk: $budgetFk, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('notes: $notes, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(budgetLimitPk, budgetFk, start, end, amount,
      currency, notes, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetLimit &&
          other.budgetLimitPk == this.budgetLimitPk &&
          other.budgetFk == this.budgetFk &&
          other.start == this.start &&
          other.end == this.end &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.notes == this.notes &&
          other.dateTimeModified == this.dateTimeModified);
}

class BudgetLimitsCompanion extends UpdateCompanion<BudgetLimit> {
  final Value<String> budgetLimitPk;
  final Value<String> budgetFk;
  final Value<DateTime> start;
  final Value<DateTime> end;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String?> notes;
  final Value<DateTime?> dateTimeModified;
  final Value<int> rowid;
  const BudgetLimitsCompanion({
    this.budgetLimitPk = const Value.absent(),
    this.budgetFk = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.notes = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetLimitsCompanion.insert({
    this.budgetLimitPk = const Value.absent(),
    required String budgetFk,
    required DateTime start,
    required DateTime end,
    required double amount,
    required String currency,
    this.notes = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : budgetFk = Value(budgetFk),
        start = Value(start),
        end = Value(end),
        amount = Value(amount),
        currency = Value(currency);
  static Insertable<BudgetLimit> custom({
    Expression<String>? budgetLimitPk,
    Expression<String>? budgetFk,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? notes,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (budgetLimitPk != null) 'budget_limit_pk': budgetLimitPk,
      if (budgetFk != null) 'budget_fk': budgetFk,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (notes != null) 'notes': notes,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetLimitsCompanion copyWith(
      {Value<String>? budgetLimitPk,
      Value<String>? budgetFk,
      Value<DateTime>? start,
      Value<DateTime>? end,
      Value<double>? amount,
      Value<String>? currency,
      Value<String?>? notes,
      Value<DateTime?>? dateTimeModified,
      Value<int>? rowid}) {
    return BudgetLimitsCompanion(
      budgetLimitPk: budgetLimitPk ?? this.budgetLimitPk,
      budgetFk: budgetFk ?? this.budgetFk,
      start: start ?? this.start,
      end: end ?? this.end,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (budgetLimitPk.present) {
      map['budget_limit_pk'] = Variable<String>(budgetLimitPk.value);
    }
    if (budgetFk.present) {
      map['budget_fk'] = Variable<String>(budgetFk.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetLimitsCompanion(')
          ..write('budgetLimitPk: $budgetLimitPk, ')
          ..write('budgetFk: $budgetFk, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('notes: $notes, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FinanceDatabase extends GeneratedDatabase {
  _$FinanceDatabase(QueryExecutor e) : super(e);
  _$FinanceDatabaseManager get managers => _$FinanceDatabaseManager(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ObjectivesTable objectives = $ObjectivesTable(this);
  late final $PayeesTable payees = $PayeesTable(this);
  late final $TransactionGroupsTable transactionGroups =
      $TransactionGroupsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $CategoryBudgetLimitsTable categoryBudgetLimits =
      $CategoryBudgetLimitsTable(this);
  late final $AssociatedTitlesTable associatedTitles =
      $AssociatedTitlesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ScannerTemplatesTable scannerTemplates =
      $ScannerTemplatesTable(this);
  late final $DeleteLogsTable deleteLogs = $DeleteLogsTable(this);
  late final $FireflyIdMapTable fireflyIdMap = $FireflyIdMapTable(this);
  late final $FireflySyncMetaTable fireflySyncMeta =
      $FireflySyncMetaTable(this);
  late final $FireflyConflictsTable fireflyConflicts =
      $FireflyConflictsTable(this);
  late final $FireflyResourceCacheTable fireflyResourceCache =
      $FireflyResourceCacheTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TransactionTagsTable transactionTags =
      $TransactionTagsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $AccountDetailsTable accountDetails = $AccountDetailsTable(this);
  late final $BudgetLimitsTable budgetLimits = $BudgetLimitsTable(this);
  late final Index fireflyIdMapRemote = Index('firefly_id_map_remote',
      'CREATE UNIQUE INDEX firefly_id_map_remote ON firefly_id_map (entity_type, remote_id, remote_sub_id, remote_role)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        wallets,
        categories,
        objectives,
        payees,
        transactionGroups,
        transactions,
        budgets,
        categoryBudgetLimits,
        associatedTitles,
        appSettings,
        scannerTemplates,
        deleteLogs,
        fireflyIdMap,
        fireflySyncMeta,
        fireflyConflicts,
        fireflyResourceCache,
        tags,
        transactionTags,
        attachments,
        accountDetails,
        budgetLimits,
        fireflyIdMapRemote
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('transactions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transaction_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('tags',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transaction_tags', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$WalletsTableInsertCompanionBuilder = WalletsCompanion Function({
  Value<String> walletPk,
  required String name,
  Value<String?> colour,
  Value<String?> iconName,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  required int order,
  Value<String?> currency,
  Value<String?> currencyFormat,
  Value<int> decimals,
  Value<List<HomePageWidgetDisplay>?> homePageWidgetDisplay,
  Value<AccountKind> accountKind,
  Value<bool> archived,
  Value<int> rowid,
});
typedef $$WalletsTableUpdateCompanionBuilder = WalletsCompanion Function({
  Value<String> walletPk,
  Value<String> name,
  Value<String?> colour,
  Value<String?> iconName,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> order,
  Value<String?> currency,
  Value<String?> currencyFormat,
  Value<int> decimals,
  Value<List<HomePageWidgetDisplay>?> homePageWidgetDisplay,
  Value<AccountKind> accountKind,
  Value<bool> archived,
  Value<int> rowid,
});

class $$WalletsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $WalletsTable,
    TransactionWallet,
    $$WalletsTableFilterComposer,
    $$WalletsTableOrderingComposer,
    $$WalletsTableProcessedTableManager,
    $$WalletsTableInsertCompanionBuilder,
    $$WalletsTableUpdateCompanionBuilder> {
  $$WalletsTableTableManager(_$FinanceDatabase db, $WalletsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$WalletsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$WalletsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $$WalletsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> walletPk = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> colour = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<String?> currencyFormat = const Value.absent(),
            Value<int> decimals = const Value.absent(),
            Value<List<HomePageWidgetDisplay>?> homePageWidgetDisplay =
                const Value.absent(),
            Value<AccountKind> accountKind = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WalletsCompanion(
            walletPk: walletPk,
            name: name,
            colour: colour,
            iconName: iconName,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            order: order,
            currency: currency,
            currencyFormat: currencyFormat,
            decimals: decimals,
            homePageWidgetDisplay: homePageWidgetDisplay,
            accountKind: accountKind,
            archived: archived,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> walletPk = const Value.absent(),
            required String name,
            Value<String?> colour = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            required int order,
            Value<String?> currency = const Value.absent(),
            Value<String?> currencyFormat = const Value.absent(),
            Value<int> decimals = const Value.absent(),
            Value<List<HomePageWidgetDisplay>?> homePageWidgetDisplay =
                const Value.absent(),
            Value<AccountKind> accountKind = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WalletsCompanion.insert(
            walletPk: walletPk,
            name: name,
            colour: colour,
            iconName: iconName,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            order: order,
            currency: currency,
            currencyFormat: currencyFormat,
            decimals: decimals,
            homePageWidgetDisplay: homePageWidgetDisplay,
            accountKind: accountKind,
            archived: archived,
            rowid: rowid,
          ),
        ));
}

class $$WalletsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $WalletsTable,
    TransactionWallet,
    $$WalletsTableFilterComposer,
    $$WalletsTableOrderingComposer,
    $$WalletsTableProcessedTableManager,
    $$WalletsTableInsertCompanionBuilder,
    $$WalletsTableUpdateCompanionBuilder> {
  $$WalletsTableProcessedTableManager(super.$state);
}

class $$WalletsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer(super.$state);
  ColumnFilters<String> get walletPk => $state.composableBuilder(
      column: $state.table.walletPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colour => $state.composableBuilder(
      column: $state.table.colour,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get currencyFormat => $state.composableBuilder(
      column: $state.table.currencyFormat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get decimals => $state.composableBuilder(
      column: $state.table.decimals,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<HomePageWidgetDisplay>?,
          List<HomePageWidgetDisplay>, String>
      get homePageWidgetDisplay => $state.composableBuilder(
          column: $state.table.homePageWidgetDisplay,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<AccountKind, AccountKind, int>
      get accountKind => $state.composableBuilder(
          column: $state.table.accountKind,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get archived => $state.composableBuilder(
      column: $state.table.archived,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter objectivesRefs(
      ComposableFilter Function($$ObjectivesTableFilterComposer f) f) {
    final $$ObjectivesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletPk,
        referencedTable: $state.db.objectives,
        getReferencedColumn: (t) => t.walletFk,
        builder: (joinBuilder, parentComposers) =>
            $$ObjectivesTableFilterComposer(ComposerState($state.db,
                $state.db.objectives, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter transactionsRefs(
      ComposableFilter Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletPk,
        referencedTable: $state.db.transactions,
        getReferencedColumn: (t) => t.walletFk,
        builder: (joinBuilder, parentComposers) =>
            $$TransactionsTableFilterComposer(ComposerState($state.db,
                $state.db.transactions, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter budgetsRefs(
      ComposableFilter Function($$BudgetsTableFilterComposer f) f) {
    final $$BudgetsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletPk,
        referencedTable: $state.db.budgets,
        getReferencedColumn: (t) => t.walletFk,
        builder: (joinBuilder, parentComposers) => $$BudgetsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.budgets, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter categoryBudgetLimitsRefs(
      ComposableFilter Function($$CategoryBudgetLimitsTableFilterComposer f)
          f) {
    final $$CategoryBudgetLimitsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.walletPk,
            referencedTable: $state.db.categoryBudgetLimits,
            getReferencedColumn: (t) => t.walletFk,
            builder: (joinBuilder, parentComposers) =>
                $$CategoryBudgetLimitsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.categoryBudgetLimits,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter scannerTemplatesRefs(
      ComposableFilter Function($$ScannerTemplatesTableFilterComposer f) f) {
    final $$ScannerTemplatesTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.walletPk,
            referencedTable: $state.db.scannerTemplates,
            getReferencedColumn: (t) => t.walletFk,
            builder: (joinBuilder, parentComposers) =>
                $$ScannerTemplatesTableFilterComposer(ComposerState($state.db,
                    $state.db.scannerTemplates, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter accountDetailsRefs(
      ComposableFilter Function($$AccountDetailsTableFilterComposer f) f) {
    final $$AccountDetailsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletPk,
        referencedTable: $state.db.accountDetails,
        getReferencedColumn: (t) => t.walletFk,
        builder: (joinBuilder, parentComposers) =>
            $$AccountDetailsTableFilterComposer(ComposerState($state.db,
                $state.db.accountDetails, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$WalletsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get walletPk => $state.composableBuilder(
      column: $state.table.walletPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colour => $state.composableBuilder(
      column: $state.table.colour,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get currencyFormat => $state.composableBuilder(
      column: $state.table.currencyFormat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get decimals => $state.composableBuilder(
      column: $state.table.decimals,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get homePageWidgetDisplay => $state.composableBuilder(
      column: $state.table.homePageWidgetDisplay,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get accountKind => $state.composableBuilder(
      column: $state.table.accountKind,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get archived => $state.composableBuilder(
      column: $state.table.archived,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CategoriesTableInsertCompanionBuilder = CategoriesCompanion Function({
  Value<String> categoryPk,
  required String name,
  Value<String?> colour,
  Value<String?> iconName,
  Value<String?> emojiIconName,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  required int order,
  Value<bool> income,
  Value<MethodAdded?> methodAdded,
  Value<String?> mainCategoryPk,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> categoryPk,
  Value<String> name,
  Value<String?> colour,
  Value<String?> iconName,
  Value<String?> emojiIconName,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> order,
  Value<bool> income,
  Value<MethodAdded?> methodAdded,
  Value<String?> mainCategoryPk,
  Value<int> rowid,
});

class $$CategoriesTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $CategoriesTable,
    TransactionCategory,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableProcessedTableManager,
    $$CategoriesTableInsertCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder> {
  $$CategoriesTableTableManager(_$FinanceDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CategoriesTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$CategoriesTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> categoryPk = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> colour = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<String?> emojiIconName = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<bool> income = const Value.absent(),
            Value<MethodAdded?> methodAdded = const Value.absent(),
            Value<String?> mainCategoryPk = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            categoryPk: categoryPk,
            name: name,
            colour: colour,
            iconName: iconName,
            emojiIconName: emojiIconName,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            order: order,
            income: income,
            methodAdded: methodAdded,
            mainCategoryPk: mainCategoryPk,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> categoryPk = const Value.absent(),
            required String name,
            Value<String?> colour = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<String?> emojiIconName = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            required int order,
            Value<bool> income = const Value.absent(),
            Value<MethodAdded?> methodAdded = const Value.absent(),
            Value<String?> mainCategoryPk = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            categoryPk: categoryPk,
            name: name,
            colour: colour,
            iconName: iconName,
            emojiIconName: emojiIconName,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            order: order,
            income: income,
            methodAdded: methodAdded,
            mainCategoryPk: mainCategoryPk,
            rowid: rowid,
          ),
        ));
}

class $$CategoriesTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $CategoriesTable,
    TransactionCategory,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableProcessedTableManager,
    $$CategoriesTableInsertCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder> {
  $$CategoriesTableProcessedTableManager(super.$state);
}

class $$CategoriesTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer(super.$state);
  ColumnFilters<String> get categoryPk => $state.composableBuilder(
      column: $state.table.categoryPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colour => $state.composableBuilder(
      column: $state.table.colour,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get emojiIconName => $state.composableBuilder(
      column: $state.table.emojiIconName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get income => $state.composableBuilder(
      column: $state.table.income,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<MethodAdded?, MethodAdded, int>
      get methodAdded => $state.composableBuilder(
          column: $state.table.methodAdded,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  $$CategoriesTableFilterComposer get mainCategoryPk {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mainCategoryPk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter categoryBudgetLimitsRefs(
      ComposableFilter Function($$CategoryBudgetLimitsTableFilterComposer f)
          f) {
    final $$CategoryBudgetLimitsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryPk,
            referencedTable: $state.db.categoryBudgetLimits,
            getReferencedColumn: (t) => t.categoryFk,
            builder: (joinBuilder, parentComposers) =>
                $$CategoryBudgetLimitsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.categoryBudgetLimits,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter associatedTitlesRefs(
      ComposableFilter Function($$AssociatedTitlesTableFilterComposer f) f) {
    final $$AssociatedTitlesTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryPk,
            referencedTable: $state.db.associatedTitles,
            getReferencedColumn: (t) => t.categoryFk,
            builder: (joinBuilder, parentComposers) =>
                $$AssociatedTitlesTableFilterComposer(ComposerState($state.db,
                    $state.db.associatedTitles, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter scannerTemplatesRefs(
      ComposableFilter Function($$ScannerTemplatesTableFilterComposer f) f) {
    final $$ScannerTemplatesTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryPk,
            referencedTable: $state.db.scannerTemplates,
            getReferencedColumn: (t) => t.defaultCategoryFk,
            builder: (joinBuilder, parentComposers) =>
                $$ScannerTemplatesTableFilterComposer(ComposerState($state.db,
                    $state.db.scannerTemplates, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get categoryPk => $state.composableBuilder(
      column: $state.table.categoryPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colour => $state.composableBuilder(
      column: $state.table.colour,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get emojiIconName => $state.composableBuilder(
      column: $state.table.emojiIconName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get income => $state.composableBuilder(
      column: $state.table.income,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get methodAdded => $state.composableBuilder(
      column: $state.table.methodAdded,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CategoriesTableOrderingComposer get mainCategoryPk {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mainCategoryPk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$ObjectivesTableInsertCompanionBuilder = ObjectivesCompanion Function({
  Value<String> objectivePk,
  Value<ObjectiveType> type,
  required String name,
  required double amount,
  required int order,
  Value<String?> colour,
  Value<DateTime> dateCreated,
  Value<DateTime?> endDate,
  Value<DateTime?> dateTimeModified,
  Value<String?> iconName,
  Value<String?> emojiIconName,
  Value<bool> income,
  Value<bool> pinned,
  Value<bool> archived,
  Value<String> walletFk,
  Value<int> rowid,
});
typedef $$ObjectivesTableUpdateCompanionBuilder = ObjectivesCompanion Function({
  Value<String> objectivePk,
  Value<ObjectiveType> type,
  Value<String> name,
  Value<double> amount,
  Value<int> order,
  Value<String?> colour,
  Value<DateTime> dateCreated,
  Value<DateTime?> endDate,
  Value<DateTime?> dateTimeModified,
  Value<String?> iconName,
  Value<String?> emojiIconName,
  Value<bool> income,
  Value<bool> pinned,
  Value<bool> archived,
  Value<String> walletFk,
  Value<int> rowid,
});

class $$ObjectivesTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $ObjectivesTable,
    Objective,
    $$ObjectivesTableFilterComposer,
    $$ObjectivesTableOrderingComposer,
    $$ObjectivesTableProcessedTableManager,
    $$ObjectivesTableInsertCompanionBuilder,
    $$ObjectivesTableUpdateCompanionBuilder> {
  $$ObjectivesTableTableManager(_$FinanceDatabase db, $ObjectivesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ObjectivesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ObjectivesTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$ObjectivesTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> objectivePk = const Value.absent(),
            Value<ObjectiveType> type = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<String?> colour = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<String?> emojiIconName = const Value.absent(),
            Value<bool> income = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<String> walletFk = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ObjectivesCompanion(
            objectivePk: objectivePk,
            type: type,
            name: name,
            amount: amount,
            order: order,
            colour: colour,
            dateCreated: dateCreated,
            endDate: endDate,
            dateTimeModified: dateTimeModified,
            iconName: iconName,
            emojiIconName: emojiIconName,
            income: income,
            pinned: pinned,
            archived: archived,
            walletFk: walletFk,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> objectivePk = const Value.absent(),
            Value<ObjectiveType> type = const Value.absent(),
            required String name,
            required double amount,
            required int order,
            Value<String?> colour = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<String?> emojiIconName = const Value.absent(),
            Value<bool> income = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<String> walletFk = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ObjectivesCompanion.insert(
            objectivePk: objectivePk,
            type: type,
            name: name,
            amount: amount,
            order: order,
            colour: colour,
            dateCreated: dateCreated,
            endDate: endDate,
            dateTimeModified: dateTimeModified,
            iconName: iconName,
            emojiIconName: emojiIconName,
            income: income,
            pinned: pinned,
            archived: archived,
            walletFk: walletFk,
            rowid: rowid,
          ),
        ));
}

class $$ObjectivesTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $ObjectivesTable,
    Objective,
    $$ObjectivesTableFilterComposer,
    $$ObjectivesTableOrderingComposer,
    $$ObjectivesTableProcessedTableManager,
    $$ObjectivesTableInsertCompanionBuilder,
    $$ObjectivesTableUpdateCompanionBuilder> {
  $$ObjectivesTableProcessedTableManager(super.$state);
}

class $$ObjectivesTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $ObjectivesTable> {
  $$ObjectivesTableFilterComposer(super.$state);
  ColumnFilters<String> get objectivePk => $state.composableBuilder(
      column: $state.table.objectivePk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<ObjectiveType, ObjectiveType, int> get type =>
      $state.composableBuilder(
          column: $state.table.type,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colour => $state.composableBuilder(
      column: $state.table.colour,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get emojiIconName => $state.composableBuilder(
      column: $state.table.emojiIconName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get income => $state.composableBuilder(
      column: $state.table.income,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get pinned => $state.composableBuilder(
      column: $state.table.pinned,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get archived => $state.composableBuilder(
      column: $state.table.archived,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$WalletsTableFilterComposer get walletFk {
    final $$WalletsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) => $$WalletsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$ObjectivesTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $ObjectivesTable> {
  $$ObjectivesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get objectivePk => $state.composableBuilder(
      column: $state.table.objectivePk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colour => $state.composableBuilder(
      column: $state.table.colour,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get emojiIconName => $state.composableBuilder(
      column: $state.table.emojiIconName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get income => $state.composableBuilder(
      column: $state.table.income,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get pinned => $state.composableBuilder(
      column: $state.table.pinned,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get archived => $state.composableBuilder(
      column: $state.table.archived,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$WalletsTableOrderingComposer get walletFk {
    final $$WalletsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) =>
            $$WalletsTableOrderingComposer(ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$PayeesTableInsertCompanionBuilder = PayeesCompanion Function({
  Value<String> payeePk,
  required String name,
  required PayeeKind kind,
  Value<bool> active,
  Value<String?> notes,
  Value<String?> iban,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});
typedef $$PayeesTableUpdateCompanionBuilder = PayeesCompanion Function({
  Value<String> payeePk,
  Value<String> name,
  Value<PayeeKind> kind,
  Value<bool> active,
  Value<String?> notes,
  Value<String?> iban,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});

class $$PayeesTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $PayeesTable,
    Payee,
    $$PayeesTableFilterComposer,
    $$PayeesTableOrderingComposer,
    $$PayeesTableProcessedTableManager,
    $$PayeesTableInsertCompanionBuilder,
    $$PayeesTableUpdateCompanionBuilder> {
  $$PayeesTableTableManager(_$FinanceDatabase db, $PayeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PayeesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PayeesTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $$PayeesTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> payeePk = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<PayeeKind> kind = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> iban = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PayeesCompanion(
            payeePk: payeePk,
            name: name,
            kind: kind,
            active: active,
            notes: notes,
            iban: iban,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> payeePk = const Value.absent(),
            required String name,
            required PayeeKind kind,
            Value<bool> active = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> iban = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PayeesCompanion.insert(
            payeePk: payeePk,
            name: name,
            kind: kind,
            active: active,
            notes: notes,
            iban: iban,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$PayeesTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $PayeesTable,
    Payee,
    $$PayeesTableFilterComposer,
    $$PayeesTableOrderingComposer,
    $$PayeesTableProcessedTableManager,
    $$PayeesTableInsertCompanionBuilder,
    $$PayeesTableUpdateCompanionBuilder> {
  $$PayeesTableProcessedTableManager(super.$state);
}

class $$PayeesTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $PayeesTable> {
  $$PayeesTableFilterComposer(super.$state);
  ColumnFilters<String> get payeePk => $state.composableBuilder(
      column: $state.table.payeePk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<PayeeKind, PayeeKind, int> get kind =>
      $state.composableBuilder(
          column: $state.table.kind,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get active => $state.composableBuilder(
      column: $state.table.active,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iban => $state.composableBuilder(
      column: $state.table.iban,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter transactionsRefs(
      ComposableFilter Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payeePk,
        referencedTable: $state.db.transactions,
        getReferencedColumn: (t) => t.payeeFk,
        builder: (joinBuilder, parentComposers) =>
            $$TransactionsTableFilterComposer(ComposerState($state.db,
                $state.db.transactions, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$PayeesTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $PayeesTable> {
  $$PayeesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get payeePk => $state.composableBuilder(
      column: $state.table.payeePk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get kind => $state.composableBuilder(
      column: $state.table.kind,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get active => $state.composableBuilder(
      column: $state.table.active,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iban => $state.composableBuilder(
      column: $state.table.iban,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TransactionGroupsTableInsertCompanionBuilder
    = TransactionGroupsCompanion Function({
  Value<String> groupPk,
  Value<String?> title,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});
typedef $$TransactionGroupsTableUpdateCompanionBuilder
    = TransactionGroupsCompanion Function({
  Value<String> groupPk,
  Value<String?> title,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});

class $$TransactionGroupsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $TransactionGroupsTable,
    TransactionGroup,
    $$TransactionGroupsTableFilterComposer,
    $$TransactionGroupsTableOrderingComposer,
    $$TransactionGroupsTableProcessedTableManager,
    $$TransactionGroupsTableInsertCompanionBuilder,
    $$TransactionGroupsTableUpdateCompanionBuilder> {
  $$TransactionGroupsTableTableManager(
      _$FinanceDatabase db, $TransactionGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TransactionGroupsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$TransactionGroupsTableOrderingComposer(
              ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$TransactionGroupsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> groupPk = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionGroupsCompanion(
            groupPk: groupPk,
            title: title,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> groupPk = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionGroupsCompanion.insert(
            groupPk: groupPk,
            title: title,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$TransactionGroupsTableProcessedTableManager
    extends ProcessedTableManager<
        _$FinanceDatabase,
        $TransactionGroupsTable,
        TransactionGroup,
        $$TransactionGroupsTableFilterComposer,
        $$TransactionGroupsTableOrderingComposer,
        $$TransactionGroupsTableProcessedTableManager,
        $$TransactionGroupsTableInsertCompanionBuilder,
        $$TransactionGroupsTableUpdateCompanionBuilder> {
  $$TransactionGroupsTableProcessedTableManager(super.$state);
}

class $$TransactionGroupsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $TransactionGroupsTable> {
  $$TransactionGroupsTableFilterComposer(super.$state);
  ColumnFilters<String> get groupPk => $state.composableBuilder(
      column: $state.table.groupPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter transactionsRefs(
      ComposableFilter Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupPk,
        referencedTable: $state.db.transactions,
        getReferencedColumn: (t) => t.splitGroupFk,
        builder: (joinBuilder, parentComposers) =>
            $$TransactionsTableFilterComposer(ComposerState($state.db,
                $state.db.transactions, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$TransactionGroupsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $TransactionGroupsTable> {
  $$TransactionGroupsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get groupPk => $state.composableBuilder(
      column: $state.table.groupPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TransactionsTableInsertCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> transactionPk,
  Value<String?> pairedTransactionFk,
  required String name,
  required double amount,
  required String note,
  required String categoryFk,
  Value<String?> subCategoryFk,
  Value<String> walletFk,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<DateTime?> originalDateDue,
  Value<bool> income,
  Value<int?> periodLength,
  Value<BudgetReoccurence?> reoccurrence,
  Value<DateTime?> endDate,
  Value<bool?> upcomingTransactionNotification,
  Value<TransactionSpecialType?> type,
  Value<bool> paid,
  Value<bool?> createdAnotherFutureTransaction,
  Value<bool> skipPaid,
  Value<MethodAdded?> methodAdded,
  Value<String?> transactionOwnerEmail,
  Value<String?> transactionOriginalOwnerEmail,
  Value<String?> sharedKey,
  Value<String?> sharedOldKey,
  Value<SharedStatus?> sharedStatus,
  Value<DateTime?> sharedDateUpdated,
  Value<String?> sharedReferenceBudgetPk,
  Value<String?> objectiveFk,
  Value<String?> objectiveLoanFk,
  Value<List<String>?> budgetFksExclude,
  Value<String?> payeeFk,
  Value<double?> foreignAmount,
  Value<String?> foreignCurrency,
  Value<String?> splitGroupFk,
  Value<int?> splitOrder,
  Value<FireflyTransactionType?> fireflyType,
  Value<String?> billFk,
  Value<bool> reconciled,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> transactionPk,
  Value<String?> pairedTransactionFk,
  Value<String> name,
  Value<double> amount,
  Value<String> note,
  Value<String> categoryFk,
  Value<String?> subCategoryFk,
  Value<String> walletFk,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<DateTime?> originalDateDue,
  Value<bool> income,
  Value<int?> periodLength,
  Value<BudgetReoccurence?> reoccurrence,
  Value<DateTime?> endDate,
  Value<bool?> upcomingTransactionNotification,
  Value<TransactionSpecialType?> type,
  Value<bool> paid,
  Value<bool?> createdAnotherFutureTransaction,
  Value<bool> skipPaid,
  Value<MethodAdded?> methodAdded,
  Value<String?> transactionOwnerEmail,
  Value<String?> transactionOriginalOwnerEmail,
  Value<String?> sharedKey,
  Value<String?> sharedOldKey,
  Value<SharedStatus?> sharedStatus,
  Value<DateTime?> sharedDateUpdated,
  Value<String?> sharedReferenceBudgetPk,
  Value<String?> objectiveFk,
  Value<String?> objectiveLoanFk,
  Value<List<String>?> budgetFksExclude,
  Value<String?> payeeFk,
  Value<double?> foreignAmount,
  Value<String?> foreignCurrency,
  Value<String?> splitGroupFk,
  Value<int?> splitOrder,
  Value<FireflyTransactionType?> fireflyType,
  Value<String?> billFk,
  Value<bool> reconciled,
  Value<int> rowid,
});

class $$TransactionsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableProcessedTableManager,
    $$TransactionsTableInsertCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder> {
  $$TransactionsTableTableManager(
      _$FinanceDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TransactionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TransactionsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$TransactionsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> transactionPk = const Value.absent(),
            Value<String?> pairedTransactionFk = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String> categoryFk = const Value.absent(),
            Value<String?> subCategoryFk = const Value.absent(),
            Value<String> walletFk = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<DateTime?> originalDateDue = const Value.absent(),
            Value<bool> income = const Value.absent(),
            Value<int?> periodLength = const Value.absent(),
            Value<BudgetReoccurence?> reoccurrence = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<bool?> upcomingTransactionNotification = const Value.absent(),
            Value<TransactionSpecialType?> type = const Value.absent(),
            Value<bool> paid = const Value.absent(),
            Value<bool?> createdAnotherFutureTransaction = const Value.absent(),
            Value<bool> skipPaid = const Value.absent(),
            Value<MethodAdded?> methodAdded = const Value.absent(),
            Value<String?> transactionOwnerEmail = const Value.absent(),
            Value<String?> transactionOriginalOwnerEmail = const Value.absent(),
            Value<String?> sharedKey = const Value.absent(),
            Value<String?> sharedOldKey = const Value.absent(),
            Value<SharedStatus?> sharedStatus = const Value.absent(),
            Value<DateTime?> sharedDateUpdated = const Value.absent(),
            Value<String?> sharedReferenceBudgetPk = const Value.absent(),
            Value<String?> objectiveFk = const Value.absent(),
            Value<String?> objectiveLoanFk = const Value.absent(),
            Value<List<String>?> budgetFksExclude = const Value.absent(),
            Value<String?> payeeFk = const Value.absent(),
            Value<double?> foreignAmount = const Value.absent(),
            Value<String?> foreignCurrency = const Value.absent(),
            Value<String?> splitGroupFk = const Value.absent(),
            Value<int?> splitOrder = const Value.absent(),
            Value<FireflyTransactionType?> fireflyType = const Value.absent(),
            Value<String?> billFk = const Value.absent(),
            Value<bool> reconciled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            transactionPk: transactionPk,
            pairedTransactionFk: pairedTransactionFk,
            name: name,
            amount: amount,
            note: note,
            categoryFk: categoryFk,
            subCategoryFk: subCategoryFk,
            walletFk: walletFk,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            originalDateDue: originalDateDue,
            income: income,
            periodLength: periodLength,
            reoccurrence: reoccurrence,
            endDate: endDate,
            upcomingTransactionNotification: upcomingTransactionNotification,
            type: type,
            paid: paid,
            createdAnotherFutureTransaction: createdAnotherFutureTransaction,
            skipPaid: skipPaid,
            methodAdded: methodAdded,
            transactionOwnerEmail: transactionOwnerEmail,
            transactionOriginalOwnerEmail: transactionOriginalOwnerEmail,
            sharedKey: sharedKey,
            sharedOldKey: sharedOldKey,
            sharedStatus: sharedStatus,
            sharedDateUpdated: sharedDateUpdated,
            sharedReferenceBudgetPk: sharedReferenceBudgetPk,
            objectiveFk: objectiveFk,
            objectiveLoanFk: objectiveLoanFk,
            budgetFksExclude: budgetFksExclude,
            payeeFk: payeeFk,
            foreignAmount: foreignAmount,
            foreignCurrency: foreignCurrency,
            splitGroupFk: splitGroupFk,
            splitOrder: splitOrder,
            fireflyType: fireflyType,
            billFk: billFk,
            reconciled: reconciled,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> transactionPk = const Value.absent(),
            Value<String?> pairedTransactionFk = const Value.absent(),
            required String name,
            required double amount,
            required String note,
            required String categoryFk,
            Value<String?> subCategoryFk = const Value.absent(),
            Value<String> walletFk = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<DateTime?> originalDateDue = const Value.absent(),
            Value<bool> income = const Value.absent(),
            Value<int?> periodLength = const Value.absent(),
            Value<BudgetReoccurence?> reoccurrence = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<bool?> upcomingTransactionNotification = const Value.absent(),
            Value<TransactionSpecialType?> type = const Value.absent(),
            Value<bool> paid = const Value.absent(),
            Value<bool?> createdAnotherFutureTransaction = const Value.absent(),
            Value<bool> skipPaid = const Value.absent(),
            Value<MethodAdded?> methodAdded = const Value.absent(),
            Value<String?> transactionOwnerEmail = const Value.absent(),
            Value<String?> transactionOriginalOwnerEmail = const Value.absent(),
            Value<String?> sharedKey = const Value.absent(),
            Value<String?> sharedOldKey = const Value.absent(),
            Value<SharedStatus?> sharedStatus = const Value.absent(),
            Value<DateTime?> sharedDateUpdated = const Value.absent(),
            Value<String?> sharedReferenceBudgetPk = const Value.absent(),
            Value<String?> objectiveFk = const Value.absent(),
            Value<String?> objectiveLoanFk = const Value.absent(),
            Value<List<String>?> budgetFksExclude = const Value.absent(),
            Value<String?> payeeFk = const Value.absent(),
            Value<double?> foreignAmount = const Value.absent(),
            Value<String?> foreignCurrency = const Value.absent(),
            Value<String?> splitGroupFk = const Value.absent(),
            Value<int?> splitOrder = const Value.absent(),
            Value<FireflyTransactionType?> fireflyType = const Value.absent(),
            Value<String?> billFk = const Value.absent(),
            Value<bool> reconciled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            transactionPk: transactionPk,
            pairedTransactionFk: pairedTransactionFk,
            name: name,
            amount: amount,
            note: note,
            categoryFk: categoryFk,
            subCategoryFk: subCategoryFk,
            walletFk: walletFk,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            originalDateDue: originalDateDue,
            income: income,
            periodLength: periodLength,
            reoccurrence: reoccurrence,
            endDate: endDate,
            upcomingTransactionNotification: upcomingTransactionNotification,
            type: type,
            paid: paid,
            createdAnotherFutureTransaction: createdAnotherFutureTransaction,
            skipPaid: skipPaid,
            methodAdded: methodAdded,
            transactionOwnerEmail: transactionOwnerEmail,
            transactionOriginalOwnerEmail: transactionOriginalOwnerEmail,
            sharedKey: sharedKey,
            sharedOldKey: sharedOldKey,
            sharedStatus: sharedStatus,
            sharedDateUpdated: sharedDateUpdated,
            sharedReferenceBudgetPk: sharedReferenceBudgetPk,
            objectiveFk: objectiveFk,
            objectiveLoanFk: objectiveLoanFk,
            budgetFksExclude: budgetFksExclude,
            payeeFk: payeeFk,
            foreignAmount: foreignAmount,
            foreignCurrency: foreignCurrency,
            splitGroupFk: splitGroupFk,
            splitOrder: splitOrder,
            fireflyType: fireflyType,
            billFk: billFk,
            reconciled: reconciled,
            rowid: rowid,
          ),
        ));
}

class $$TransactionsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableProcessedTableManager,
    $$TransactionsTableInsertCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder> {
  $$TransactionsTableProcessedTableManager(super.$state);
}

class $$TransactionsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer(super.$state);
  ColumnFilters<String> get transactionPk => $state.composableBuilder(
      column: $state.table.transactionPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get originalDateDue => $state.composableBuilder(
      column: $state.table.originalDateDue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get income => $state.composableBuilder(
      column: $state.table.income,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get periodLength => $state.composableBuilder(
      column: $state.table.periodLength,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<BudgetReoccurence?, BudgetReoccurence, int>
      get reoccurrence => $state.composableBuilder(
          column: $state.table.reoccurrence,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get upcomingTransactionNotification =>
      $state.composableBuilder(
          column: $state.table.upcomingTransactionNotification,
          builder: (column, joinBuilders) =>
              ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<TransactionSpecialType?,
          TransactionSpecialType, int>
      get type => $state.composableBuilder(
          column: $state.table.type,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get paid => $state.composableBuilder(
      column: $state.table.paid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get createdAnotherFutureTransaction =>
      $state.composableBuilder(
          column: $state.table.createdAnotherFutureTransaction,
          builder: (column, joinBuilders) =>
              ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get skipPaid => $state.composableBuilder(
      column: $state.table.skipPaid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<MethodAdded?, MethodAdded, int>
      get methodAdded => $state.composableBuilder(
          column: $state.table.methodAdded,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get transactionOwnerEmail => $state.composableBuilder(
      column: $state.table.transactionOwnerEmail,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get transactionOriginalOwnerEmail =>
      $state.composableBuilder(
          column: $state.table.transactionOriginalOwnerEmail,
          builder: (column, joinBuilders) =>
              ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sharedKey => $state.composableBuilder(
      column: $state.table.sharedKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sharedOldKey => $state.composableBuilder(
      column: $state.table.sharedOldKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<SharedStatus?, SharedStatus, int>
      get sharedStatus => $state.composableBuilder(
          column: $state.table.sharedStatus,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get sharedDateUpdated => $state.composableBuilder(
      column: $state.table.sharedDateUpdated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sharedReferenceBudgetPk => $state.composableBuilder(
      column: $state.table.sharedReferenceBudgetPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get budgetFksExclude => $state.composableBuilder(
          column: $state.table.budgetFksExclude,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<double> get foreignAmount => $state.composableBuilder(
      column: $state.table.foreignAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get foreignCurrency => $state.composableBuilder(
      column: $state.table.foreignCurrency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get splitOrder => $state.composableBuilder(
      column: $state.table.splitOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<FireflyTransactionType?,
          FireflyTransactionType, int>
      get fireflyType => $state.composableBuilder(
          column: $state.table.fireflyType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get billFk => $state.composableBuilder(
      column: $state.table.billFk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get reconciled => $state.composableBuilder(
      column: $state.table.reconciled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$TransactionsTableFilterComposer get pairedTransactionFk {
    final $$TransactionsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pairedTransactionFk,
        referencedTable: $state.db.transactions,
        getReferencedColumn: (t) => t.transactionPk,
        builder: (joinBuilder, parentComposers) =>
            $$TransactionsTableFilterComposer(ComposerState($state.db,
                $state.db.transactions, joinBuilder, parentComposers)));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryFk {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  $$CategoriesTableFilterComposer get subCategoryFk {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subCategoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  $$WalletsTableFilterComposer get walletFk {
    final $$WalletsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) => $$WalletsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }

  $$ObjectivesTableFilterComposer get objectiveFk {
    final $$ObjectivesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.objectiveFk,
        referencedTable: $state.db.objectives,
        getReferencedColumn: (t) => t.objectivePk,
        builder: (joinBuilder, parentComposers) =>
            $$ObjectivesTableFilterComposer(ComposerState($state.db,
                $state.db.objectives, joinBuilder, parentComposers)));
    return composer;
  }

  $$ObjectivesTableFilterComposer get objectiveLoanFk {
    final $$ObjectivesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.objectiveLoanFk,
        referencedTable: $state.db.objectives,
        getReferencedColumn: (t) => t.objectivePk,
        builder: (joinBuilder, parentComposers) =>
            $$ObjectivesTableFilterComposer(ComposerState($state.db,
                $state.db.objectives, joinBuilder, parentComposers)));
    return composer;
  }

  $$PayeesTableFilterComposer get payeeFk {
    final $$PayeesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payeeFk,
        referencedTable: $state.db.payees,
        getReferencedColumn: (t) => t.payeePk,
        builder: (joinBuilder, parentComposers) => $$PayeesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.payees, joinBuilder, parentComposers)));
    return composer;
  }

  $$TransactionGroupsTableFilterComposer get splitGroupFk {
    final $$TransactionGroupsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.splitGroupFk,
            referencedTable: $state.db.transactionGroups,
            getReferencedColumn: (t) => t.groupPk,
            builder: (joinBuilder, parentComposers) =>
                $$TransactionGroupsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.transactionGroups,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }

  ComposableFilter transactionTagsRefs(
      ComposableFilter Function($$TransactionTagsTableFilterComposer f) f) {
    final $$TransactionTagsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.transactionPk,
            referencedTable: $state.db.transactionTags,
            getReferencedColumn: (t) => t.transactionFk,
            builder: (joinBuilder, parentComposers) =>
                $$TransactionTagsTableFilterComposer(ComposerState($state.db,
                    $state.db.transactionTags, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get transactionPk => $state.composableBuilder(
      column: $state.table.transactionPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get originalDateDue => $state.composableBuilder(
      column: $state.table.originalDateDue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get income => $state.composableBuilder(
      column: $state.table.income,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get periodLength => $state.composableBuilder(
      column: $state.table.periodLength,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get reoccurrence => $state.composableBuilder(
      column: $state.table.reoccurrence,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get upcomingTransactionNotification =>
      $state.composableBuilder(
          column: $state.table.upcomingTransactionNotification,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get paid => $state.composableBuilder(
      column: $state.table.paid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get createdAnotherFutureTransaction =>
      $state.composableBuilder(
          column: $state.table.createdAnotherFutureTransaction,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get skipPaid => $state.composableBuilder(
      column: $state.table.skipPaid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get methodAdded => $state.composableBuilder(
      column: $state.table.methodAdded,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get transactionOwnerEmail => $state.composableBuilder(
      column: $state.table.transactionOwnerEmail,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get transactionOriginalOwnerEmail =>
      $state.composableBuilder(
          column: $state.table.transactionOriginalOwnerEmail,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sharedKey => $state.composableBuilder(
      column: $state.table.sharedKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sharedOldKey => $state.composableBuilder(
      column: $state.table.sharedOldKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sharedStatus => $state.composableBuilder(
      column: $state.table.sharedStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get sharedDateUpdated => $state.composableBuilder(
      column: $state.table.sharedDateUpdated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sharedReferenceBudgetPk =>
      $state.composableBuilder(
          column: $state.table.sharedReferenceBudgetPk,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get budgetFksExclude => $state.composableBuilder(
      column: $state.table.budgetFksExclude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get foreignAmount => $state.composableBuilder(
      column: $state.table.foreignAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get foreignCurrency => $state.composableBuilder(
      column: $state.table.foreignCurrency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get splitOrder => $state.composableBuilder(
      column: $state.table.splitOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get fireflyType => $state.composableBuilder(
      column: $state.table.fireflyType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get billFk => $state.composableBuilder(
      column: $state.table.billFk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get reconciled => $state.composableBuilder(
      column: $state.table.reconciled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$TransactionsTableOrderingComposer get pairedTransactionFk {
    final $$TransactionsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.pairedTransactionFk,
        referencedTable: $state.db.transactions,
        getReferencedColumn: (t) => t.transactionPk,
        builder: (joinBuilder, parentComposers) =>
            $$TransactionsTableOrderingComposer(ComposerState($state.db,
                $state.db.transactions, joinBuilder, parentComposers)));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryFk {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  $$CategoriesTableOrderingComposer get subCategoryFk {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subCategoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  $$WalletsTableOrderingComposer get walletFk {
    final $$WalletsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) =>
            $$WalletsTableOrderingComposer(ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }

  $$ObjectivesTableOrderingComposer get objectiveFk {
    final $$ObjectivesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.objectiveFk,
        referencedTable: $state.db.objectives,
        getReferencedColumn: (t) => t.objectivePk,
        builder: (joinBuilder, parentComposers) =>
            $$ObjectivesTableOrderingComposer(ComposerState($state.db,
                $state.db.objectives, joinBuilder, parentComposers)));
    return composer;
  }

  $$ObjectivesTableOrderingComposer get objectiveLoanFk {
    final $$ObjectivesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.objectiveLoanFk,
        referencedTable: $state.db.objectives,
        getReferencedColumn: (t) => t.objectivePk,
        builder: (joinBuilder, parentComposers) =>
            $$ObjectivesTableOrderingComposer(ComposerState($state.db,
                $state.db.objectives, joinBuilder, parentComposers)));
    return composer;
  }

  $$PayeesTableOrderingComposer get payeeFk {
    final $$PayeesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.payeeFk,
        referencedTable: $state.db.payees,
        getReferencedColumn: (t) => t.payeePk,
        builder: (joinBuilder, parentComposers) =>
            $$PayeesTableOrderingComposer(ComposerState(
                $state.db, $state.db.payees, joinBuilder, parentComposers)));
    return composer;
  }

  $$TransactionGroupsTableOrderingComposer get splitGroupFk {
    final $$TransactionGroupsTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.splitGroupFk,
            referencedTable: $state.db.transactionGroups,
            getReferencedColumn: (t) => t.groupPk,
            builder: (joinBuilder, parentComposers) =>
                $$TransactionGroupsTableOrderingComposer(ComposerState(
                    $state.db,
                    $state.db.transactionGroups,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

typedef $$BudgetsTableInsertCompanionBuilder = BudgetsCompanion Function({
  Value<String> budgetPk,
  required String name,
  required double amount,
  Value<String?> colour,
  required DateTime startDate,
  required DateTime endDate,
  Value<List<String>?> walletFks,
  Value<List<String>?> categoryFks,
  Value<List<String>?> categoryFksExclude,
  Value<bool> income,
  Value<bool> archived,
  Value<bool> addedTransactionsOnly,
  required int periodLength,
  Value<BudgetReoccurence?> reoccurrence,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<bool> pinned,
  required int order,
  Value<String> walletFk,
  Value<List<BudgetTransactionFilters>?> budgetTransactionFilters,
  Value<List<String>?> memberTransactionFilters,
  Value<String?> sharedKey,
  Value<SharedOwnerMember?> sharedOwnerMember,
  Value<DateTime?> sharedDateUpdated,
  Value<List<String>?> sharedMembers,
  Value<List<String>?> sharedAllMembersEver,
  Value<bool> isAbsoluteSpendingLimit,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> budgetPk,
  Value<String> name,
  Value<double> amount,
  Value<String?> colour,
  Value<DateTime> startDate,
  Value<DateTime> endDate,
  Value<List<String>?> walletFks,
  Value<List<String>?> categoryFks,
  Value<List<String>?> categoryFksExclude,
  Value<bool> income,
  Value<bool> archived,
  Value<bool> addedTransactionsOnly,
  Value<int> periodLength,
  Value<BudgetReoccurence?> reoccurrence,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<bool> pinned,
  Value<int> order,
  Value<String> walletFk,
  Value<List<BudgetTransactionFilters>?> budgetTransactionFilters,
  Value<List<String>?> memberTransactionFilters,
  Value<String?> sharedKey,
  Value<SharedOwnerMember?> sharedOwnerMember,
  Value<DateTime?> sharedDateUpdated,
  Value<List<String>?> sharedMembers,
  Value<List<String>?> sharedAllMembersEver,
  Value<bool> isAbsoluteSpendingLimit,
  Value<int> rowid,
});

class $$BudgetsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableProcessedTableManager,
    $$BudgetsTableInsertCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder> {
  $$BudgetsTableTableManager(_$FinanceDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BudgetsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BudgetsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $$BudgetsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> budgetPk = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> colour = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime> endDate = const Value.absent(),
            Value<List<String>?> walletFks = const Value.absent(),
            Value<List<String>?> categoryFks = const Value.absent(),
            Value<List<String>?> categoryFksExclude = const Value.absent(),
            Value<bool> income = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> addedTransactionsOnly = const Value.absent(),
            Value<int> periodLength = const Value.absent(),
            Value<BudgetReoccurence?> reoccurrence = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<String> walletFk = const Value.absent(),
            Value<List<BudgetTransactionFilters>?> budgetTransactionFilters =
                const Value.absent(),
            Value<List<String>?> memberTransactionFilters =
                const Value.absent(),
            Value<String?> sharedKey = const Value.absent(),
            Value<SharedOwnerMember?> sharedOwnerMember = const Value.absent(),
            Value<DateTime?> sharedDateUpdated = const Value.absent(),
            Value<List<String>?> sharedMembers = const Value.absent(),
            Value<List<String>?> sharedAllMembersEver = const Value.absent(),
            Value<bool> isAbsoluteSpendingLimit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            budgetPk: budgetPk,
            name: name,
            amount: amount,
            colour: colour,
            startDate: startDate,
            endDate: endDate,
            walletFks: walletFks,
            categoryFks: categoryFks,
            categoryFksExclude: categoryFksExclude,
            income: income,
            archived: archived,
            addedTransactionsOnly: addedTransactionsOnly,
            periodLength: periodLength,
            reoccurrence: reoccurrence,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            pinned: pinned,
            order: order,
            walletFk: walletFk,
            budgetTransactionFilters: budgetTransactionFilters,
            memberTransactionFilters: memberTransactionFilters,
            sharedKey: sharedKey,
            sharedOwnerMember: sharedOwnerMember,
            sharedDateUpdated: sharedDateUpdated,
            sharedMembers: sharedMembers,
            sharedAllMembersEver: sharedAllMembersEver,
            isAbsoluteSpendingLimit: isAbsoluteSpendingLimit,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> budgetPk = const Value.absent(),
            required String name,
            required double amount,
            Value<String?> colour = const Value.absent(),
            required DateTime startDate,
            required DateTime endDate,
            Value<List<String>?> walletFks = const Value.absent(),
            Value<List<String>?> categoryFks = const Value.absent(),
            Value<List<String>?> categoryFksExclude = const Value.absent(),
            Value<bool> income = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> addedTransactionsOnly = const Value.absent(),
            required int periodLength,
            Value<BudgetReoccurence?> reoccurrence = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            required int order,
            Value<String> walletFk = const Value.absent(),
            Value<List<BudgetTransactionFilters>?> budgetTransactionFilters =
                const Value.absent(),
            Value<List<String>?> memberTransactionFilters =
                const Value.absent(),
            Value<String?> sharedKey = const Value.absent(),
            Value<SharedOwnerMember?> sharedOwnerMember = const Value.absent(),
            Value<DateTime?> sharedDateUpdated = const Value.absent(),
            Value<List<String>?> sharedMembers = const Value.absent(),
            Value<List<String>?> sharedAllMembersEver = const Value.absent(),
            Value<bool> isAbsoluteSpendingLimit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            budgetPk: budgetPk,
            name: name,
            amount: amount,
            colour: colour,
            startDate: startDate,
            endDate: endDate,
            walletFks: walletFks,
            categoryFks: categoryFks,
            categoryFksExclude: categoryFksExclude,
            income: income,
            archived: archived,
            addedTransactionsOnly: addedTransactionsOnly,
            periodLength: periodLength,
            reoccurrence: reoccurrence,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            pinned: pinned,
            order: order,
            walletFk: walletFk,
            budgetTransactionFilters: budgetTransactionFilters,
            memberTransactionFilters: memberTransactionFilters,
            sharedKey: sharedKey,
            sharedOwnerMember: sharedOwnerMember,
            sharedDateUpdated: sharedDateUpdated,
            sharedMembers: sharedMembers,
            sharedAllMembersEver: sharedAllMembersEver,
            isAbsoluteSpendingLimit: isAbsoluteSpendingLimit,
            rowid: rowid,
          ),
        ));
}

class $$BudgetsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableProcessedTableManager,
    $$BudgetsTableInsertCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder> {
  $$BudgetsTableProcessedTableManager(super.$state);
}

class $$BudgetsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer(super.$state);
  ColumnFilters<String> get budgetPk => $state.composableBuilder(
      column: $state.table.budgetPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colour => $state.composableBuilder(
      column: $state.table.colour,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get walletFks => $state.composableBuilder(
          column: $state.table.walletFks,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get categoryFks => $state.composableBuilder(
          column: $state.table.categoryFks,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get categoryFksExclude => $state.composableBuilder(
          column: $state.table.categoryFksExclude,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get income => $state.composableBuilder(
      column: $state.table.income,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get archived => $state.composableBuilder(
      column: $state.table.archived,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get addedTransactionsOnly => $state.composableBuilder(
      column: $state.table.addedTransactionsOnly,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get periodLength => $state.composableBuilder(
      column: $state.table.periodLength,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<BudgetReoccurence?, BudgetReoccurence, int>
      get reoccurrence => $state.composableBuilder(
          column: $state.table.reoccurrence,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get pinned => $state.composableBuilder(
      column: $state.table.pinned,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<BudgetTransactionFilters>?,
          List<BudgetTransactionFilters>, String>
      get budgetTransactionFilters => $state.composableBuilder(
          column: $state.table.budgetTransactionFilters,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get memberTransactionFilters => $state.composableBuilder(
          column: $state.table.memberTransactionFilters,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get sharedKey => $state.composableBuilder(
      column: $state.table.sharedKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<SharedOwnerMember?, SharedOwnerMember, int>
      get sharedOwnerMember => $state.composableBuilder(
          column: $state.table.sharedOwnerMember,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get sharedDateUpdated => $state.composableBuilder(
      column: $state.table.sharedDateUpdated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get sharedMembers => $state.composableBuilder(
          column: $state.table.sharedMembers,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get sharedAllMembersEver => $state.composableBuilder(
          column: $state.table.sharedAllMembersEver,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get isAbsoluteSpendingLimit => $state.composableBuilder(
      column: $state.table.isAbsoluteSpendingLimit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$WalletsTableFilterComposer get walletFk {
    final $$WalletsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) => $$WalletsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter categoryBudgetLimitsRefs(
      ComposableFilter Function($$CategoryBudgetLimitsTableFilterComposer f)
          f) {
    final $$CategoryBudgetLimitsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.budgetPk,
            referencedTable: $state.db.categoryBudgetLimits,
            getReferencedColumn: (t) => t.budgetFk,
            builder: (joinBuilder, parentComposers) =>
                $$CategoryBudgetLimitsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.categoryBudgetLimits,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter budgetLimitsRefs(
      ComposableFilter Function($$BudgetLimitsTableFilterComposer f) f) {
    final $$BudgetLimitsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.budgetPk,
        referencedTable: $state.db.budgetLimits,
        getReferencedColumn: (t) => t.budgetFk,
        builder: (joinBuilder, parentComposers) =>
            $$BudgetLimitsTableFilterComposer(ComposerState($state.db,
                $state.db.budgetLimits, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$BudgetsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get budgetPk => $state.composableBuilder(
      column: $state.table.budgetPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colour => $state.composableBuilder(
      column: $state.table.colour,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get walletFks => $state.composableBuilder(
      column: $state.table.walletFks,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get categoryFks => $state.composableBuilder(
      column: $state.table.categoryFks,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get categoryFksExclude => $state.composableBuilder(
      column: $state.table.categoryFksExclude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get income => $state.composableBuilder(
      column: $state.table.income,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get archived => $state.composableBuilder(
      column: $state.table.archived,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get addedTransactionsOnly => $state.composableBuilder(
      column: $state.table.addedTransactionsOnly,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get periodLength => $state.composableBuilder(
      column: $state.table.periodLength,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get reoccurrence => $state.composableBuilder(
      column: $state.table.reoccurrence,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get pinned => $state.composableBuilder(
      column: $state.table.pinned,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get budgetTransactionFilters =>
      $state.composableBuilder(
          column: $state.table.budgetTransactionFilters,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get memberTransactionFilters =>
      $state.composableBuilder(
          column: $state.table.memberTransactionFilters,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sharedKey => $state.composableBuilder(
      column: $state.table.sharedKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sharedOwnerMember => $state.composableBuilder(
      column: $state.table.sharedOwnerMember,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get sharedDateUpdated => $state.composableBuilder(
      column: $state.table.sharedDateUpdated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sharedMembers => $state.composableBuilder(
      column: $state.table.sharedMembers,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sharedAllMembersEver => $state.composableBuilder(
      column: $state.table.sharedAllMembersEver,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isAbsoluteSpendingLimit => $state.composableBuilder(
      column: $state.table.isAbsoluteSpendingLimit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$WalletsTableOrderingComposer get walletFk {
    final $$WalletsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) =>
            $$WalletsTableOrderingComposer(ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$CategoryBudgetLimitsTableInsertCompanionBuilder
    = CategoryBudgetLimitsCompanion Function({
  Value<String> categoryLimitPk,
  required String categoryFk,
  required String budgetFk,
  required double amount,
  Value<DateTime?> dateTimeModified,
  Value<String> walletFk,
  Value<int> rowid,
});
typedef $$CategoryBudgetLimitsTableUpdateCompanionBuilder
    = CategoryBudgetLimitsCompanion Function({
  Value<String> categoryLimitPk,
  Value<String> categoryFk,
  Value<String> budgetFk,
  Value<double> amount,
  Value<DateTime?> dateTimeModified,
  Value<String> walletFk,
  Value<int> rowid,
});

class $$CategoryBudgetLimitsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $CategoryBudgetLimitsTable,
    CategoryBudgetLimit,
    $$CategoryBudgetLimitsTableFilterComposer,
    $$CategoryBudgetLimitsTableOrderingComposer,
    $$CategoryBudgetLimitsTableProcessedTableManager,
    $$CategoryBudgetLimitsTableInsertCompanionBuilder,
    $$CategoryBudgetLimitsTableUpdateCompanionBuilder> {
  $$CategoryBudgetLimitsTableTableManager(
      _$FinanceDatabase db, $CategoryBudgetLimitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$CategoryBudgetLimitsTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$CategoryBudgetLimitsTableOrderingComposer(
              ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$CategoryBudgetLimitsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> categoryLimitPk = const Value.absent(),
            Value<String> categoryFk = const Value.absent(),
            Value<String> budgetFk = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<String> walletFk = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryBudgetLimitsCompanion(
            categoryLimitPk: categoryLimitPk,
            categoryFk: categoryFk,
            budgetFk: budgetFk,
            amount: amount,
            dateTimeModified: dateTimeModified,
            walletFk: walletFk,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> categoryLimitPk = const Value.absent(),
            required String categoryFk,
            required String budgetFk,
            required double amount,
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<String> walletFk = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryBudgetLimitsCompanion.insert(
            categoryLimitPk: categoryLimitPk,
            categoryFk: categoryFk,
            budgetFk: budgetFk,
            amount: amount,
            dateTimeModified: dateTimeModified,
            walletFk: walletFk,
            rowid: rowid,
          ),
        ));
}

class $$CategoryBudgetLimitsTableProcessedTableManager
    extends ProcessedTableManager<
        _$FinanceDatabase,
        $CategoryBudgetLimitsTable,
        CategoryBudgetLimit,
        $$CategoryBudgetLimitsTableFilterComposer,
        $$CategoryBudgetLimitsTableOrderingComposer,
        $$CategoryBudgetLimitsTableProcessedTableManager,
        $$CategoryBudgetLimitsTableInsertCompanionBuilder,
        $$CategoryBudgetLimitsTableUpdateCompanionBuilder> {
  $$CategoryBudgetLimitsTableProcessedTableManager(super.$state);
}

class $$CategoryBudgetLimitsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $CategoryBudgetLimitsTable> {
  $$CategoryBudgetLimitsTableFilterComposer(super.$state);
  ColumnFilters<String> get categoryLimitPk => $state.composableBuilder(
      column: $state.table.categoryLimitPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CategoriesTableFilterComposer get categoryFk {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  $$BudgetsTableFilterComposer get budgetFk {
    final $$BudgetsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.budgetFk,
        referencedTable: $state.db.budgets,
        getReferencedColumn: (t) => t.budgetPk,
        builder: (joinBuilder, parentComposers) => $$BudgetsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.budgets, joinBuilder, parentComposers)));
    return composer;
  }

  $$WalletsTableFilterComposer get walletFk {
    final $$WalletsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) => $$WalletsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$CategoryBudgetLimitsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $CategoryBudgetLimitsTable> {
  $$CategoryBudgetLimitsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get categoryLimitPk => $state.composableBuilder(
      column: $state.table.categoryLimitPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CategoriesTableOrderingComposer get categoryFk {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  $$BudgetsTableOrderingComposer get budgetFk {
    final $$BudgetsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.budgetFk,
        referencedTable: $state.db.budgets,
        getReferencedColumn: (t) => t.budgetPk,
        builder: (joinBuilder, parentComposers) =>
            $$BudgetsTableOrderingComposer(ComposerState(
                $state.db, $state.db.budgets, joinBuilder, parentComposers)));
    return composer;
  }

  $$WalletsTableOrderingComposer get walletFk {
    final $$WalletsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) =>
            $$WalletsTableOrderingComposer(ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$AssociatedTitlesTableInsertCompanionBuilder
    = AssociatedTitlesCompanion Function({
  Value<String> associatedTitlePk,
  required String categoryFk,
  required String title,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  required int order,
  Value<bool> isExactMatch,
  Value<int> rowid,
});
typedef $$AssociatedTitlesTableUpdateCompanionBuilder
    = AssociatedTitlesCompanion Function({
  Value<String> associatedTitlePk,
  Value<String> categoryFk,
  Value<String> title,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> order,
  Value<bool> isExactMatch,
  Value<int> rowid,
});

class $$AssociatedTitlesTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $AssociatedTitlesTable,
    TransactionAssociatedTitle,
    $$AssociatedTitlesTableFilterComposer,
    $$AssociatedTitlesTableOrderingComposer,
    $$AssociatedTitlesTableProcessedTableManager,
    $$AssociatedTitlesTableInsertCompanionBuilder,
    $$AssociatedTitlesTableUpdateCompanionBuilder> {
  $$AssociatedTitlesTableTableManager(
      _$FinanceDatabase db, $AssociatedTitlesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AssociatedTitlesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AssociatedTitlesTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$AssociatedTitlesTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> associatedTitlePk = const Value.absent(),
            Value<String> categoryFk = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<bool> isExactMatch = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssociatedTitlesCompanion(
            associatedTitlePk: associatedTitlePk,
            categoryFk: categoryFk,
            title: title,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            order: order,
            isExactMatch: isExactMatch,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> associatedTitlePk = const Value.absent(),
            required String categoryFk,
            required String title,
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            required int order,
            Value<bool> isExactMatch = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssociatedTitlesCompanion.insert(
            associatedTitlePk: associatedTitlePk,
            categoryFk: categoryFk,
            title: title,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            order: order,
            isExactMatch: isExactMatch,
            rowid: rowid,
          ),
        ));
}

class $$AssociatedTitlesTableProcessedTableManager
    extends ProcessedTableManager<
        _$FinanceDatabase,
        $AssociatedTitlesTable,
        TransactionAssociatedTitle,
        $$AssociatedTitlesTableFilterComposer,
        $$AssociatedTitlesTableOrderingComposer,
        $$AssociatedTitlesTableProcessedTableManager,
        $$AssociatedTitlesTableInsertCompanionBuilder,
        $$AssociatedTitlesTableUpdateCompanionBuilder> {
  $$AssociatedTitlesTableProcessedTableManager(super.$state);
}

class $$AssociatedTitlesTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $AssociatedTitlesTable> {
  $$AssociatedTitlesTableFilterComposer(super.$state);
  ColumnFilters<String> get associatedTitlePk => $state.composableBuilder(
      column: $state.table.associatedTitlePk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isExactMatch => $state.composableBuilder(
      column: $state.table.isExactMatch,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CategoriesTableFilterComposer get categoryFk {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$AssociatedTitlesTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $AssociatedTitlesTable> {
  $$AssociatedTitlesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get associatedTitlePk => $state.composableBuilder(
      column: $state.table.associatedTitlePk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isExactMatch => $state.composableBuilder(
      column: $state.table.isExactMatch,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CategoriesTableOrderingComposer get categoryFk {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$AppSettingsTableInsertCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> settingsPk,
  required String settingsJSON,
  Value<DateTime> dateUpdated,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> settingsPk,
  Value<String> settingsJSON,
  Value<DateTime> dateUpdated,
});

class $$AppSettingsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableProcessedTableManager,
    $$AppSettingsTableInsertCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder> {
  $$AppSettingsTableTableManager(_$FinanceDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AppSettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AppSettingsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$AppSettingsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<int> settingsPk = const Value.absent(),
            Value<String> settingsJSON = const Value.absent(),
            Value<DateTime> dateUpdated = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            settingsPk: settingsPk,
            settingsJSON: settingsJSON,
            dateUpdated: dateUpdated,
          ),
          getInsertCompanionBuilder: ({
            Value<int> settingsPk = const Value.absent(),
            required String settingsJSON,
            Value<DateTime> dateUpdated = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            settingsPk: settingsPk,
            settingsJSON: settingsJSON,
            dateUpdated: dateUpdated,
          ),
        ));
}

class $$AppSettingsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableProcessedTableManager,
    $$AppSettingsTableInsertCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder> {
  $$AppSettingsTableProcessedTableManager(super.$state);
}

class $$AppSettingsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer(super.$state);
  ColumnFilters<int> get settingsPk => $state.composableBuilder(
      column: $state.table.settingsPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get settingsJSON => $state.composableBuilder(
      column: $state.table.settingsJSON,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateUpdated => $state.composableBuilder(
      column: $state.table.dateUpdated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AppSettingsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get settingsPk => $state.composableBuilder(
      column: $state.table.settingsPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get settingsJSON => $state.composableBuilder(
      column: $state.table.settingsJSON,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateUpdated => $state.composableBuilder(
      column: $state.table.dateUpdated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ScannerTemplatesTableInsertCompanionBuilder
    = ScannerTemplatesCompanion Function({
  Value<String> scannerTemplatePk,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  required String templateName,
  required String contains,
  required String titleTransactionBefore,
  required String titleTransactionAfter,
  required String amountTransactionBefore,
  required String amountTransactionAfter,
  required String defaultCategoryFk,
  Value<String> walletFk,
  Value<bool> ignore,
  Value<int> rowid,
});
typedef $$ScannerTemplatesTableUpdateCompanionBuilder
    = ScannerTemplatesCompanion Function({
  Value<String> scannerTemplatePk,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<String> templateName,
  Value<String> contains,
  Value<String> titleTransactionBefore,
  Value<String> titleTransactionAfter,
  Value<String> amountTransactionBefore,
  Value<String> amountTransactionAfter,
  Value<String> defaultCategoryFk,
  Value<String> walletFk,
  Value<bool> ignore,
  Value<int> rowid,
});

class $$ScannerTemplatesTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $ScannerTemplatesTable,
    ScannerTemplate,
    $$ScannerTemplatesTableFilterComposer,
    $$ScannerTemplatesTableOrderingComposer,
    $$ScannerTemplatesTableProcessedTableManager,
    $$ScannerTemplatesTableInsertCompanionBuilder,
    $$ScannerTemplatesTableUpdateCompanionBuilder> {
  $$ScannerTemplatesTableTableManager(
      _$FinanceDatabase db, $ScannerTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ScannerTemplatesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ScannerTemplatesTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$ScannerTemplatesTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> scannerTemplatePk = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<String> templateName = const Value.absent(),
            Value<String> contains = const Value.absent(),
            Value<String> titleTransactionBefore = const Value.absent(),
            Value<String> titleTransactionAfter = const Value.absent(),
            Value<String> amountTransactionBefore = const Value.absent(),
            Value<String> amountTransactionAfter = const Value.absent(),
            Value<String> defaultCategoryFk = const Value.absent(),
            Value<String> walletFk = const Value.absent(),
            Value<bool> ignore = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScannerTemplatesCompanion(
            scannerTemplatePk: scannerTemplatePk,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            templateName: templateName,
            contains: contains,
            titleTransactionBefore: titleTransactionBefore,
            titleTransactionAfter: titleTransactionAfter,
            amountTransactionBefore: amountTransactionBefore,
            amountTransactionAfter: amountTransactionAfter,
            defaultCategoryFk: defaultCategoryFk,
            walletFk: walletFk,
            ignore: ignore,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> scannerTemplatePk = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            required String templateName,
            required String contains,
            required String titleTransactionBefore,
            required String titleTransactionAfter,
            required String amountTransactionBefore,
            required String amountTransactionAfter,
            required String defaultCategoryFk,
            Value<String> walletFk = const Value.absent(),
            Value<bool> ignore = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScannerTemplatesCompanion.insert(
            scannerTemplatePk: scannerTemplatePk,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            templateName: templateName,
            contains: contains,
            titleTransactionBefore: titleTransactionBefore,
            titleTransactionAfter: titleTransactionAfter,
            amountTransactionBefore: amountTransactionBefore,
            amountTransactionAfter: amountTransactionAfter,
            defaultCategoryFk: defaultCategoryFk,
            walletFk: walletFk,
            ignore: ignore,
            rowid: rowid,
          ),
        ));
}

class $$ScannerTemplatesTableProcessedTableManager
    extends ProcessedTableManager<
        _$FinanceDatabase,
        $ScannerTemplatesTable,
        ScannerTemplate,
        $$ScannerTemplatesTableFilterComposer,
        $$ScannerTemplatesTableOrderingComposer,
        $$ScannerTemplatesTableProcessedTableManager,
        $$ScannerTemplatesTableInsertCompanionBuilder,
        $$ScannerTemplatesTableUpdateCompanionBuilder> {
  $$ScannerTemplatesTableProcessedTableManager(super.$state);
}

class $$ScannerTemplatesTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $ScannerTemplatesTable> {
  $$ScannerTemplatesTableFilterComposer(super.$state);
  ColumnFilters<String> get scannerTemplatePk => $state.composableBuilder(
      column: $state.table.scannerTemplatePk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get templateName => $state.composableBuilder(
      column: $state.table.templateName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get contains => $state.composableBuilder(
      column: $state.table.contains,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get titleTransactionBefore => $state.composableBuilder(
      column: $state.table.titleTransactionBefore,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get titleTransactionAfter => $state.composableBuilder(
      column: $state.table.titleTransactionAfter,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get amountTransactionBefore => $state.composableBuilder(
      column: $state.table.amountTransactionBefore,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get amountTransactionAfter => $state.composableBuilder(
      column: $state.table.amountTransactionAfter,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get ignore => $state.composableBuilder(
      column: $state.table.ignore,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CategoriesTableFilterComposer get defaultCategoryFk {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.defaultCategoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  $$WalletsTableFilterComposer get walletFk {
    final $$WalletsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) => $$WalletsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$ScannerTemplatesTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $ScannerTemplatesTable> {
  $$ScannerTemplatesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get scannerTemplatePk => $state.composableBuilder(
      column: $state.table.scannerTemplatePk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get templateName => $state.composableBuilder(
      column: $state.table.templateName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get contains => $state.composableBuilder(
      column: $state.table.contains,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get titleTransactionBefore =>
      $state.composableBuilder(
          column: $state.table.titleTransactionBefore,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get titleTransactionAfter => $state.composableBuilder(
      column: $state.table.titleTransactionAfter,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get amountTransactionBefore =>
      $state.composableBuilder(
          column: $state.table.amountTransactionBefore,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get amountTransactionAfter =>
      $state.composableBuilder(
          column: $state.table.amountTransactionAfter,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get ignore => $state.composableBuilder(
      column: $state.table.ignore,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CategoriesTableOrderingComposer get defaultCategoryFk {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.defaultCategoryFk,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.categoryPk,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  $$WalletsTableOrderingComposer get walletFk {
    final $$WalletsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) =>
            $$WalletsTableOrderingComposer(ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$DeleteLogsTableInsertCompanionBuilder = DeleteLogsCompanion Function({
  Value<String> deleteLogPk,
  required String entryPk,
  required DeleteLogType type,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});
typedef $$DeleteLogsTableUpdateCompanionBuilder = DeleteLogsCompanion Function({
  Value<String> deleteLogPk,
  Value<String> entryPk,
  Value<DeleteLogType> type,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$DeleteLogsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $DeleteLogsTable,
    DeleteLog,
    $$DeleteLogsTableFilterComposer,
    $$DeleteLogsTableOrderingComposer,
    $$DeleteLogsTableProcessedTableManager,
    $$DeleteLogsTableInsertCompanionBuilder,
    $$DeleteLogsTableUpdateCompanionBuilder> {
  $$DeleteLogsTableTableManager(_$FinanceDatabase db, $DeleteLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DeleteLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DeleteLogsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$DeleteLogsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> deleteLogPk = const Value.absent(),
            Value<String> entryPk = const Value.absent(),
            Value<DeleteLogType> type = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeleteLogsCompanion(
            deleteLogPk: deleteLogPk,
            entryPk: entryPk,
            type: type,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> deleteLogPk = const Value.absent(),
            required String entryPk,
            required DeleteLogType type,
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeleteLogsCompanion.insert(
            deleteLogPk: deleteLogPk,
            entryPk: entryPk,
            type: type,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$DeleteLogsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $DeleteLogsTable,
    DeleteLog,
    $$DeleteLogsTableFilterComposer,
    $$DeleteLogsTableOrderingComposer,
    $$DeleteLogsTableProcessedTableManager,
    $$DeleteLogsTableInsertCompanionBuilder,
    $$DeleteLogsTableUpdateCompanionBuilder> {
  $$DeleteLogsTableProcessedTableManager(super.$state);
}

class $$DeleteLogsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableFilterComposer(super.$state);
  ColumnFilters<String> get deleteLogPk => $state.composableBuilder(
      column: $state.table.deleteLogPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entryPk => $state.composableBuilder(
      column: $state.table.entryPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<DeleteLogType, DeleteLogType, int> get type =>
      $state.composableBuilder(
          column: $state.table.type,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DeleteLogsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get deleteLogPk => $state.composableBuilder(
      column: $state.table.deleteLogPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entryPk => $state.composableBuilder(
      column: $state.table.entryPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$FireflyIdMapTableInsertCompanionBuilder = FireflyIdMapCompanion
    Function({
  required FireflyEntityType entityType,
  required String localPk,
  required String remoteId,
  Value<String> remoteSubId,
  Value<int> remoteRole,
  Value<DateTime?> remoteUpdatedAt,
  Value<DateTime?> localVersionAt,
  Value<String?> syncedHash,
  Value<String?> lossyFields,
  required FireflySyncState state,
  Value<int> attempts,
  Value<String?> lastError,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});
typedef $$FireflyIdMapTableUpdateCompanionBuilder = FireflyIdMapCompanion
    Function({
  Value<FireflyEntityType> entityType,
  Value<String> localPk,
  Value<String> remoteId,
  Value<String> remoteSubId,
  Value<int> remoteRole,
  Value<DateTime?> remoteUpdatedAt,
  Value<DateTime?> localVersionAt,
  Value<String?> syncedHash,
  Value<String?> lossyFields,
  Value<FireflySyncState> state,
  Value<int> attempts,
  Value<String?> lastError,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});

class $$FireflyIdMapTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $FireflyIdMapTable,
    FireflyIdMapping,
    $$FireflyIdMapTableFilterComposer,
    $$FireflyIdMapTableOrderingComposer,
    $$FireflyIdMapTableProcessedTableManager,
    $$FireflyIdMapTableInsertCompanionBuilder,
    $$FireflyIdMapTableUpdateCompanionBuilder> {
  $$FireflyIdMapTableTableManager(
      _$FinanceDatabase db, $FireflyIdMapTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$FireflyIdMapTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$FireflyIdMapTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$FireflyIdMapTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<FireflyEntityType> entityType = const Value.absent(),
            Value<String> localPk = const Value.absent(),
            Value<String> remoteId = const Value.absent(),
            Value<String> remoteSubId = const Value.absent(),
            Value<int> remoteRole = const Value.absent(),
            Value<DateTime?> remoteUpdatedAt = const Value.absent(),
            Value<DateTime?> localVersionAt = const Value.absent(),
            Value<String?> syncedHash = const Value.absent(),
            Value<String?> lossyFields = const Value.absent(),
            Value<FireflySyncState> state = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FireflyIdMapCompanion(
            entityType: entityType,
            localPk: localPk,
            remoteId: remoteId,
            remoteSubId: remoteSubId,
            remoteRole: remoteRole,
            remoteUpdatedAt: remoteUpdatedAt,
            localVersionAt: localVersionAt,
            syncedHash: syncedHash,
            lossyFields: lossyFields,
            state: state,
            attempts: attempts,
            lastError: lastError,
            lastAttemptAt: lastAttemptAt,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required FireflyEntityType entityType,
            required String localPk,
            required String remoteId,
            Value<String> remoteSubId = const Value.absent(),
            Value<int> remoteRole = const Value.absent(),
            Value<DateTime?> remoteUpdatedAt = const Value.absent(),
            Value<DateTime?> localVersionAt = const Value.absent(),
            Value<String?> syncedHash = const Value.absent(),
            Value<String?> lossyFields = const Value.absent(),
            required FireflySyncState state,
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FireflyIdMapCompanion.insert(
            entityType: entityType,
            localPk: localPk,
            remoteId: remoteId,
            remoteSubId: remoteSubId,
            remoteRole: remoteRole,
            remoteUpdatedAt: remoteUpdatedAt,
            localVersionAt: localVersionAt,
            syncedHash: syncedHash,
            lossyFields: lossyFields,
            state: state,
            attempts: attempts,
            lastError: lastError,
            lastAttemptAt: lastAttemptAt,
            rowid: rowid,
          ),
        ));
}

class $$FireflyIdMapTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $FireflyIdMapTable,
    FireflyIdMapping,
    $$FireflyIdMapTableFilterComposer,
    $$FireflyIdMapTableOrderingComposer,
    $$FireflyIdMapTableProcessedTableManager,
    $$FireflyIdMapTableInsertCompanionBuilder,
    $$FireflyIdMapTableUpdateCompanionBuilder> {
  $$FireflyIdMapTableProcessedTableManager(super.$state);
}

class $$FireflyIdMapTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $FireflyIdMapTable> {
  $$FireflyIdMapTableFilterComposer(super.$state);
  ColumnWithTypeConverterFilters<FireflyEntityType, FireflyEntityType, int>
      get entityType => $state.composableBuilder(
          column: $state.table.entityType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get localPk => $state.composableBuilder(
      column: $state.table.localPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get remoteId => $state.composableBuilder(
      column: $state.table.remoteId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get remoteSubId => $state.composableBuilder(
      column: $state.table.remoteSubId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get remoteRole => $state.composableBuilder(
      column: $state.table.remoteRole,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get remoteUpdatedAt => $state.composableBuilder(
      column: $state.table.remoteUpdatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get localVersionAt => $state.composableBuilder(
      column: $state.table.localVersionAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncedHash => $state.composableBuilder(
      column: $state.table.syncedHash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lossyFields => $state.composableBuilder(
      column: $state.table.lossyFields,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<FireflySyncState, FireflySyncState, int>
      get state => $state.composableBuilder(
          column: $state.table.state,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastError => $state.composableBuilder(
      column: $state.table.lastError,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastAttemptAt => $state.composableBuilder(
      column: $state.table.lastAttemptAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$FireflyIdMapTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $FireflyIdMapTable> {
  $$FireflyIdMapTableOrderingComposer(super.$state);
  ColumnOrderings<int> get entityType => $state.composableBuilder(
      column: $state.table.entityType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localPk => $state.composableBuilder(
      column: $state.table.localPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get remoteId => $state.composableBuilder(
      column: $state.table.remoteId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get remoteSubId => $state.composableBuilder(
      column: $state.table.remoteSubId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get remoteRole => $state.composableBuilder(
      column: $state.table.remoteRole,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get remoteUpdatedAt => $state.composableBuilder(
      column: $state.table.remoteUpdatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get localVersionAt => $state.composableBuilder(
      column: $state.table.localVersionAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncedHash => $state.composableBuilder(
      column: $state.table.syncedHash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lossyFields => $state.composableBuilder(
      column: $state.table.lossyFields,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get state => $state.composableBuilder(
      column: $state.table.state,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastError => $state.composableBuilder(
      column: $state.table.lastError,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastAttemptAt => $state.composableBuilder(
      column: $state.table.lastAttemptAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$FireflySyncMetaTableInsertCompanionBuilder = FireflySyncMetaCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$FireflySyncMetaTableUpdateCompanionBuilder = FireflySyncMetaCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$FireflySyncMetaTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $FireflySyncMetaTable,
    FireflySyncMetaEntry,
    $$FireflySyncMetaTableFilterComposer,
    $$FireflySyncMetaTableOrderingComposer,
    $$FireflySyncMetaTableProcessedTableManager,
    $$FireflySyncMetaTableInsertCompanionBuilder,
    $$FireflySyncMetaTableUpdateCompanionBuilder> {
  $$FireflySyncMetaTableTableManager(
      _$FinanceDatabase db, $FireflySyncMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$FireflySyncMetaTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$FireflySyncMetaTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$FireflySyncMetaTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FireflySyncMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              FireflySyncMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
        ));
}

class $$FireflySyncMetaTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $FireflySyncMetaTable,
    FireflySyncMetaEntry,
    $$FireflySyncMetaTableFilterComposer,
    $$FireflySyncMetaTableOrderingComposer,
    $$FireflySyncMetaTableProcessedTableManager,
    $$FireflySyncMetaTableInsertCompanionBuilder,
    $$FireflySyncMetaTableUpdateCompanionBuilder> {
  $$FireflySyncMetaTableProcessedTableManager(super.$state);
}

class $$FireflySyncMetaTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $FireflySyncMetaTable> {
  $$FireflySyncMetaTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$FireflySyncMetaTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $FireflySyncMetaTable> {
  $$FireflySyncMetaTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$FireflyConflictsTableInsertCompanionBuilder
    = FireflyConflictsCompanion Function({
  Value<String> conflictPk,
  required FireflyEntityType entityType,
  required String localPk,
  required String remoteId,
  required String localJson,
  Value<String?> remoteJson,
  required String resolution,
  Value<DateTime> dateCreated,
  Value<bool> acknowledged,
  Value<int> rowid,
});
typedef $$FireflyConflictsTableUpdateCompanionBuilder
    = FireflyConflictsCompanion Function({
  Value<String> conflictPk,
  Value<FireflyEntityType> entityType,
  Value<String> localPk,
  Value<String> remoteId,
  Value<String> localJson,
  Value<String?> remoteJson,
  Value<String> resolution,
  Value<DateTime> dateCreated,
  Value<bool> acknowledged,
  Value<int> rowid,
});

class $$FireflyConflictsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $FireflyConflictsTable,
    FireflyConflict,
    $$FireflyConflictsTableFilterComposer,
    $$FireflyConflictsTableOrderingComposer,
    $$FireflyConflictsTableProcessedTableManager,
    $$FireflyConflictsTableInsertCompanionBuilder,
    $$FireflyConflictsTableUpdateCompanionBuilder> {
  $$FireflyConflictsTableTableManager(
      _$FinanceDatabase db, $FireflyConflictsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$FireflyConflictsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$FireflyConflictsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$FireflyConflictsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> conflictPk = const Value.absent(),
            Value<FireflyEntityType> entityType = const Value.absent(),
            Value<String> localPk = const Value.absent(),
            Value<String> remoteId = const Value.absent(),
            Value<String> localJson = const Value.absent(),
            Value<String?> remoteJson = const Value.absent(),
            Value<String> resolution = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<bool> acknowledged = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FireflyConflictsCompanion(
            conflictPk: conflictPk,
            entityType: entityType,
            localPk: localPk,
            remoteId: remoteId,
            localJson: localJson,
            remoteJson: remoteJson,
            resolution: resolution,
            dateCreated: dateCreated,
            acknowledged: acknowledged,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> conflictPk = const Value.absent(),
            required FireflyEntityType entityType,
            required String localPk,
            required String remoteId,
            required String localJson,
            Value<String?> remoteJson = const Value.absent(),
            required String resolution,
            Value<DateTime> dateCreated = const Value.absent(),
            Value<bool> acknowledged = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FireflyConflictsCompanion.insert(
            conflictPk: conflictPk,
            entityType: entityType,
            localPk: localPk,
            remoteId: remoteId,
            localJson: localJson,
            remoteJson: remoteJson,
            resolution: resolution,
            dateCreated: dateCreated,
            acknowledged: acknowledged,
            rowid: rowid,
          ),
        ));
}

class $$FireflyConflictsTableProcessedTableManager
    extends ProcessedTableManager<
        _$FinanceDatabase,
        $FireflyConflictsTable,
        FireflyConflict,
        $$FireflyConflictsTableFilterComposer,
        $$FireflyConflictsTableOrderingComposer,
        $$FireflyConflictsTableProcessedTableManager,
        $$FireflyConflictsTableInsertCompanionBuilder,
        $$FireflyConflictsTableUpdateCompanionBuilder> {
  $$FireflyConflictsTableProcessedTableManager(super.$state);
}

class $$FireflyConflictsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $FireflyConflictsTable> {
  $$FireflyConflictsTableFilterComposer(super.$state);
  ColumnFilters<String> get conflictPk => $state.composableBuilder(
      column: $state.table.conflictPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<FireflyEntityType, FireflyEntityType, int>
      get entityType => $state.composableBuilder(
          column: $state.table.entityType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get localPk => $state.composableBuilder(
      column: $state.table.localPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get remoteId => $state.composableBuilder(
      column: $state.table.remoteId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localJson => $state.composableBuilder(
      column: $state.table.localJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get remoteJson => $state.composableBuilder(
      column: $state.table.remoteJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get resolution => $state.composableBuilder(
      column: $state.table.resolution,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get acknowledged => $state.composableBuilder(
      column: $state.table.acknowledged,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$FireflyConflictsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $FireflyConflictsTable> {
  $$FireflyConflictsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get conflictPk => $state.composableBuilder(
      column: $state.table.conflictPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get entityType => $state.composableBuilder(
      column: $state.table.entityType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localPk => $state.composableBuilder(
      column: $state.table.localPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get remoteId => $state.composableBuilder(
      column: $state.table.remoteId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localJson => $state.composableBuilder(
      column: $state.table.localJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get remoteJson => $state.composableBuilder(
      column: $state.table.remoteJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get resolution => $state.composableBuilder(
      column: $state.table.resolution,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get acknowledged => $state.composableBuilder(
      column: $state.table.acknowledged,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$FireflyResourceCacheTableInsertCompanionBuilder
    = FireflyResourceCacheCompanion Function({
  required String resourcePk,
  required FireflyEntityType entityType,
  required String json,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});
typedef $$FireflyResourceCacheTableUpdateCompanionBuilder
    = FireflyResourceCacheCompanion Function({
  Value<String> resourcePk,
  Value<FireflyEntityType> entityType,
  Value<String> json,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});

class $$FireflyResourceCacheTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $FireflyResourceCacheTable,
    FireflyCachedResource,
    $$FireflyResourceCacheTableFilterComposer,
    $$FireflyResourceCacheTableOrderingComposer,
    $$FireflyResourceCacheTableProcessedTableManager,
    $$FireflyResourceCacheTableInsertCompanionBuilder,
    $$FireflyResourceCacheTableUpdateCompanionBuilder> {
  $$FireflyResourceCacheTableTableManager(
      _$FinanceDatabase db, $FireflyResourceCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$FireflyResourceCacheTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$FireflyResourceCacheTableOrderingComposer(
              ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$FireflyResourceCacheTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> resourcePk = const Value.absent(),
            Value<FireflyEntityType> entityType = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FireflyResourceCacheCompanion(
            resourcePk: resourcePk,
            entityType: entityType,
            json: json,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String resourcePk,
            required FireflyEntityType entityType,
            required String json,
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FireflyResourceCacheCompanion.insert(
            resourcePk: resourcePk,
            entityType: entityType,
            json: json,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$FireflyResourceCacheTableProcessedTableManager
    extends ProcessedTableManager<
        _$FinanceDatabase,
        $FireflyResourceCacheTable,
        FireflyCachedResource,
        $$FireflyResourceCacheTableFilterComposer,
        $$FireflyResourceCacheTableOrderingComposer,
        $$FireflyResourceCacheTableProcessedTableManager,
        $$FireflyResourceCacheTableInsertCompanionBuilder,
        $$FireflyResourceCacheTableUpdateCompanionBuilder> {
  $$FireflyResourceCacheTableProcessedTableManager(super.$state);
}

class $$FireflyResourceCacheTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $FireflyResourceCacheTable> {
  $$FireflyResourceCacheTableFilterComposer(super.$state);
  ColumnFilters<String> get resourcePk => $state.composableBuilder(
      column: $state.table.resourcePk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<FireflyEntityType, FireflyEntityType, int>
      get entityType => $state.composableBuilder(
          column: $state.table.entityType,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get json => $state.composableBuilder(
      column: $state.table.json,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$FireflyResourceCacheTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $FireflyResourceCacheTable> {
  $$FireflyResourceCacheTableOrderingComposer(super.$state);
  ColumnOrderings<String> get resourcePk => $state.composableBuilder(
      column: $state.table.resourcePk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get entityType => $state.composableBuilder(
      column: $state.table.entityType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get json => $state.composableBuilder(
      column: $state.table.json,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TagsTableInsertCompanionBuilder = TagsCompanion Function({
  Value<String> tagPk,
  required String name,
  Value<String?> description,
  Value<DateTime?> date,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> tagPk,
  Value<String> name,
  Value<String?> description,
  Value<DateTime?> date,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});

class $$TagsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableProcessedTableManager,
    $$TagsTableInsertCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder> {
  $$TagsTableTableManager(_$FinanceDatabase db, $TagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TagsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TagsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) => $$TagsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> tagPk = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsCompanion(
            tagPk: tagPk,
            name: name,
            description: description,
            date: date,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> tagPk = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsCompanion.insert(
            tagPk: tagPk,
            name: name,
            description: description,
            date: date,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$TagsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableProcessedTableManager,
    $$TagsTableInsertCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder> {
  $$TagsTableProcessedTableManager(super.$state);
}

class $$TagsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $TagsTable> {
  $$TagsTableFilterComposer(super.$state);
  ColumnFilters<String> get tagPk => $state.composableBuilder(
      column: $state.table.tagPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter transactionTagsRefs(
      ComposableFilter Function($$TransactionTagsTableFilterComposer f) f) {
    final $$TransactionTagsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.tagPk,
            referencedTable: $state.db.transactionTags,
            getReferencedColumn: (t) => t.tagFk,
            builder: (joinBuilder, parentComposers) =>
                $$TransactionTagsTableFilterComposer(ComposerState($state.db,
                    $state.db.transactionTags, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$TagsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $TagsTable> {
  $$TagsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get tagPk => $state.composableBuilder(
      column: $state.table.tagPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TransactionTagsTableInsertCompanionBuilder = TransactionTagsCompanion
    Function({
  required String transactionFk,
  required String tagFk,
  Value<int> rowid,
});
typedef $$TransactionTagsTableUpdateCompanionBuilder = TransactionTagsCompanion
    Function({
  Value<String> transactionFk,
  Value<String> tagFk,
  Value<int> rowid,
});

class $$TransactionTagsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $TransactionTagsTable,
    TransactionTagLink,
    $$TransactionTagsTableFilterComposer,
    $$TransactionTagsTableOrderingComposer,
    $$TransactionTagsTableProcessedTableManager,
    $$TransactionTagsTableInsertCompanionBuilder,
    $$TransactionTagsTableUpdateCompanionBuilder> {
  $$TransactionTagsTableTableManager(
      _$FinanceDatabase db, $TransactionTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TransactionTagsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TransactionTagsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$TransactionTagsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> transactionFk = const Value.absent(),
            Value<String> tagFk = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionTagsCompanion(
            transactionFk: transactionFk,
            tagFk: tagFk,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String transactionFk,
            required String tagFk,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionTagsCompanion.insert(
            transactionFk: transactionFk,
            tagFk: tagFk,
            rowid: rowid,
          ),
        ));
}

class $$TransactionTagsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $TransactionTagsTable,
    TransactionTagLink,
    $$TransactionTagsTableFilterComposer,
    $$TransactionTagsTableOrderingComposer,
    $$TransactionTagsTableProcessedTableManager,
    $$TransactionTagsTableInsertCompanionBuilder,
    $$TransactionTagsTableUpdateCompanionBuilder> {
  $$TransactionTagsTableProcessedTableManager(super.$state);
}

class $$TransactionTagsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $TransactionTagsTable> {
  $$TransactionTagsTableFilterComposer(super.$state);
  $$TransactionsTableFilterComposer get transactionFk {
    final $$TransactionsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionFk,
        referencedTable: $state.db.transactions,
        getReferencedColumn: (t) => t.transactionPk,
        builder: (joinBuilder, parentComposers) =>
            $$TransactionsTableFilterComposer(ComposerState($state.db,
                $state.db.transactions, joinBuilder, parentComposers)));
    return composer;
  }

  $$TagsTableFilterComposer get tagFk {
    final $$TagsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagFk,
        referencedTable: $state.db.tags,
        getReferencedColumn: (t) => t.tagPk,
        builder: (joinBuilder, parentComposers) => $$TagsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.tags, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$TransactionTagsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $TransactionTagsTable> {
  $$TransactionTagsTableOrderingComposer(super.$state);
  $$TransactionsTableOrderingComposer get transactionFk {
    final $$TransactionsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionFk,
        referencedTable: $state.db.transactions,
        getReferencedColumn: (t) => t.transactionPk,
        builder: (joinBuilder, parentComposers) =>
            $$TransactionsTableOrderingComposer(ComposerState($state.db,
                $state.db.transactions, joinBuilder, parentComposers)));
    return composer;
  }

  $$TagsTableOrderingComposer get tagFk {
    final $$TagsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagFk,
        referencedTable: $state.db.tags,
        getReferencedColumn: (t) => t.tagPk,
        builder: (joinBuilder, parentComposers) => $$TagsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.tags, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$AttachmentsTableInsertCompanionBuilder = AttachmentsCompanion
    Function({
  Value<String> attachmentPk,
  required String attachableType,
  required String attachableFk,
  required String filename,
  Value<String?> title,
  Value<String?> mime,
  Value<int?> size,
  Value<String?> localPath,
  Value<String?> hash,
  required String uploadState,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});
typedef $$AttachmentsTableUpdateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<String> attachmentPk,
  Value<String> attachableType,
  Value<String> attachableFk,
  Value<String> filename,
  Value<String?> title,
  Value<String?> mime,
  Value<int?> size,
  Value<String?> localPath,
  Value<String?> hash,
  Value<String> uploadState,
  Value<DateTime> dateCreated,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});

class $$AttachmentsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableProcessedTableManager,
    $$AttachmentsTableInsertCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder> {
  $$AttachmentsTableTableManager(_$FinanceDatabase db, $AttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AttachmentsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AttachmentsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$AttachmentsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> attachmentPk = const Value.absent(),
            Value<String> attachableType = const Value.absent(),
            Value<String> attachableFk = const Value.absent(),
            Value<String> filename = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> mime = const Value.absent(),
            Value<int?> size = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> hash = const Value.absent(),
            Value<String> uploadState = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion(
            attachmentPk: attachmentPk,
            attachableType: attachableType,
            attachableFk: attachableFk,
            filename: filename,
            title: title,
            mime: mime,
            size: size,
            localPath: localPath,
            hash: hash,
            uploadState: uploadState,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> attachmentPk = const Value.absent(),
            required String attachableType,
            required String attachableFk,
            required String filename,
            Value<String?> title = const Value.absent(),
            Value<String?> mime = const Value.absent(),
            Value<int?> size = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> hash = const Value.absent(),
            required String uploadState,
            Value<DateTime> dateCreated = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion.insert(
            attachmentPk: attachmentPk,
            attachableType: attachableType,
            attachableFk: attachableFk,
            filename: filename,
            title: title,
            mime: mime,
            size: size,
            localPath: localPath,
            hash: hash,
            uploadState: uploadState,
            dateCreated: dateCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$AttachmentsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableProcessedTableManager,
    $$AttachmentsTableInsertCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder> {
  $$AttachmentsTableProcessedTableManager(super.$state);
}

class $$AttachmentsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer(super.$state);
  ColumnFilters<String> get attachmentPk => $state.composableBuilder(
      column: $state.table.attachmentPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get attachableType => $state.composableBuilder(
      column: $state.table.attachableType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get attachableFk => $state.composableBuilder(
      column: $state.table.attachableFk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get filename => $state.composableBuilder(
      column: $state.table.filename,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mime => $state.composableBuilder(
      column: $state.table.mime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get size => $state.composableBuilder(
      column: $state.table.size,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localPath => $state.composableBuilder(
      column: $state.table.localPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get hash => $state.composableBuilder(
      column: $state.table.hash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get uploadState => $state.composableBuilder(
      column: $state.table.uploadState,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AttachmentsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get attachmentPk => $state.composableBuilder(
      column: $state.table.attachmentPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get attachableType => $state.composableBuilder(
      column: $state.table.attachableType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get attachableFk => $state.composableBuilder(
      column: $state.table.attachableFk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get filename => $state.composableBuilder(
      column: $state.table.filename,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mime => $state.composableBuilder(
      column: $state.table.mime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get size => $state.composableBuilder(
      column: $state.table.size,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localPath => $state.composableBuilder(
      column: $state.table.localPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get hash => $state.composableBuilder(
      column: $state.table.hash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get uploadState => $state.composableBuilder(
      column: $state.table.uploadState,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$AccountDetailsTableInsertCompanionBuilder = AccountDetailsCompanion
    Function({
  required String walletFk,
  Value<String?> accountRole,
  Value<String?> liabilityType,
  Value<String?> liabilityDirection,
  Value<double?> interest,
  Value<String?> interestPeriod,
  Value<String?> iban,
  Value<String?> bic,
  Value<String?> accountNumber,
  Value<String?> notes,
  Value<bool?> includeNetWorth,
  Value<double?> virtualBalance,
  Value<double?> serverBalance,
  Value<DateTime?> serverBalanceDate,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});
typedef $$AccountDetailsTableUpdateCompanionBuilder = AccountDetailsCompanion
    Function({
  Value<String> walletFk,
  Value<String?> accountRole,
  Value<String?> liabilityType,
  Value<String?> liabilityDirection,
  Value<double?> interest,
  Value<String?> interestPeriod,
  Value<String?> iban,
  Value<String?> bic,
  Value<String?> accountNumber,
  Value<String?> notes,
  Value<bool?> includeNetWorth,
  Value<double?> virtualBalance,
  Value<double?> serverBalance,
  Value<DateTime?> serverBalanceDate,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});

class $$AccountDetailsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $AccountDetailsTable,
    AccountDetail,
    $$AccountDetailsTableFilterComposer,
    $$AccountDetailsTableOrderingComposer,
    $$AccountDetailsTableProcessedTableManager,
    $$AccountDetailsTableInsertCompanionBuilder,
    $$AccountDetailsTableUpdateCompanionBuilder> {
  $$AccountDetailsTableTableManager(
      _$FinanceDatabase db, $AccountDetailsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AccountDetailsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AccountDetailsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$AccountDetailsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> walletFk = const Value.absent(),
            Value<String?> accountRole = const Value.absent(),
            Value<String?> liabilityType = const Value.absent(),
            Value<String?> liabilityDirection = const Value.absent(),
            Value<double?> interest = const Value.absent(),
            Value<String?> interestPeriod = const Value.absent(),
            Value<String?> iban = const Value.absent(),
            Value<String?> bic = const Value.absent(),
            Value<String?> accountNumber = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool?> includeNetWorth = const Value.absent(),
            Value<double?> virtualBalance = const Value.absent(),
            Value<double?> serverBalance = const Value.absent(),
            Value<DateTime?> serverBalanceDate = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountDetailsCompanion(
            walletFk: walletFk,
            accountRole: accountRole,
            liabilityType: liabilityType,
            liabilityDirection: liabilityDirection,
            interest: interest,
            interestPeriod: interestPeriod,
            iban: iban,
            bic: bic,
            accountNumber: accountNumber,
            notes: notes,
            includeNetWorth: includeNetWorth,
            virtualBalance: virtualBalance,
            serverBalance: serverBalance,
            serverBalanceDate: serverBalanceDate,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String walletFk,
            Value<String?> accountRole = const Value.absent(),
            Value<String?> liabilityType = const Value.absent(),
            Value<String?> liabilityDirection = const Value.absent(),
            Value<double?> interest = const Value.absent(),
            Value<String?> interestPeriod = const Value.absent(),
            Value<String?> iban = const Value.absent(),
            Value<String?> bic = const Value.absent(),
            Value<String?> accountNumber = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool?> includeNetWorth = const Value.absent(),
            Value<double?> virtualBalance = const Value.absent(),
            Value<double?> serverBalance = const Value.absent(),
            Value<DateTime?> serverBalanceDate = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountDetailsCompanion.insert(
            walletFk: walletFk,
            accountRole: accountRole,
            liabilityType: liabilityType,
            liabilityDirection: liabilityDirection,
            interest: interest,
            interestPeriod: interestPeriod,
            iban: iban,
            bic: bic,
            accountNumber: accountNumber,
            notes: notes,
            includeNetWorth: includeNetWorth,
            virtualBalance: virtualBalance,
            serverBalance: serverBalance,
            serverBalanceDate: serverBalanceDate,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$AccountDetailsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $AccountDetailsTable,
    AccountDetail,
    $$AccountDetailsTableFilterComposer,
    $$AccountDetailsTableOrderingComposer,
    $$AccountDetailsTableProcessedTableManager,
    $$AccountDetailsTableInsertCompanionBuilder,
    $$AccountDetailsTableUpdateCompanionBuilder> {
  $$AccountDetailsTableProcessedTableManager(super.$state);
}

class $$AccountDetailsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $AccountDetailsTable> {
  $$AccountDetailsTableFilterComposer(super.$state);
  ColumnFilters<String> get accountRole => $state.composableBuilder(
      column: $state.table.accountRole,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get liabilityType => $state.composableBuilder(
      column: $state.table.liabilityType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get liabilityDirection => $state.composableBuilder(
      column: $state.table.liabilityDirection,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get interest => $state.composableBuilder(
      column: $state.table.interest,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get interestPeriod => $state.composableBuilder(
      column: $state.table.interestPeriod,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iban => $state.composableBuilder(
      column: $state.table.iban,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get bic => $state.composableBuilder(
      column: $state.table.bic,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get accountNumber => $state.composableBuilder(
      column: $state.table.accountNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get includeNetWorth => $state.composableBuilder(
      column: $state.table.includeNetWorth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get virtualBalance => $state.composableBuilder(
      column: $state.table.virtualBalance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get serverBalance => $state.composableBuilder(
      column: $state.table.serverBalance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get serverBalanceDate => $state.composableBuilder(
      column: $state.table.serverBalanceDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$WalletsTableFilterComposer get walletFk {
    final $$WalletsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) => $$WalletsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$AccountDetailsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $AccountDetailsTable> {
  $$AccountDetailsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get accountRole => $state.composableBuilder(
      column: $state.table.accountRole,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get liabilityType => $state.composableBuilder(
      column: $state.table.liabilityType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get liabilityDirection => $state.composableBuilder(
      column: $state.table.liabilityDirection,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get interest => $state.composableBuilder(
      column: $state.table.interest,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get interestPeriod => $state.composableBuilder(
      column: $state.table.interestPeriod,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iban => $state.composableBuilder(
      column: $state.table.iban,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get bic => $state.composableBuilder(
      column: $state.table.bic,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get accountNumber => $state.composableBuilder(
      column: $state.table.accountNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get includeNetWorth => $state.composableBuilder(
      column: $state.table.includeNetWorth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get virtualBalance => $state.composableBuilder(
      column: $state.table.virtualBalance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get serverBalance => $state.composableBuilder(
      column: $state.table.serverBalance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get serverBalanceDate => $state.composableBuilder(
      column: $state.table.serverBalanceDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$WalletsTableOrderingComposer get walletFk {
    final $$WalletsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletFk,
        referencedTable: $state.db.wallets,
        getReferencedColumn: (t) => t.walletPk,
        builder: (joinBuilder, parentComposers) =>
            $$WalletsTableOrderingComposer(ComposerState(
                $state.db, $state.db.wallets, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$BudgetLimitsTableInsertCompanionBuilder = BudgetLimitsCompanion
    Function({
  Value<String> budgetLimitPk,
  required String budgetFk,
  required DateTime start,
  required DateTime end,
  required double amount,
  required String currency,
  Value<String?> notes,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});
typedef $$BudgetLimitsTableUpdateCompanionBuilder = BudgetLimitsCompanion
    Function({
  Value<String> budgetLimitPk,
  Value<String> budgetFk,
  Value<DateTime> start,
  Value<DateTime> end,
  Value<double> amount,
  Value<String> currency,
  Value<String?> notes,
  Value<DateTime?> dateTimeModified,
  Value<int> rowid,
});

class $$BudgetLimitsTableTableManager extends RootTableManager<
    _$FinanceDatabase,
    $BudgetLimitsTable,
    BudgetLimit,
    $$BudgetLimitsTableFilterComposer,
    $$BudgetLimitsTableOrderingComposer,
    $$BudgetLimitsTableProcessedTableManager,
    $$BudgetLimitsTableInsertCompanionBuilder,
    $$BudgetLimitsTableUpdateCompanionBuilder> {
  $$BudgetLimitsTableTableManager(
      _$FinanceDatabase db, $BudgetLimitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BudgetLimitsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BudgetLimitsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$BudgetLimitsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> budgetLimitPk = const Value.absent(),
            Value<String> budgetFk = const Value.absent(),
            Value<DateTime> start = const Value.absent(),
            Value<DateTime> end = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetLimitsCompanion(
            budgetLimitPk: budgetLimitPk,
            budgetFk: budgetFk,
            start: start,
            end: end,
            amount: amount,
            currency: currency,
            notes: notes,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            Value<String> budgetLimitPk = const Value.absent(),
            required String budgetFk,
            required DateTime start,
            required DateTime end,
            required double amount,
            required String currency,
            Value<String?> notes = const Value.absent(),
            Value<DateTime?> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetLimitsCompanion.insert(
            budgetLimitPk: budgetLimitPk,
            budgetFk: budgetFk,
            start: start,
            end: end,
            amount: amount,
            currency: currency,
            notes: notes,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$BudgetLimitsTableProcessedTableManager extends ProcessedTableManager<
    _$FinanceDatabase,
    $BudgetLimitsTable,
    BudgetLimit,
    $$BudgetLimitsTableFilterComposer,
    $$BudgetLimitsTableOrderingComposer,
    $$BudgetLimitsTableProcessedTableManager,
    $$BudgetLimitsTableInsertCompanionBuilder,
    $$BudgetLimitsTableUpdateCompanionBuilder> {
  $$BudgetLimitsTableProcessedTableManager(super.$state);
}

class $$BudgetLimitsTableFilterComposer
    extends FilterComposer<_$FinanceDatabase, $BudgetLimitsTable> {
  $$BudgetLimitsTableFilterComposer(super.$state);
  ColumnFilters<String> get budgetLimitPk => $state.composableBuilder(
      column: $state.table.budgetLimitPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get start => $state.composableBuilder(
      column: $state.table.start,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get end => $state.composableBuilder(
      column: $state.table.end,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$BudgetsTableFilterComposer get budgetFk {
    final $$BudgetsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.budgetFk,
        referencedTable: $state.db.budgets,
        getReferencedColumn: (t) => t.budgetPk,
        builder: (joinBuilder, parentComposers) => $$BudgetsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.budgets, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$BudgetLimitsTableOrderingComposer
    extends OrderingComposer<_$FinanceDatabase, $BudgetLimitsTable> {
  $$BudgetLimitsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get budgetLimitPk => $state.composableBuilder(
      column: $state.table.budgetLimitPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get start => $state.composableBuilder(
      column: $state.table.start,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get end => $state.composableBuilder(
      column: $state.table.end,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$BudgetsTableOrderingComposer get budgetFk {
    final $$BudgetsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.budgetFk,
        referencedTable: $state.db.budgets,
        getReferencedColumn: (t) => t.budgetPk,
        builder: (joinBuilder, parentComposers) =>
            $$BudgetsTableOrderingComposer(ComposerState(
                $state.db, $state.db.budgets, joinBuilder, parentComposers)));
    return composer;
  }
}

class _$FinanceDatabaseManager {
  final _$FinanceDatabase _db;
  _$FinanceDatabaseManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ObjectivesTableTableManager get objectives =>
      $$ObjectivesTableTableManager(_db, _db.objectives);
  $$PayeesTableTableManager get payees =>
      $$PayeesTableTableManager(_db, _db.payees);
  $$TransactionGroupsTableTableManager get transactionGroups =>
      $$TransactionGroupsTableTableManager(_db, _db.transactionGroups);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$CategoryBudgetLimitsTableTableManager get categoryBudgetLimits =>
      $$CategoryBudgetLimitsTableTableManager(_db, _db.categoryBudgetLimits);
  $$AssociatedTitlesTableTableManager get associatedTitles =>
      $$AssociatedTitlesTableTableManager(_db, _db.associatedTitles);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ScannerTemplatesTableTableManager get scannerTemplates =>
      $$ScannerTemplatesTableTableManager(_db, _db.scannerTemplates);
  $$DeleteLogsTableTableManager get deleteLogs =>
      $$DeleteLogsTableTableManager(_db, _db.deleteLogs);
  $$FireflyIdMapTableTableManager get fireflyIdMap =>
      $$FireflyIdMapTableTableManager(_db, _db.fireflyIdMap);
  $$FireflySyncMetaTableTableManager get fireflySyncMeta =>
      $$FireflySyncMetaTableTableManager(_db, _db.fireflySyncMeta);
  $$FireflyConflictsTableTableManager get fireflyConflicts =>
      $$FireflyConflictsTableTableManager(_db, _db.fireflyConflicts);
  $$FireflyResourceCacheTableTableManager get fireflyResourceCache =>
      $$FireflyResourceCacheTableTableManager(_db, _db.fireflyResourceCache);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TransactionTagsTableTableManager get transactionTags =>
      $$TransactionTagsTableTableManager(_db, _db.transactionTags);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$AccountDetailsTableTableManager get accountDetails =>
      $$AccountDetailsTableTableManager(_db, _db.accountDetails);
  $$BudgetLimitsTableTableManager get budgetLimits =>
      $$BudgetLimitsTableTableManager(_db, _db.budgetLimits);
}
