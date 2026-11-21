import 'dart:convert';
import 'dart:io';

import 'package:budget/firefly/api/transport.dart';

import 'fake_firefly_transport.dart';

/// Disposable IPv4 loopback HTTP fixture. No credential is needed to start it.
class FakeFireflyServer {
  FakeFireflyServer._(this._server, this.transport, this.intercept);

  static Future<FakeFireflyServer> start({
    FakeFireflyTransport? transport,
    Future<bool> Function(HttpRequest)? intercept,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeFireflyServer._(
        server, transport ?? FakeFireflyTransport(), intercept);
    server.listen(fake._handle);
    return fake;
  }

  final HttpServer _server;
  final FakeFireflyTransport transport;
  final Future<bool> Function(HttpRequest)? intercept;

  Uri get baseUrl => Uri(scheme: 'http', host: '127.0.0.1', port: _server.port);
  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    try {
      if (await intercept?.call(request) == true) return;
      final path = request.uri.path;
      final query = request.uri.queryParameters;
      final response = request.response;
      response.headers.contentType = ContentType('application', 'vnd.api+json');
      switch (request.method) {
        case 'GET':
          if (path.endsWith('/download')) {
            response.headers.contentType = ContentType.binary;
            await response.addStream(await transport.download(path));
          } else if (_isCollection(path, query)) {
            final page = await transport.getPage(path, query: query);
            response.write(jsonEncode({
              'data': page.items,
              'meta': {
                'pagination': {
                  'total': page.total,
                  'count': page.items.length,
                  'per_page': page.perPage,
                  'current_page': page.currentPage,
                  'total_pages': page.totalPages,
                },
              },
            }));
          } else {
            response.write(
                jsonEncode({'data': await transport.get(path, query: query)}));
          }
        case 'POST':
          if (path.endsWith('/upload')) {
            await transport.upload(path, request);
            response.statusCode = HttpStatus.noContent;
          } else {
            final item =
                await transport.post(path, await _read(request), query: query);
            response.statusCode = HttpStatus.created;
            response.write(jsonEncode({'data': item}));
          }
        case 'PUT':
          final item =
              await transport.put(path, await _read(request), query: query);
          response.write(jsonEncode({'data': item}));
        case 'DELETE':
          await transport.delete(path, query: query);
          response.statusCode = HttpStatus.noContent;
        default:
          response.statusCode = HttpStatus.methodNotAllowed;
      }
    } on FireflyException catch (error) {
      final response = request.response;
      response.headers.contentType = ContentType.json;
      response.statusCode = switch (error) {
        FireflyUnauthorized() => HttpStatus.unauthorized,
        FireflyNotFound() => HttpStatus.notFound,
        FireflyValidation() => HttpStatus.unprocessableEntity,
        FireflyRateLimited() => HttpStatus.tooManyRequests,
        FireflyServerError(:final statusCode) => statusCode,
        FireflyUnexpectedResponse(:final statusCode) => statusCode,
        _ => HttpStatus.internalServerError,
      };
      response.write(jsonEncode({
        'message':
            error is FireflyValidation ? error.message : error.description,
        if (error is FireflyValidation) 'errors': error.errors,
      }));
    } on FormatException {
      request.response.statusCode = HttpStatus.badRequest;
    } finally {
      await request.response.close();
    }
  }

  bool _isCollection(String path, FireflyQuery query) {
    final segments = Uri.parse(path).pathSegments;
    if (segments.contains('about')) return false;
    return segments.length == 3 ||
        query.containsKey('page') ||
        query.containsKey('limit');
  }

  Future<JsonObject> _read(HttpRequest request) async {
    final input = jsonDecode(await utf8.decoder.bind(request).join());
    if (input is! JsonObject) throw const FormatException('Expected an object');
    return input;
  }
}
