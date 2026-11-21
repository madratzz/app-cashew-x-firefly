import 'dart:math';

import 'package:budget/firefly/api/transport.dart';

import 'fixtures.dart';

typedef FakeFireflyRequest = ({
  String method,
  String path,
  FireflyQuery query,
  JsonObject? body,
});

/// In-memory Firefly resources and a request log. Inject errors with onRequest.
class FakeFireflyTransport implements FireflyTransport {
  FakeFireflyTransport({this.maxPageSize = 50});

  final int maxPageSize;
  void Function(FakeFireflyRequest)? onRequest;
  final requests = <FakeFireflyRequest>[];
  final _collections = <String, Map<String, JsonObject>>{};
  final _files = <String, List<int>>{};
  var _nextId = 1;

  void seed(String path, String id, JsonObject attributes) {
    _collection(_path(path))[id] = Map.of(attributes);
  }

  void removeSeed(String path, String id) {
    _collection(_path(path)).remove(id);
  }

  Map<String, JsonObject> _collection(String path) =>
      _collections.putIfAbsent(path, () => {});

  String _path(String raw) {
    var path = raw.startsWith('/') ? raw : '/$raw';
    if (path.startsWith('/api/v1/')) path = path.substring('/api/v1'.length);
    return path.replaceFirst(RegExp(r'/+$'), '');
  }

  ({String collection, String id}) _item(String path) {
    final slash = path.lastIndexOf('/');
    if (slash <= 0 || slash == path.length - 1) throw const FireflyNotFound();
    return (
      collection: path.substring(0, slash),
      id: path.substring(slash + 1)
    );
  }

  JsonObject _resource(String path, String id, JsonObject attributes) =>
      fireflyResource(path.split('/').last, id, Map.of(attributes));

  String _record(String method, String raw,
      {FireflyQuery query = const {}, JsonObject? body}) {
    final path = _path(raw);
    final request =
        (method: method, path: path, query: Map.of(query), body: body);
    requests.add(request);
    onRequest?.call(request);
    return path;
  }

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async {
    final normalized = _record('GET', path, query: query);
    if (normalized == '/about') {
      return {'version': '6.6.2', 'api_version': '2.0.0'};
    }
    if (normalized == '/about/user') {
      return fireflyResource('users', '1', const {});
    }
    final item = _item(normalized);
    final attributes = _collection(item.collection)[item.id];
    if (attributes == null) throw const FireflyNotFound();
    return _resource(item.collection, item.id, attributes);
  }

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}}) async {
    final normalized = _record('GET', path, query: query);
    final type = query['type'];
    final collection = _collection(normalized)
        .entries
        .where((entry) =>
            type == null || type == 'all' || entry.value['type'] == type)
        .toList();
    final perPage = min(maxPageSize, int.tryParse(query['limit'] ?? '') ?? 50);
    final page = int.tryParse(query['page'] ?? '') ?? 1;
    if (perPage < 1 || page < 1) throw const FireflyValidation('Invalid page');
    final total = collection.length;
    final first = min(total, (page - 1) * perPage);
    return FireflyPage(
      items: [
        for (final item in collection.skip(first).take(perPage))
          _resource(normalized, item.key, item.value),
      ],
      total: total,
      currentPage: page,
      perPage: perPage,
      totalPages: max(1, (total + perPage - 1) ~/ perPage),
    );
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final normalized = _record('POST', path, query: query, body: body);
    final collection = _collection(normalized);
    while (collection.containsKey('$_nextId')) {
      _nextId++;
    }
    final id = '${_nextId++}';
    final attributes = {...body, 'updated_at': fixtureTime.toIso8601String()};
    collection[id] = attributes;
    return _resource(normalized, id, attributes);
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final item = _item(_record('PUT', path, query: query, body: body));
    final collection = _collection(item.collection);
    final previous = collection[item.id];
    if (previous == null) throw const FireflyNotFound();
    final updatedAt = previous['updated_at'];
    final previousTime =
        updatedAt is String ? DateTime.tryParse(updatedAt) : null;
    final attributes = {
      ...previous,
      ...body,
      'updated_at': (previousTime ?? fixtureTime)
          .add(const Duration(seconds: 1))
          .toIso8601String(),
    };
    collection[item.id] = attributes;
    return _resource(item.collection, item.id, attributes);
  }

  @override
  Future<void> delete(String path, {FireflyQuery query = const {}}) async {
    final item = _item(_record('DELETE', path, query: query));
    if (_collection(item.collection).remove(item.id) == null) {
      throw const FireflyNotFound();
    }
  }

  @override
  Future<void> upload(String path, Stream<List<int>> bytes,
      {int? length}) async {
    final normalized = _record('UPLOAD', path);
    final file = await bytes.expand((chunk) => chunk).toList();
    if (length != null && file.length != length) {
      throw const FireflyValidation('Incorrect length');
    }
    _files[normalized.replaceFirst(RegExp(r'/upload$'), '')] = file;
  }

  @override
  Future<Stream<List<int>>> download(String path) async {
    final normalized = _record('DOWNLOAD', path);
    final file = _files[normalized.replaceFirst(RegExp(r'/download$'), '')];
    if (file == null) throw const FireflyNotFound();
    return Stream.value(List.of(file));
  }
}
