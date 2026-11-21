import 'package:budget/firefly/api/transport.dart';

class FireflyAbout {
  const FireflyAbout({required this.version, this.apiVersion});

  factory FireflyAbout.fromJson(JsonObject data) {
    final version = data['version'];
    final apiVersion = data['api_version'];
    if (version is! String || version.isEmpty) {
      throw const FireflyInvalidPayload();
    }
    return FireflyAbout(
      version: version,
      apiVersion: apiVersion is String ? apiVersion : null,
    );
  }

  final String version;
  final String? apiVersion;
}

class FireflyUser {
  const FireflyUser({required this.id, this.displayName});

  factory FireflyUser.fromJson(JsonObject data) {
    final id = data['id'];
    final attributes = data['attributes'];
    if (id is! String || id.isEmpty || attributes is! JsonObject) {
      throw const FireflyInvalidPayload();
    }
    final email = attributes['email'];
    return FireflyUser(id: id, displayName: email is String ? email : null);
  }

  final String id;
  final String? displayName;
}
