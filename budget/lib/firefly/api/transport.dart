typedef JsonObject = Map<String, Object?>;
typedef FireflyQuery = Map<String, String>;

abstract interface class FireflyTransport {
  Future<JsonObject> get(String path, {FireflyQuery query = const {}});
  Future<FireflyPage<JsonObject>> getPage(String path,
      {FireflyQuery query = const {}});
  Future<JsonObject> post(String path, JsonObject body,
      {FireflyQuery query = const {}});
  Future<JsonObject> put(String path, JsonObject body,
      {FireflyQuery query = const {}});
  Future<void> delete(String path, {FireflyQuery query = const {}});
  Future<void> upload(String path, Stream<List<int>> bytes, {int? length});
  Future<Stream<List<int>>> download(String path);
}

class FireflyPage<T> {
  const FireflyPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.perPage,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int currentPage;
  final int perPage;
  final int totalPages;

  FireflyPage<R> map<R>(R Function(T) convert) => FireflyPage(
        items: items.map(convert).toList(),
        total: total,
        currentPage: currentPage,
        perPage: perPage,
        totalPages: totalPages,
      );
}

sealed class FireflyException implements Exception {
  const FireflyException(this.description);
  final String description;

  @override
  String toString() => '$runtimeType: $description';
}

final class FireflyUnauthorized extends FireflyException {
  const FireflyUnauthorized() : super('Authentication failed');
}

final class FireflyNotFound extends FireflyException {
  const FireflyNotFound() : super('Resource not found');
}

final class FireflyValidation extends FireflyException {
  const FireflyValidation(this.message, {this.errors = const {}})
      : super('Validation failed');

  final String message;
  final Map<String, List<String>> errors;
}

final class FireflyRateLimited extends FireflyException {
  const FireflyRateLimited({this.retryAfter}) : super('Rate limit reached');
  final Duration? retryAfter;
}

final class FireflyServerError extends FireflyException {
  const FireflyServerError(this.statusCode) : super('Server error');
  final int statusCode;
}

final class FireflyNetworkError extends FireflyException {
  const FireflyNetworkError() : super('Network request failed');
}

final class FireflyTimeout extends FireflyException {
  const FireflyTimeout() : super('Network request timed out');
}

final class FireflyUnexpectedResponse extends FireflyException {
  const FireflyUnexpectedResponse(this.statusCode)
      : super('Unexpected HTTP response');
  final int statusCode;
}

final class FireflyInvalidPayload extends FireflyException {
  const FireflyInvalidPayload() : super('Invalid Firefly response');
}

final class FireflyTransportUnavailable extends FireflyException {
  const FireflyTransportUnavailable()
      : super('Firefly transport is unavailable');
}

/// Writes a non-negative plain decimal for a Firefly amount field.
String formatFireflyAmount(double amount, int decimalPlaces) {
  RangeError.checkValueInInterval(decimalPlaces, 0, 20, 'decimalPlaces');
  if (!amount.isFinite) throw ArgumentError('Amount must be finite');
  final value = amount.abs();
  if (value < 1e21) return value.toStringAsFixed(decimalPlaces);

  // toStringAsFixed uses exponential notation from 1e21 onwards.
  final exponential = value.toStringAsExponential().split('e');
  final digits = exponential.first.replaceAll('.', '');
  final integer = digits.padRight(int.parse(exponential.last) + 1, '0');
  return decimalPlaces == 0
      ? integer
      : '$integer.${''.padRight(decimalPlaces, '0')}';
}

double parseFireflyAmount(String amount) {
  final value = double.tryParse(amount);
  if (value == null || !value.isFinite) {
    throw const FireflyInvalidPayload();
  }
  return value;
}

/// Keeps the offset at this date (including daylight-saving time).
String formatFireflyDateTime(DateTime date) {
  final local = date.toLocal();
  final offset = local.timeZoneOffset.inMinutes;
  final hours = (offset.abs() ~/ 60).toString().padLeft(2, '0');
  final minutes = (offset.abs() % 60).toString().padLeft(2, '0');
  return "${local.toIso8601String()}${offset < 0 ? '-' : '+'}$hours:$minutes";
}

DateTime parseFireflyDateTime(String date) => DateTime.parse(date).toLocal();

String formatFireflyDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
