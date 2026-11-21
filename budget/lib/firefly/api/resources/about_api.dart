import 'package:budget/firefly/api/models/about.dart';
import 'package:budget/firefly/api/transport.dart';

class AboutApi {
  const AboutApi(this.transport);
  final FireflyTransport transport;

  Future<FireflyAbout> get() async =>
      FireflyAbout.fromJson(await transport.get('/about'));

  Future<FireflyUser> getUser() async =>
      FireflyUser.fromJson(await transport.get('/about/user'));
}
