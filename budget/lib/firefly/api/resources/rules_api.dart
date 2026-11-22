import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/models/rule.dart';
import 'package:budget/firefly/api/models/rule_group.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class RulesApi extends FireflyResourceApi<FireflyRule> {
  const RulesApi(super.transport);

  static const _rules = '/rules';
  static const _groups = '/rule-groups';

  @override
  Future<FireflyPage<FireflyRule>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_rules, query: {
        ...query,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyRule.fromJson);

  @override
  Future<FireflyRule> get(String id) async =>
      FireflyRule.fromJson(await transport.get(_item(_rules, id)));

  @override
  Future<FireflyRule> create(JsonObject body) async => FireflyRule.fromJson(
      await _post(_rules, FireflyRule(id: '', attributes: body).toWriteJson()));

  @override
  Future<FireflyRule> update(String id, JsonObject body) async =>
      FireflyRule.fromJson(await transport.put(_item(_rules, id),
          FireflyRule(id: id, attributes: body).toWriteJson(updating: true)));

  @override
  Future<void> delete(String id) => transport.delete(_item(_rules, id));

  Future<FireflyPage<FireflyRuleGroup>> listGroups({
    int page = 1,
    int limit = 100,
  }) async =>
      (await transport.getPage(_groups, query: {
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyRuleGroup.fromJson);

  Future<FireflyRuleGroup> getGroup(String id) async =>
      FireflyRuleGroup.fromJson(await transport.get(_item(_groups, id)));

  Future<FireflyRuleGroup> createGroup(JsonObject body) async =>
      FireflyRuleGroup.fromJson(await _post(
          _groups, FireflyRuleGroup(id: '', attributes: body).toWriteJson()));

  Future<FireflyRuleGroup> updateGroup(String id, JsonObject body) async =>
      FireflyRuleGroup.fromJson(await transport.put(_item(_groups, id),
          FireflyRuleGroup(id: id, attributes: body).toWriteJson()));

  Future<void> deleteGroup(String id) => transport.delete(_item(_groups, id));

  Future<FireflyPage<FireflyTransaction>> test(
    String id, {
    DateTime? start,
    DateTime? end,
    List<String> accounts = const [],
    int page = 1,
    int limit = 100,
  }) =>
      _test(_item(_rules, id), start, end, accounts, page, limit);

  Future<FireflyPage<FireflyTransaction>> testGroup(
    String id, {
    DateTime? start,
    DateTime? end,
    List<String> accounts = const [],
    int page = 1,
    int limit = 100,
  }) =>
      _test(_item(_groups, id), start, end, accounts, page, limit);

  Future<void> trigger(
    String id, {
    DateTime? start,
    DateTime? end,
    List<String> accounts = const [],
  }) async {
    await _post('${_item(_rules, id)}/trigger', const {},
        query: _filters(start, end, accounts));
  }

  Future<void> triggerGroup(
    String id, {
    DateTime? start,
    DateTime? end,
    List<String> accounts = const [],
  }) async {
    await _post('${_item(_groups, id)}/trigger', const {},
        query: _filters(start, end, accounts));
  }

  Future<FireflyPage<FireflyTransaction>> _test(
    String item,
    DateTime? start,
    DateTime? end,
    List<String> accounts,
    int page,
    int limit,
  ) async =>
      (await transport.getPage('$item/test', query: {
        ..._filters(start, end, accounts),
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyTransaction.fromJson);

  Future<JsonObject> _post(String path, JsonObject body,
      {FireflyQuery query = const {}}) {
    final client = transport;
    // A timed-out creation or run may already have taken effect.
    return client is HttpFireflyTransport
        ? client.post(path, body, query: query, retry: false)
        : client.post(path, body, query: query);
  }

  static String _item(String path, String id) =>
      '$path/${Uri.encodeComponent(id)}';

  static FireflyQuery _filters(
      DateTime? start, DateTime? end, List<String> accounts) {
    // Indexed PHP array keys preserve every account in FireflyQuery.
    return {
      if (start != null) 'start': formatFireflyDate(start),
      if (end != null) 'end': formatFireflyDate(end),
      for (var i = 0; i < accounts.length; i++) 'accounts[$i]': accounts[i],
    };
  }
}
