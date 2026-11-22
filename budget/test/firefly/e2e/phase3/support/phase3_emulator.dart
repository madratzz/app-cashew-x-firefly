import 'package:budget/firefly/api/transport.dart';
import 'package:crypto/crypto.dart';

import '../../phase2/support/phase2_emulator.dart';
import '../../support/e2e_harness.dart';

/// The Phase 2 emulator plus the read shapes Phase 3 relies on: liabilities
/// are listed and read back as `liabilities`, and an attachment
/// upload stamps the stored file's md5 hash and size.
class Phase3Emulator extends Phase2Emulator {
  Phase3Emulator({super.clock});

  static Future<E2eTarget> target(DateTime Function() clock) =>
      E2eTarget.fake(clock, emulator: (clock) => Phase3Emulator(clock: clock));

  static String _normalize(String raw) {
    var path = raw.startsWith('/') ? raw : '/$raw';
    if (path.startsWith('/api/v1/')) path = path.substring('/api/v1'.length);
    return path.replaceFirst(RegExp(r'/+$'), '');
  }

  static JsonObject _liabilityShape(JsonObject resource) {
    final attributes = resource['attributes'];
    if (attributes is! JsonObject || attributes['type'] != 'liability') {
      return resource;
    }
    return {
      ...resource,
      'attributes': {...attributes, 'type': 'liabilities'},
    };
  }

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async {
    final item = await super.get(path, query: query);
    return _normalize(path).startsWith('/accounts/')
        ? _liabilityShape(item)
        : item;
  }

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}}) async {
    final normalized = _normalize(path);
    if (normalized == '/accounts' && query['type'] == 'liabilities') {
      query = {...query, 'type': 'liability'};
    }
    final page = await super.getPage(path, query: query);
    return normalized == '/accounts' ? page.map(_liabilityShape) : page;
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final normalized = _normalize(path);
    if (normalized == '/accounts' && body['type'] == 'liabilities') {
      body = {...body, 'type': 'liability'};
    }
    final created = await super.post(path, body, query: query);
    return normalized == '/accounts' ? _liabilityShape(created) : created;
  }

  @override
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}}) async {
    final updated = await super.put(path, body, query: query);
    return _normalize(path).startsWith('/accounts/')
        ? _liabilityShape(updated)
        : updated;
  }

  @override
  Future<void> upload(String path, Stream<List<int>> bytes,
      {int? length}) async {
    final file = await bytes.expand((chunk) => chunk).toList();
    await super.upload(path, Stream.value(file), length: length);
    final item = _normalize(path).replaceFirst(RegExp(r'/upload$'), '');
    final attributes = (await super.get(item))['attributes']! as JsonObject;
    seed('/attachments', item.split('/').last, {
      ...attributes,
      'hash': md5.convert(file).toString(),
      'size': file.length,
    });
  }
}
