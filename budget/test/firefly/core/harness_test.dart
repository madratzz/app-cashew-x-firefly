import 'dart:convert';

import 'package:budget/firefly/api/transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_firefly_server.dart';
import '../../support/fake_firefly_transport.dart';

void main() {
  test('fake server serves JSON:API pagination and CRUD over loopback',
      () async {
    final transport = FakeFireflyTransport(maxPageSize: 1)
      ..seed('/categories', '10', {'name': 'First'})
      ..seed('/categories', '11', {'name': 'Second'});
    final server = await FakeFireflyServer.start(transport: transport);
    addTearDown(server.close);
    final categories = server.baseUrl.replace(path: '/api/v1/categories');
    final list = await http.get(categories.replace(queryParameters: {
      'page': '2',
      'limit': '100',
    }));
    expect(list.statusCode, 200);
    expect(
        list.headers['content-type'], startsWith('application/vnd.api+json'));
    final envelope = jsonDecode(list.body) as JsonObject;
    expect(
        (envelope['data'] as List<Object?>).single, containsPair('id', '11'));
    expect(envelope['meta'], {
      'pagination': {
        'total': 2,
        'count': 1,
        'per_page': 1,
        'current_page': 2,
        'total_pages': 2,
      },
    });

    final created = await http.post(categories, body: '{"name":"New"}');
    expect(created.statusCode, 201);
    final data = (jsonDecode(created.body) as JsonObject)['data'] as JsonObject;
    final resource =
        categories.replace(path: '${categories.path}/${data['id']}');
    expect((await http.put(resource, body: '{"name":"Renamed"}')).body,
        contains('Renamed'));
    expect((await http.get(resource)).body, contains('Renamed'));
    expect((await http.delete(resource)).statusCode, 204);
    expect((await http.get(resource)).statusCode, 404);

    final upload = server.baseUrl.replace(path: '/api/v1/attachments/1/upload');
    final download =
        server.baseUrl.replace(path: '/api/v1/attachments/1/download');
    expect((await http.post(upload, body: [1, 2, 3])).statusCode, 204);
    expect((await http.get(download)).bodyBytes, [1, 2, 3]);
  });
}
