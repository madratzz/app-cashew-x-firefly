import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/config/log_redaction.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class HttpFireflyTransport implements FireflyTransport {
  HttpFireflyTransport({
    required Uri baseUrl,
    required this.readToken,
    this.client,
    Duration requestTimeout = const Duration(seconds: 30),
    Future<void> Function(Duration)? delay,
  })  : baseUrl = normalizeFireflyUrl(baseUrl.toString()),
        _requestTimeout = requestTimeout,
        _delay = delay ?? Future<void>.delayed;

  final Uri baseUrl;
  final Future<String?> Function() readToken;
  final http.Client? client;
  final Duration _requestTimeout;
  final Future<void> Function(Duration) _delay;

  static const _jsonApi = 'application/vnd.api+json';
  static const _json = 'application/json';
  static const _binary = 'application/octet-stream';
  static const _maxAttempts = 5;
  static const _maxGets = 4;

  final _getQueue = Queue<Completer<void>>();
  final _activeClients = <http.Client>{};
  int _activeGets = 0;
  bool _closed = false;

  @override
  Future<JsonObject> get(String path, {FireflyQuery query = const {}}) async =>
      _object((await _requestJson('GET', path, query))['data']);

  @override
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}}) async {
    final envelope = await _requestJson('GET', path, query);
    final items = envelope['data'];
    if (items is! List<Object?>) throw const FireflyInvalidPayload();
    final meta = _object(envelope['meta']);
    final pagination = _object(meta['pagination']);
    return FireflyPage(
      items: items.map(_object).toList(),
      total: _pageNumber(pagination['total'], min: 0),
      currentPage: _pageNumber(pagination['current_page'], min: 1),
      perPage: _pageNumber(pagination['per_page'], min: 1),
      totalPages: _pageNumber(pagination['total_pages'], min: 0),
    );
  }

  @override
  Future<JsonObject> post(String path, JsonObject body,
          {FireflyQuery query = const {}}) async =>
      _object((await _requestJson('POST', path, query, body: body))['data']);

  @override
  Future<JsonObject> put(String path, JsonObject body,
          {FireflyQuery query = const {}}) async =>
      _object((await _requestJson('PUT', path, query, body: body))['data']);

  @override
  Future<void> delete(String path, {FireflyQuery query = const {}}) async {
    final uri = _uri(path, query);
    await _retry(() => _exchange(http.Request('DELETE', uri), _discard));
  }

  @override
  Future<void> upload(String path, Stream<List<int>> bytes, {int? length}) {
    final request = _UploadRequest(_uri(path, const {}), bytes)
      ..contentLength = length
      ..headers['Content-Type'] = _binary;
    // The caller supplies a single-subscription stream. The next sync cycle
    // can reopen it if the upload fails.
    return _exchange(request, _discard);
  }

  @override
  Future<Stream<List<int>>> download(String path) async {
    final uri = _uri(path, const {});
    await _acquireGet();
    try {
      return await _retry(() async {
        final token = await _token();
        final attempt = _openClient();
        try {
          final request = http.Request('GET', uri);
          final response = await _network(
            () => _send(attempt, request, token, accept: _binary),
          ).timeout(_requestTimeout, onTimeout: _timedOut);
          return _downloadStream(response.stream, attempt);
        } catch (_) {
          _closeClient(attempt);
          rethrow;
        }
      });
    } catch (_) {
      _releaseGet();
      rethrow;
    }
  }

  Stream<List<int>> _downloadStream(
      Stream<List<int>> bytes, http.Client attempt) {
    var expired = false;
    void finish() {
      _closeClient(attempt);
      _releaseGet();
    }

    final startTimer = Timer(_requestTimeout, () {
      expired = true;
      finish();
    });

    Stream<List<int>> read() async* {
      if (expired) throw const FireflyTimeout();
      startTimer.cancel();
      try {
        yield* bytes.timeout(_requestTimeout, onTimeout: (sink) {
          sink.addError(const FireflyTimeout());
          sink.close();
        }).handleError((Object error) {
          if (error is FireflyException) throw error;
          throw const FireflyNetworkError();
        });
      } finally {
        finish();
      }
    }

    return read();
  }

  Future<JsonObject> _requestJson(
      String method, String path, FireflyQuery query,
      {JsonObject? body}) async {
    final uri = _uri(path, query);
    final isGet = method == 'GET';
    final bytes = body == null ? null : utf8.encode(jsonEncode(body));
    if (isGet) await _acquireGet();
    try {
      return await _retry(() {
        final request = http.Request(method, uri);
        if (bytes != null) {
          request.headers['Content-Type'] = _json;
          request.bodyBytes = bytes;
        }
        return _exchange(request, (response) async {
          if (response.statusCode == 204 && !isGet) {
            return {'data': <String, Object?>{}};
          }
          return _object(_decode(await response.stream.toBytes()));
        });
      });
    } finally {
      if (isGet) _releaseGet();
    }
  }

  Future<T> _exchange<T>(
    http.BaseRequest request,
    Future<T> Function(http.StreamedResponse) read,
  ) async {
    final token = await _token();
    final attempt = _openClient();
    try {
      return await _network(() async {
        final response = await _send(attempt, request, token);
        return read(response);
      }).timeout(_requestTimeout, onTimeout: _timedOut);
    } finally {
      _closeClient(attempt);
    }
  }

  Future<String> _token() async {
    if (_closed) throw const FireflyTransportUnavailable();
    final token = await _network(readToken)
        .timeout(_requestTimeout, onTimeout: _timedOut);
    if (token == null || token.trim().isEmpty) {
      throw const FireflyUnauthorized();
    }
    return token;
  }

  Future<http.StreamedResponse> _send(
    http.Client attempt,
    http.BaseRequest request,
    String token, {
    String accept = _jsonApi,
  }) async {
    request.followRedirects = false;
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'X-Trace-Id': const Uuid().v4(),
      'Accept': accept,
    });
    final response = await attempt.send(request);
    final status = response.statusCode;
    if (status >= 200 && status < 300) return response;
    switch (status) {
      case 401:
        throw const FireflyUnauthorized();
      case 404:
        throw const FireflyNotFound();
      case 422:
        final bytes = await response.stream.toBytes();
        throw _validation(bytes, token, request.headers.values);
      case 429:
        throw FireflyRateLimited(
            retryAfter: _retryAfter(response.headers['retry-after']));
      default:
        if (status >= 500 && status < 600) throw FireflyServerError(status);
        throw FireflyUnexpectedResponse(status);
    }
  }

  Future<T> _retry<T>(Future<T> Function() run) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await run();
      } on FireflyException catch (error) {
        if (attempt == _maxAttempts - 1 ||
            (error is! FireflyRateLimited &&
                error is! FireflyServerError &&
                error is! FireflyNetworkError &&
                error is! FireflyTimeout)) {
          rethrow;
        }
        final base = 250 << attempt;
        final jitter = _random.nextInt(base ~/ 2 + 1);
        final backoff = Duration(milliseconds: base + jitter);
        final retryAfter =
            error is FireflyRateLimited ? error.retryAfter : null;
        await _delay(
            retryAfter != null && retryAfter > backoff ? retryAfter : backoff);
      }
    }
  }

  Future<void> _acquireGet() async {
    if (_closed) throw const FireflyTransportUnavailable();
    if (_activeGets < _maxGets) {
      _activeGets++;
      return;
    }
    final ready = Completer<void>();
    _getQueue.addLast(ready);
    await ready.future;
  }

  void _releaseGet() {
    if (_getQueue.isEmpty) {
      _activeGets--;
    } else {
      _getQueue.removeFirst().complete();
    }
  }

  http.Client _openClient() {
    if (_closed) throw const FireflyTransportUnavailable();
    final injected = client;
    if (injected != null) return injected;
    // This version of package:http aborts requests by closing the client.
    // A separate client lets a timeout leave other requests running.
    final attempt = http.Client();
    _activeClients.add(attempt);
    return attempt;
  }

  void _closeClient(http.Client attempt) {
    if (_activeClients.remove(attempt)) attempt.close();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    while (_getQueue.isNotEmpty) {
      _getQueue
          .removeFirst()
          .completeError(const FireflyTransportUnavailable());
    }
    for (final attempt in _activeClients) {
      attempt.close();
    }
    _activeClients.clear();
    client?.close();
  }

  Uri _uri(String path, FireflyQuery query) {
    if (!path.startsWith('/') ||
        path.startsWith('//') ||
        RegExp(r'[\\?#]').hasMatch(path)) {
      throw const FormatException('Invalid Firefly API path');
    }
    final segments = path.substring(1).split('/').map(Uri.decodeComponent);
    if (segments.any((part) => part == '.' || part == '..' || part.isEmpty)) {
      throw const FormatException('Invalid Firefly API path');
    }
    return baseUrl.replace(
      pathSegments: [...baseUrl.pathSegments, 'api', 'v1', ...segments],
      queryParameters: query.isEmpty ? null : query,
    );
  }
}

