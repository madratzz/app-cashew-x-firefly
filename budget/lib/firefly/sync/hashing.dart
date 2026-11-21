import 'dart:convert';

import 'package:budget/firefly/api/transport.dart';
import 'package:crypto/crypto.dart';

String canonicalJson(JsonObject fields) => jsonEncode(_canonical(fields));

String syncedFieldsHash(JsonObject fields) =>
    fireflyTextHash(canonicalJson(fields));

String fireflyTextHash(String value) =>
    sha256.convert(utf8.encode(value)).toString();

Object? _canonical(Object? value) {
  if (value is JsonObject) {
    return {
      for (final key in value.keys.toList()..sort())
        key: _canonical(value[key]),
    };
  }
  if (value is List<Object?>) return value.map(_canonical).toList();
  return value;
}
