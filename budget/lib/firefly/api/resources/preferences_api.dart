import 'package:budget/firefly/api/models/preference.dart';
import 'package:budget/firefly/api/resources/resource_api.dart';
import 'package:budget/firefly/api/transport.dart';

class PreferencesApi extends FireflyResourceApi<FireflyPreference> {
  const PreferencesApi(super.transport);

  static const _path = '/preferences';

  String _item(String name) => '$_path/${Uri.encodeComponent(name)}';

  @override
  Future<FireflyPage<FireflyPreference>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      (await transport.getPage(_path, query: {
        ...query,
        'page': '$page',
        'limit': '$limit',
      }))
          .map(FireflyPreference.fromJson);

  /// Firefly routes preference lookups by name.
  @override
  Future<FireflyPreference> get(String name) async =>
      FireflyPreference.fromJson(await transport.get(_item(name)));

  @override
  Future<FireflyPreference> create(JsonObject body) async =>
      FireflyPreference.fromJson(await transport.post(_path, body));

  /// Send a body containing the preference's new `data` value.
  @override
  Future<FireflyPreference> update(String name, JsonObject body) async =>
      FireflyPreference.fromJson(await transport.put(_item(name), body));

  @override
  Future<void> delete(String id) async =>
      throw UnsupportedError('Firefly does not expose preference deletion');
}
