import 'package:budget/firefly/api/models/about.dart';
import 'package:budget/firefly/api/transport.dart';

class AboutApi {
  const AboutApi(this.transport);
  final FireflyTransport transport;

  Future<FireflyAbout> get() async => throw const FireflyTransportUnavailable();

  Future<FireflyUser> getUser() async =>
      throw const FireflyTransportUnavailable();
}