class _UploadRequest extends http.BaseRequest {
  _UploadRequest(Uri url, this.bytes) : super('POST', url);

  final Stream<List<int>> bytes;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(bytes);
  }
}

final _random = Random();

Future<void> _discard(http.StreamedResponse response) =>
    response.stream.drain<void>();

Never _timedOut() => throw const FireflyTimeout();

Future<T> _network<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on FireflyException {
    rethrow;
  } catch (_) {
    throw const FireflyNetworkError();
  }
}

Object? _decode(List<int> bytes) {
  try {
    return jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw const FireflyInvalidPayload();
  }
}

JsonObject _object(Object? value) {
  if (value is JsonObject) return value;
  throw const FireflyInvalidPayload();
}

int _pageNumber(Object? value, {required int min}) {
  if (value is int && value >= min) return value;
  throw const FireflyInvalidPayload();
}

FireflyValidation _validation(
    List<int> bytes, String token, Iterable<String> headers) {
  const fallback = 'Validation failed';
  final JsonObject payload;
  try {
    payload = _object(_decode(bytes));
  } on FireflyInvalidPayload {
    return const FireflyValidation(fallback);
  }

  String redact(String value) {
    for (final header in headers) {
      value = value.replaceAll(header, 'REDACTED');
    }
    return redactFireflyLog(value, token: token);
  }

  final message = payload['message'];
  final errors = payload['errors'];
  return FireflyValidation(
    message is String ? redact(message) : fallback,
    errors: {
      if (errors is JsonObject)
        for (final entry in errors.entries)
          if (entry.value is List<Object?>)
            redact(entry.key): (entry.value as List<Object?>)
                .whereType<String>()
                .map(redact)
                .toList(),
    },
  );
}

Duration? _retryAfter(String? header) {
  if (header == null) return null;
  final seconds = int.tryParse(header);
  if (seconds != null && seconds >= 0 && seconds < 8640000000000) {
    return Duration(seconds: seconds);
  }
  try {
    final date = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
        .parseStrict(header, true);
    final wait = date.difference(DateTime.now());
    return wait.isNegative ? Duration.zero : wait;
  } on FormatException {
    return null;
  }
}
