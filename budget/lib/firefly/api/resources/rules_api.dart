import 'package:budget/firefly/api/models/rule.dart';
import 'package:budget/firefly/api/models/rule_group.dart';
import 'package:budget/firefly/api/models/transaction.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class RulesApi extends FireflyResourceApi<FireflyRule> {
  const RulesApi(super.transport);

  Future<FireflyPage<FireflyRuleGroup>> listGroups(
          {int page = 1, int limit = 100}) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyRuleGroup> getGroup(String id) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyRuleGroup> createGroup(JsonObject body) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyRuleGroup> updateGroup(String id, JsonObject body) async =>
      throw const FireflyTransportUnavailable();

  Future<void> deleteGroup(String id) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyPage<FireflyTransaction>> test(String id,
          {DateTime? start,
          DateTime? end,
          List<String> accounts = const []}) async =>
      throw const FireflyTransportUnavailable();

  Future<FireflyPage<FireflyTransaction>> testGroup(String id,
          {DateTime? start,
          DateTime? end,
          List<String> accounts = const []}) async =>
      throw const FireflyTransportUnavailable();

  Future<void> trigger(String id,
          {DateTime? start,
          DateTime? end,
          List<String> accounts = const []}) async =>
      throw const FireflyTransportUnavailable();

  Future<void> triggerGroup(String id,
          {DateTime? start,
          DateTime? end,
          List<String> accounts = const []}) async =>
      throw const FireflyTransportUnavailable();
}
