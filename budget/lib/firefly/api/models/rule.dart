import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

class FireflyRule extends FireflyResource {
  const FireflyRule({required super.id, super.attributes});

  factory FireflyRule.fromJson(JsonObject json) {
    final id = json['id'];
    final attributes = json['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    final rule = FireflyRule(id: id, attributes: attributes);
    // Check nested shapes before a response can replace the offline cache.
    rule.triggers;
    rule.actions;
    return rule;
  }

  // Firefly III 6.6.2 OpenAPI RuleTriggerType, RuleTriggerKeyword and
  // RuleActionKeyword. Additional server keywords are preserved when decoding.
  static const triggerTypes = [
    'store-journal',
    'update-journal',
    'manual-activation',
  ];

  static const triggerKeywords = [
    'from_account_starts',
    'from_account_ends',
    'from_account_is',
    'from_account_contains',
    'to_account_starts',
    'to_account_ends',
    'to_account_is',
    'to_account_contains',
    'amount_less',
    'amount_exactly',
    'amount_more',
    'description_starts',
    'description_ends',
    'description_contains',
    'description_is',
    'transaction_type',
    'category_is',
    'budget_is',
    'tag_is',
    'currency_is',
    'has_attachments',
    'has_no_category',
    'has_any_category',
    'has_no_budget',
    'has_any_budget',
    'has_no_tag',
    'has_any_tag',
    'notes_contains',
    'notes_starts',
    'notes_end',
    'notes_are',
    'no_notes',
    'any_notes',
    'source_account_is',
    'destination_account_is',
    'source_account_starts',
  ];

  static const actionKeywords = [
    'user_action',
    'set_category',
    'clear_category',
    'set_budget',
    'clear_budget',
    'add_tag',
    'remove_tag',
    'remove_all_tags',
    'set_description',
    'append_description',
    'prepend_description',
    'set_source_account',
    'set_destination_account',
    'set_notes',
    'append_notes',
    'prepend_notes',
    'clear_notes',
    'link_to_bill',
    'convert_withdrawal',
    'convert_deposit',
    'convert_transfer',
    'delete_transaction',
  ];

  String? get title => attributes['title'] as String?;
  String? get description => attributes['description'] as String?;
  String? get ruleGroupId => attributes['rule_group_id']?.toString();
  String? get ruleGroupTitle => attributes['rule_group_title'] as String?;
  int? get order => attributes['order'] as int?;
  String? get trigger => attributes['trigger'] as String?;
  bool? get active => attributes['active'] as bool?;
  bool? get strict => attributes['strict'] as bool?;
  bool? get stopProcessing => attributes['stop_processing'] as bool?;
  List<JsonObject> get triggers => _clauses(attributes['triggers']);
  List<JsonObject> get actions => _clauses(attributes['actions']);

  JsonObject toWriteJson({bool updating = false}) => {
        for (final key in const [
          'title',
          'description',
          'rule_group_id',
          'order',
          'trigger',
          'active',
          'strict',
          'stop_processing',
        ])
          if (attributes.containsKey(key)) key: attributes[key],
        if (!updating && attributes.containsKey('rule_group_title'))
          'rule_group_title': ruleGroupTitle,
        if (attributes.containsKey('triggers'))
          'triggers': [
            for (final clause in triggers) _writeClause(clause, trigger: true),
          ],
        if (attributes.containsKey('actions'))
          'actions': [
            for (final clause in actions) _writeClause(clause, trigger: false),
          ],
      };

  static List<JsonObject> _clauses(Object? value) {
    if (value == null) return const [];
    if (value is! List<Object?>) throw const FireflyInvalidPayload();
    return [
      for (final clause in value)
        if (clause is JsonObject && clause['type'] is String)
          clause
        else
          throw const FireflyInvalidPayload(),
    ];
  }

  // Firefly assigns clause order from array position. Its update handler
  // defaults omitted action activity to false, so send the editor default.
  static JsonObject _writeClause(JsonObject clause, {required bool trigger}) =>
      {
        'type': clause['type'],
        'value': clause['value'],
        'active': clause['active'] ?? true,
        if (clause.containsKey('stop_processing'))
          'stop_processing': clause['stop_processing'],
        if (trigger && clause.containsKey('prohibited'))
          'prohibited': clause['prohibited'],
      };
}
