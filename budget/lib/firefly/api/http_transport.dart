import 'package:budget/firefly/api/transport.dart';
import 'package:http/http.dart' as http;

/// WP-03 implements HTTP. The foundation never sends requests.
class HttpFireflyTransport implements FireflyTransport {
  const HttpFireflyTransport({
    required this.baseUrl,
    required this.readToken,
    this.client,
  });

  final Uri baseUrl;
  final Future<String?> Function() readToken;
  final http.Client? client;

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async =>
      throw const FireflyTransportUnavailable();

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
          {FireflyQuery query = const {}}) async =>
      throw const FireflyTransportUnavailable();

  @override
  Future<JsonObject> post(String path, JsonObject body,
          {FireflyQuery query = const {}}) async =>
      throw const FireflyTransportUnavailable();

  @override
  Future<JsonObject> put(String path, JsonObject body,
          {FireflyQuery query = const {}}) async =>
      throw const FireflyTransportUnavailable();

  @override
  Future<void> delete(String path, {FireflyQuery query = const {}}) async =>
      throw const FireflyTransportUnavailable();

  @override
  Future<void> upload(String path, Stream<List<int>> bytes,
          {int? length}) async =>
      throw const FireflyTransportUnavailable();

  @override
  Future<Stream<List<int>>> download(String path) async =>
      throw const FireflyTransportUnavailable();

  void close() {}
}
