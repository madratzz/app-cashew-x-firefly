import 'package:budget/firefly/api/firefly_api.dart';
import 'package:budget/firefly/api/http_transport.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/pages/connection/connection_page.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:budget/struct/settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Fetches the Firefly user email for a connected server.
typedef FireflyEmailLoader = Future<String?> Function(Uri baseUrl);

Future<String?> _loadEmail(Uri baseUrl) async {
  final transport = HttpFireflyTransport(
      baseUrl: baseUrl, readToken: () => FireflyMode.tokens.read());
  try {
    return (await FireflyApi(transport).about.getUser()).displayName;
  } finally {
    transport.close();
  }
}

/// Account entry that replaces Google sign-in (WP-42).
///
/// Shows "Connect to Firefly III" when no token is stored, otherwise the
/// server host, the user email from GET /about/user, and Disconnect.
class FireflyAccountTile extends StatefulWidget {
  const FireflyAccountTile({
    super.key,
    this.compact = false,
    this.emailLoader,
    this.controller,
    this.connectPage,
  });

  /// Sidebar layout: one row, no Disconnect button.
  final bool compact;
  final FireflyEmailLoader? emailLoader;
  final FireflyConnectionController? controller;
  final Widget? connectPage;

  /// Email cached per server so headers do not refetch on every rebuild.
  static final Map<String, String?> _emailCache = {};
  static void clearCache() => _emailCache.clear();

  @override
  State<FireflyAccountTile> createState() => _FireflyAccountTileState();
}

class _FireflyAccountTileState extends State<FireflyAccountTile> {
  bool _loading = true;
  bool _connected = false;
  String? _email;
  bool _emailFailed = false;

  String get _baseUrl => FireflyMode.config.baseUrl;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    String? token;
    try {
      token = await FireflyMode.tokens.read();
    } catch (_) {}
    final connected =
        _baseUrl.isNotEmpty && token != null && token.trim().isNotEmpty;
    if (!mounted) return;
    setState(() {
      _connected = connected;
      _loading = false;
      _email = FireflyAccountTile._emailCache[_baseUrl];
      _emailFailed = false;
    });
    if (connected && !FireflyAccountTile._emailCache.containsKey(_baseUrl)) {
      _fetchEmail();
    }
  }

  Future<void> _fetchEmail() async {
    final url = _baseUrl;
    try {
      final email = await (widget.emailLoader ?? _loadEmail)(Uri.parse(url));
      FireflyAccountTile._emailCache[url] = email;
      if (mounted) setState(() => _email = email);
    } catch (_) {
      if (mounted) setState(() => _emailFailed = true);
    }
  }

  Future<void> _connect() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => widget.connectPage ?? const FireflyConnectionPage()));
    await _refresh();
  }

  Future<void> _disconnect() async {
    final controller = widget.controller ??
        FireflyConnectionController(
            writeSetting: (key, value) =>
                updateSettings(key, value, updateGlobalState: false));
    await controller.signOut();
    FireflyAccountTile._emailCache.remove(_baseUrl);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('firefly-account-disconnected'.tr())));
    await _refresh();
  }

  String get _host => Uri.tryParse(_baseUrl)?.host ?? _baseUrl;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (!_connected) {
      return ListTile(
        key: const ValueKey('firefly-account-connect'),
        leading: const Icon(Icons.local_fire_department_rounded),
        title: Text('firefly-account-connect'.tr()),
        subtitle: widget.compact
            ? null
            : Text('firefly-account-connect-description'.tr()),
        onTap: _connect,
      );
    }
    final subtitle = _email ??
        (_emailFailed
            ? 'firefly-account-email-unknown'.tr()
            : 'firefly-account-email-loading'.tr());
    return ListTile(
      key: const ValueKey('firefly-account-connected'),
      leading: const Icon(Icons.local_fire_department_rounded),
      title: Text(_host, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, overflow: TextOverflow.ellipsis),
      onTap: _connect,
      trailing: widget.compact
          ? null
          : TextButton(
              onPressed: _disconnect,
              child: Text('firefly-account-disconnect'.tr()),
            ),
    );
  }
}
