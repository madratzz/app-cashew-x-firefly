import 'package:budget/firefly/api/models/resource.dart';
import 'package:budget/firefly/api/transport.dart';

/// Shared method signatures for resource clients. Each owner supplies its own
/// endpoint and encoding; these defaults deliberately perform no I/O.
abstract class FireflyResourceApi<T extends FireflyResource> {
  const FireflyResourceApi(this.transport);

  final FireflyTransport transport;

  Future<FireflyPage<T>> list({
    int page = 1,
    int limit = 100,
    FireflyQuery query = const {},
  }) async =>
      throw const FireflyTransportUnavailable();

  Future<T> get(String id) async => throw const FireflyTransportUnavailable();
  Future<T> create(JsonObject body) async =>
      throw const FireflyTransportUnavailable();
  Future<T> update(String id, JsonObject body) async =>
      throw const FireflyTransportUnavailable();
  Future<void> delete(String id) async =>
      throw const FireflyTransportUnavailable();
}
