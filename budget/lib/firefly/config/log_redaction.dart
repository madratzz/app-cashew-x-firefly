final _authorization = RegExp(
  r'''(\bauthorization["']?\s*[:=]\s*)(?:"[^"\r\n]*"|'[^'\r\n]*'|[^\r\n,;}]*)''',
  caseSensitive: false,
);
final _bearer =
    RegExp(r'''(\bbearer\s+)[^\s"'\],;)}]+''', caseSensitive: false);

String redactFireflyLog(String message, {String? token}) {
  final text = token == null || token.isEmpty
      ? message
      : message.replaceAll(token, 'REDACTED');
  return text
      .replaceAllMapped(_authorization, (match) => '${match[1]}REDACTED')
      .replaceAllMapped(_bearer, (match) => '${match[1]}REDACTED');
}

/// Redacts Firefly text before handing it to the app's print capture.
void logFirefly(String message, {String? token}) {
  // ignore: avoid_print
  print(redactFireflyLog(message, token: token));
}
