import 'dart:async';
import 'dart:convert';

import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/resources/attachments_api.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _metadata = {
  'filename': 'receipt.pdf',
  'attachable_type': 'TransactionJournal',
  'attachable_id': '34',
};

void main() {
  for (final timeout in [false, true]) {
    test(
        'attachment metadata POST does not retry on ${timeout ? 'timeout' : '5xx'}',
        () async {
      var requests = 0;
      final lateResponse = Completer<http.Response>();
      final transport = HttpFireflyTransport(
        baseUrl: Uri.https('firefly.example'),
        readToken: () async => 'REDACTED',
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/attachments');
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), _metadata);
          requests++;
          if (timeout) return lateResponse.future;
          return http.Response('', 503);
        }),
        requestTimeout: const Duration(milliseconds: 20),
        delay: (_) async {},
      );
      addTearDown(transport.close);

      await expectLater(
        AttachmentsApi(transport).create(_metadata),
        throwsA(timeout ? isA<FireflyTimeout>() : isA<FireflyServerError>()),
      );
      expect(requests, 1);
      lateResponse.complete(http.Response('', 503));
    });
  }

  test('default POST retry still retries transient errors', () async {
    var attempts = 0;
    final transport = HttpFireflyTransport(
      baseUrl: Uri.https('firefly.example'),
      readToken: () async => 'REDACTED',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/categories');
        if (++attempts == 1) return http.Response('', 503);
        return http.Response('{"data":{"id":"1"}}', 201);
      }),
      delay: (_) async {},
    );
    addTearDown(transport.close);
    expect(await transport.post('/categories', {'name': 'Other'}), {'id': '1'});
    expect(attempts, 2);
  });
}
