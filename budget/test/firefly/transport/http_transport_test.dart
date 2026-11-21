import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/struct/logging.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fake_firefly_server.dart';

const _allowHttp = bool.fromEnvironment('FIREFLY_ALLOW_HTTP');
const _fixture = 'REDACTED-fixture';

void main() {
  test('validates HTTPS URLs before requesting a token', () async {
    final requests = <Uri>[];
    var tokenReads = 0;
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response('{"data":{}}', 200);
    });
    final transport = HttpFireflyTransport(
      baseUrl: Uri.parse('https://firefly.example/my%20mount/api/v1/'),
      readToken: () async {
        tokenReads++;
        return _fixture;
      },
      client: client,
    );
    addTearDown(transport.close);
    for (final path in [
      'https://firefly.example/about',
      '//other.example/x',
      '/%2e%2e/about'
    ]) {
      await expectLater(transport.get(path), throwsFormatException);
    }
    for (final url in [
      'http://firefly.example',
      'http://localhost.example',
      'http://[::1]',
      'https://user@firefly.example',
      'https://firefly.example/?q=1',
    ]) {
      expect(
        () => HttpFireflyTransport(
          baseUrl: Uri.parse(url),
          readToken: transport.readToken,
          client: client,
        ),
        throwsFormatException,
      );
    }
    expect(tokenReads, 0);
    await transport.get('/tags/a%2Fb', query: {'search': 'a + b'});
    expect(requests.single.toString(),
        'https://firefly.example/my%20mount/api/v1/tags/a%2Fb?search=a+%2B+b');
    expect(tokenReads, 1);
  });

  for (final host in ['localhost', '127.0.0.1']) {
    test('enforces the debug loopback setting for $host', () async {
      final server = await FakeFireflyServer.start(intercept: (request) async {
        await _jsonResponse(request, {
          'data': {'version': '6.6.2'}
        });
        return true;
      });
      addTearDown(server.close);
      HttpFireflyTransport build() => HttpFireflyTransport(
            baseUrl: server.baseUrl.replace(host: host),
            readToken: () async => _fixture,
          );
      if (!_allowHttp) {
        expect(build, throwsFormatException);
      } else {
        final transport = build();
        addTearDown(transport.close);
        expect(await transport.get('/about'), {'version': '6.6.2'});
      }
    });
  }

  group('packaged HTTP client against the loopback server', () {
    test('decodes About, the current user, currency CRUD and actions',
        () async {
      final actions = <String>[];
      final headers = <Map<String, String?>>[];
      const currency = {
        'type': 'currencies',
        'id': '1',
        'attributes': {
          'code': 'USD',
          'name': 'Dollar •',
          'decimal_places': 2,
          'primary': true,
          'enabled': true,
        },
      };
      final transport = await _start((request) async {
        final endpoint = request.uri.path;
        headers.add({
          for (final name in ['accept', 'authorization', 'x-trace-id'])
            name: request.headers.value(name),
        });
        switch (endpoint) {
          case '/proxy/api/v1/about':
            await _jsonResponse(request, {
              'data': {'version': '6.6.2', 'api_version': '2.0.0'}
            });
          case '/proxy/api/v1/about/user':
            await _jsonResponse(request, {
              'data': {
                'type': 'users',
                'id': '31',
                'attributes': {'email': 'user@example.test'}
              }
            });
          case '/proxy/api/v1/currencies' when request.method == 'GET':
            expect(request.uri.queryParameters, {
              'enabled': 'true',
              'limit': '100',
              'page': '2',
            });
            await _jsonResponse(request, {
              'data': [currency],
              'meta': {
                'pagination': {
                  'total': 51,
                  'current_page': 2,
                  'per_page': 50,
                  'total_pages': 2,
                }
              },
            });
          default:
            actions.add('${request.method} $endpoint');
            if (request.method == 'POST' || request.method == 'PUT') {
              expect(request.headers.contentType?.mimeType, 'application/json');
              final body = jsonDecode(await utf8.decoder.bind(request).join());
              expect(
                  body,
                  endpoint.split('/').length == 7
                      ? <String, String>{}
                      : {'name': 'Dollar •'});
            }
            if (request.method == 'DELETE' || endpoint.split('/').length == 7) {
              request.response.statusCode = 204;
              await request.response.close();
            } else {
              await _jsonResponse(request, {'data': currency});
            }
        }
        return true;
      }, mount: '/proxy/api/v1/');
      final api = FireflyApi(transport);
      final about = await api.about.get();
      expect((about.version, about.apiVersion), ('6.6.2', '2.0.0'));
      final user = await api.about.getUser();
      expect((user.id, user.displayName), ('31', 'user@example.test'));
      final page =
          await api.currencies.list(page: 2, query: {'enabled': 'true'});
      expect((page.total, page.currentPage, page.perPage, page.totalPages),
          (51, 2, 50, 2));
      final item = page.items.single;
      expect((
        item.id,
        item.code,
        item.name,
        item.decimalPlaces,
        item.enabled,
        item.primary
      ), (
        '1',
        'USD',
        'Dollar •',
        2,
        true,
        true
      ));
      expect((await api.currencies.primary()).id, '1');
      expect((await api.currencies.get('usd')).id, '1');
      expect((await api.currencies.create({'name': 'Dollar •'})).id, '1');
      expect(
          (await api.currencies.update('usd', {'name': 'Dollar •'})).id, '1');
      await api.currencies.delete('usd');
      await api.currencies.enable('usd');
      await api.currencies.disable('usd');
      await api.currencies.setPrimary('usd');
      expect(actions, [
        'GET /proxy/api/v1/currencies/primary',
        'GET /proxy/api/v1/currencies/USD',
        'POST /proxy/api/v1/currencies',
        'PUT /proxy/api/v1/currencies/USD',
        'DELETE /proxy/api/v1/currencies/USD',
        'POST /proxy/api/v1/currencies/USD/enable',
        'POST /proxy/api/v1/currencies/USD/disable',
        'POST /proxy/api/v1/currencies/USD/primary',
      ]);
      final traces = <String>{};
      for (final request in headers) {
        expect(request['authorization'], 'Bearer $_fixture');
        expect(request['accept'], 'application/vnd.api+json');
        expect(
            request['x-trace-id'],
            matches(RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
        traces.add(request['x-trace-id']!);
      }
      expect(traces, hasLength(headers.length));
    });

    for (final (status, matcher) in [
      (401, isA<FireflyUnauthorized>()),
      (404, isA<FireflyNotFound>()),
      (422, isA<FireflyValidation>()),
      (400, isA<FireflyUnexpectedResponse>()),
      (
        429,
        isA<FireflyRateLimited>().having((error) => error.retryAfter,
            'retry after', const Duration(seconds: 3))
      ),
      (
        503,
        isA<FireflyServerError>()
            .having((error) => error.statusCode, 'status', 503)
      ),
    ]) {
      test('maps HTTP $status and only retries transient errors', () async {
        var requests = 0;
        final delays = <Duration>[];
        final transport = await _start((request) async {
          requests++;
          if (status == 429) request.response.headers.set('Retry-After', '3');
          await _jsonResponse(request, {'message': 'Rejected'}, status: status);
          return true;
        }, delay: (duration) async => delays.add(duration));
        await expectLater(transport.get('/about'), throwsA(matcher));
        expect(requests, status >= 429 ? 5 : 1);
        if (status == 429) {
          expect(delays, List.filled(4, const Duration(seconds: 3)));
        } else if (status == 503) {
          _expectBackoff(delays);
        } else {
          expect(delays, isEmpty);
        }
      });
    }

    test('recovers after a transient error and parses HTTP-date retry headers',
        () async {
      var requests = 0;
      final delays = <Duration>[];
      final transport = await _start((request) async {
        if (++requests == 1) {
          final retryAt =
              DateTime.now().toUtc().add(const Duration(seconds: 20));
          request.response.headers.set('Retry-After', HttpDate.format(retryAt));
          await _jsonResponse(request, {}, status: 429);
        } else {
          await _jsonResponse(request, {
            'data': {'version': '6.6.2'}
          });
        }
        return true;
      }, delay: (duration) async => delays.add(duration));
      expect(await transport.get('/about'), {'version': '6.6.2'});
      expect(requests, 2);
      expect(delays.single.inSeconds, inInclusiveRange(16, 20));
    });

    test('redacts echoed headers and validation details before log capture',
        () async {
      final echoed = <String>[];
      final transport = await _start((request) async {
        echoed.addAll([
          request.headers.value('authorization')!,
          request.headers.value('x-trace-id')!,
          request.headers.value('accept')!,
          request.headers.value('content-type')!,
        ]);
        await request.drain<void>();
        await _jsonResponse(
            request,
            {
              'message': 'Invalid name. Authorization: ${echoed.first}',
              'errors': {
                'name': [
                  'Rejected $_fixture',
                  'Echo ${echoed.skip(1).join(' ')}'
                ],
                'Bearer $_fixture': ['Bearer alternate-fixture'],
              },
            },
            status: 422);
        return true;
      });
      final previousSettings = appStateSettings;
      final previousLog = logService;
      appStateSettings = {'logging': true};
      logService = LogService();
      addTearDown(() {
        appStateSettings = previousSettings;
        logService = previousLog;
      });

      final done = Completer<void>();
      captureLogs(() async {
        try {
          await transport.post('/currencies', {'name': 'fixture payload'});
          done.completeError(StateError('Expected validation error'));
        } on FireflyValidation catch (error) {
          // Exercise the same log buffer even when a caller prints details.
          // ignore: avoid_print
          print(error.message);
          // ignore: avoid_print
          print(error.errors);
          done.complete();
        } catch (error, stack) {
          done.completeError(error, stack);
        }
      });
      await done.future;
      final log = logService.exportLogs();
      expect(log, contains('Invalid name'));
      expect(log, contains('Rejected REDACTED'));
      for (final value in [
        ...echoed,
        _fixture,
        'alternate-fixture',
        'fixture payload'
      ]) {
        expect(log, isNot(contains(value)));
      }
    });

    test('blocks redirects before forwarding credentials', () async {
      var forwarded = 0;
      final destination =
          await FakeFireflyServer.start(intercept: (request) async {
        forwarded++;
        await _jsonResponse(request, {'data': {}});
        return true;
      });
      addTearDown(destination.close);
      final transport = await _start((request) async {
        request.response.headers
            .set('Location', destination.baseUrl.toString());
        await _jsonResponse(request, {}, status: 302);
        return true;
      });
      await expectLater(
          transport.get('/about'),
          throwsA(isA<FireflyUnexpectedResponse>()
              .having((e) => e.statusCode, 'status', 302)));
      expect(forwarded, 0);
    });

    test('retries a server disconnect five times as a network error', () async {
      var requests = 0;
      final delays = <Duration>[];
      final transport = await _start((request) async {
        requests++;
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.destroy();
        return true;
      }, delay: (duration) async => delays.add(duration));
      await expectLater(
          transport.get('/about'), throwsA(isA<FireflyNetworkError>()));
      expect(requests, 5);
      _expectBackoff(delays);
    });

    test('bounds retries when the server stalls an in-flight JSON body',
        () async {
      var requests = 0;
      final delays = <Duration>[];
      final release = Completer<void>();
      final transport = await _start((request) async {
        requests++;
        request.response.bufferOutput = false;
        request.response.write('{"data":');
        await request.response.flush();
        await release.future;
        return true;
      },
          timeout: const Duration(milliseconds: 150),
          delay: (duration) async => delays.add(duration));
      addTearDown(release.complete);
      await expectLater(
          transport.get('/about'), throwsA(isA<FireflyTimeout>()));
      expect(requests, 5);
      _expectBackoff(delays);
    });

    test('keeps at most four concurrent GETs across JSON and downloads',
        () async {
      var started = 0;
      var active = 0;
      var maxActive = 0;
      final initialBatch = Completer<void>();
      final release = Completer<void>();
      final transport = await _start((request) async {
        maxActive = max(maxActive, ++active);
        if (++started == 4) initialBatch.complete();
        await release.future;
        active--;
        if (request.uri.path.endsWith('/download')) {
          request.response.add([42]);
          await request.response.close();
        } else {
          await _jsonResponse(request, {'data': {}});
        }
        return true;
      });
      final requests = Future.wait<Object?>([
        transport
            .download('/attachments/1/download')
            .then((bytes) => bytes.toList()),
        for (var i = 0; i < 7; i++) transport.get('/about'),
      ]);
      await initialBatch.future;
      release.complete();
      await requests;
      expect(started, 8);
      expect(maxActive, 4);
    });

    test('streams binary uploads and downloads before the source finishes',
        () async {
      final firstUpload = Completer<void>();
      final finishDownload = Completer<void>();
      final received = <int>[];
      final firstBlock = List.filled(128 * 1024, 255);
      final uploadBytes = [...firstBlock, 42, 1];
      final transport = await _start((request) async {
        if (request.method == 'POST') {
          expect(request.headers.contentType?.mimeType,
              'application/octet-stream');
          expect(request.headers.contentLength, uploadBytes.length);
          await for (final chunk in request) {
            received.addAll(chunk);
            if (!firstUpload.isCompleted) firstUpload.complete();
          }
          request.response.statusCode = 204;
        } else {
          expect(request.headers.value('accept'), 'application/octet-stream');
          request.response.bufferOutput = false;
          request.response.add([0, 255]);
          await request.response.flush();
          await finishDownload.future;
          request.response.add([42, 1]);
        }
        await request.response.close();
        return true;
      });
      Stream<List<int>> upload() async* {
        yield firstBlock;
        await firstUpload.future;
        yield [42, 1];
      }

      await transport.upload('/attachments/1/upload', upload(),
          length: uploadBytes.length);
      expect(received, uploadBytes);
      final bytes = await transport.download('/attachments/1/download');
      final downloaded = <int>[];
      await for (final chunk in bytes) {
        downloaded.addAll(chunk);
        if (!finishDownload.isCompleted) finishDownload.complete();
      }
      expect(downloaded, [0, 255, 42, 1]);
    });

    test('rejects malformed envelopes and pagination without a retry',
        () async {
      var requests = 0;
      final transport = await _start((request) async {
        requests++;
        await _jsonResponse(request, {
          'data': [],
          'meta': {
            'pagination': {'current_page': 1}
          }
        });
        return true;
      });
      await expectLater(
          transport.get('/about'), throwsA(isA<FireflyInvalidPayload>()));
      await expectLater(transport.getPage('/currencies'),
          throwsA(isA<FireflyInvalidPayload>()));
      expect(requests, 2);
    });
  },
      skip: !_allowHttp
          ? 'Requires --dart-define=FIREFLY_ALLOW_HTTP=true'
          : false);
}

Future<HttpFireflyTransport> _start(
  Future<bool> Function(HttpRequest) intercept, {
  String mount = '',
  Duration timeout = const Duration(seconds: 30),
  Future<void> Function(Duration)? delay,
}) async {
  final server = await FakeFireflyServer.start(intercept: intercept);
  addTearDown(server.close);
  final transport = HttpFireflyTransport(
    baseUrl: server.baseUrl.replace(path: mount),
    readToken: () async => _fixture,
    requestTimeout: timeout,
    delay: delay ?? (_) async {},
  );
  addTearDown(transport.close);
  return transport;
}

Future<void> _jsonResponse(HttpRequest request, JsonObject body,
    {int status = 200}) async {
  request.response.statusCode = status;
  request.response.headers.contentType =
      ContentType('application', 'vnd.api+json', charset: 'utf-8');
  request.response.add(utf8.encode(jsonEncode(body)));
  await request.response.close();
}

void _expectBackoff(List<Duration> delays) {
  expect(delays, hasLength(4));
  for (var i = 0; i < delays.length; i++) {
    final base = 250 << i;
    expect(delays[i].inMilliseconds, inInclusiveRange(base, base + base ~/ 2));
  }
}
