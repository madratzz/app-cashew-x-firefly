import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/firefly/config/config.dart';
import 'package:budget/firefly/firefly.dart';
import 'package:budget/firefly/ui/pages/connection/conflicts_page.dart';
import 'package:budget/firefly/ui/pages/connection/sync_issues_page.dart';
import 'package:budget/firefly/ui/settings/connection_controller.dart';
import 'package:budget/firefly/ui/settings/sync_status.dart';
import 'package:budget/struct/settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _writeAppSetting(String key, Object value) =>
    updateSettings(key, value, updateGlobalState: false);

Future<Directory> _defaultBackupDirectory() async => Directory(
    '${(await getApplicationDocumentsDirectory()).path}/firefly-backups');

/// Width cap so the form stays readable on desktop windows.
const fireflyPageMaxWidth = 720.0;

class FireflyConnectionPage extends StatefulWidget {
  const FireflyConnectionPage({
    super.key,
    this.controller,
    this.db,
    this.backupDirectory,
    this.beforeBackup,
    this.onboarding = false,
  });

  final FireflyConnectionController? controller;
  final FinanceDatabase? db;
  final Future<Directory> Function()? backupDirectory;
  final Future<void> Function()? beforeBackup;

  /// Pops with true after a successful connection when opened from onboarding.
  final bool onboarding;

  @override
  State<FireflyConnectionPage> createState() => FireflyConnectionPageState();
}

class FireflyConnectionPageState extends State<FireflyConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _url =
      TextEditingController(text: FireflyMode.config.baseUrl);
  final _token = TextEditingController();
  late final FireflyConnectionController _controller = widget.controller ??
      FireflyConnectionController(writeSetting: _writeAppSetting);

  bool _busy = false;
  bool _hasToken = false;
  String? _statusText;
  bool _statusError = false;

  FinanceDatabase get _db => widget.db ?? FireflySync.db();

  @override
  void initState() {
    super.initState();
    _loadTokenPresence();
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _loadTokenPresence() async {
    String? token;
    try {
      token = await _controller.tokens.read();
    } catch (_) {
      token = null;
    }
    if (mounted) setState(() => _hasToken = token?.isNotEmpty == true);
  }

  void _setStatus(String text, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _statusText = text;
      _statusError = error;
    });
  }

  String _successText(FireflyConnectionResult result) =>
      'firefly-connection-success'.tr(namedArgs: {
        'version': result.about!.version,
        'user': result.user!.displayName ?? result.user!.id,
      });

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() => _run(() async {
        if (!_formKey.currentState!.validate()) return;
        _setStatus('firefly-connection-testing'.tr());
        final result = await _controller.test(_url.text, _token.text);
        result.ok
            ? _setStatus(_successText(result))
            : _setStatus(result.errorKey!.tr(), error: true);
      });

  Future<void> _connect() => _run(() async {
        if (!_formKey.currentState!.validate()) return;
        _setStatus('firefly-connection-testing'.tr());
        final result = await _controller.connect(_url.text, _token.text);
        if (!result.ok) {
          _setStatus(result.errorKey!.tr(), error: true);
          return;
        }
        _token.clear();
        _hasToken = true;
        _setStatus(_successText(result));
        if (!FireflyMode.config.mode) await _enableMode();
        if (widget.onboarding && mounted && FireflyMode.config.mode) {
          Navigator.of(context).pop(true);
        }
      });

  /// Turns the mode on, running the replace flow on a first connection.
  Future<void> _enableMode() async {
    if (await FireflyReplaceFlow.isFirstConnection(_db)) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('firefly-connection-replace-title'.tr()),
          content: Text('firefly-connection-replace-description'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('firefly-connection-cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('firefly-connection-replace-confirm'.tr()),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final File backup;
      try {
        backup = await FireflyReplaceFlow(
          db: _db,
          backupDirectory: widget.backupDirectory ?? _defaultBackupDirectory,
          beforeBackup: widget.beforeBackup ??
              (widget.db == null ? () async => backupSettings() : null),
        ).run();
      } catch (_) {
        _setStatus('firefly-connection-replace-failed'.tr(), error: true);
        return;
      }
      _setStatus('firefly-connection-replace-done'
          .tr(namedArgs: {'path': backup.path}));
    }
    await _controller.setMode(true);
    if (mounted) setState(() {});
    FireflySync.syncNow(fullResync: true);
  }

  Future<void> _toggleMode(bool value) => _run(() async {
        if (value) {
          await _enableMode();
        } else {
          await _controller.setMode(false);
          if (mounted) setState(() {});
        }
      });

  Future<void> _signOut() => _run(() async {
        await _controller.signOut();
        _hasToken = false;
        _setStatus('firefly-connection-signed-out'.tr());
      });

  @override
  Widget build(BuildContext context) {
    final config = FireflyMode.config;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('firefly-connection-title'.tr())),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: fireflyPageMaxWidth),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('firefly-url'),
                      controller: _url,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'firefly-connection-url'.tr(),
                        hintText: 'firefly-connection-url-hint'.tr(),
                      ),
                      validator: (value) => fireflyUrlError(value ?? '')?.tr(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('firefly-token'),
                      controller: _token,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'firefly-connection-token'.tr(),
                        helperText: 'firefly-connection-token-help'.tr(),
                        helperMaxLines: 3,
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'firefly-connection-token-required'.tr()
                          : null,
                    ),
                    if (_controller.tokens.sessionOnly)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            'firefly-connection-token-session-only'.tr(),
                            style: TextStyle(color: theme.colorScheme.error)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    key: const ValueKey('firefly-test'),
                    onPressed: _busy ? null : _test,
                    child: Text('firefly-connection-test'.tr()),
                  ),
                  FilledButton(
                    key: const ValueKey('firefly-connect'),
                    onPressed: _busy ? null : _connect,
                    child: Text('firefly-connection-save'.tr()),
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_statusText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _statusText!,
                    key: const ValueKey('firefly-status'),
                    style: _statusError
                        ? TextStyle(color: theme.colorScheme.error)
                        : null,
                  ),
                ),
              const Divider(height: 32),
              SwitchListTile(
                key: const ValueKey('firefly-mode'),
                title: Text('firefly-connection-mode'.tr()),
                subtitle: Text(_hasToken
                    ? 'firefly-connection-mode-description'.tr()
                    : 'firefly-connection-mode-needs-token'.tr()),
                value: config.mode,
                onChanged:
                    _busy || (!_hasToken && !config.mode) ? null : _toggleMode,
              ),
              if (FireflyMode.enabled) ...[
                fireflySyncStatus(context),
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: Text('firefly-connection-full-resync'.tr()),
                  subtitle:
                      Text('firefly-connection-full-resync-description'.tr()),
                  onTap: () => FireflySync.syncNow(fullResync: true),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.error_outline_rounded),
                title: Text('firefly-connection-sync-issues'.tr()),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => FireflySyncIssuesPage(db: widget.db))),
              ),
              ListTile(
                leading: const Icon(Icons.call_split_rounded),
                title: Text('firefly-connection-conflicts'.tr()),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => FireflyConflictsPage(db: widget.db))),
              ),
              _AdvancedSettings(
                  config: config, writeSetting: _controller.writeSetting),
              if (_hasToken)
                ListTile(
                  key: const ValueKey('firefly-sign-out'),
                  leading: const Icon(Icons.logout_rounded),
                  title: Text('firefly-connection-sign-out'.tr()),
                  subtitle:
                      Text('firefly-connection-sign-out-description'.tr()),
                  onTap: _busy ? null : _signOut,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedSettings extends StatefulWidget {
  const _AdvancedSettings({required this.config, required this.writeSetting});

  final FireflyConfig config;
  final FireflySettingWriter writeSetting;

  @override
  State<_AdvancedSettings> createState() => _AdvancedSettingsState();
}

class _AdvancedSettingsState extends State<_AdvancedSettings> {
  late bool _syncOnChange = widget.config.syncOnChange;
  late bool _applyRules = widget.config.applyRules;
  late bool _fireWebhooks = widget.config.fireWebhooks;

  Future<void> _write(String key, Object value) async {
    await widget.writeSetting(key, value);
    FireflySync.reset();
  }

  Widget _switch(
          String label, bool value, String key, void Function(bool) assign) =>
      SwitchListTile(
        title: Text(label.tr()),
        value: value,
        onChanged: (next) {
          setState(() => assign(next));
          _write(key, next);
        },
      );

  Widget _number(String label, int initial, String key, {int min = 1}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: TextFormField(
          initialValue: '$initial',
          keyboardType: TextInputType.number,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(labelText: label.tr()),
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            return parsed == null || parsed < min
                ? 'firefly-connection-number-invalid'.tr()
                : null;
          },
          onChanged: (value) {
            final parsed = int.tryParse(value);
            if (parsed != null && parsed >= min) _write(key, parsed);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return ExpansionTile(
      leading: const Icon(Icons.tune_rounded),
      title: Text('firefly-connection-advanced'.tr()),
      children: [
        _switch('firefly-connection-sync-on-change', _syncOnChange,
            FireflyConfig.syncOnChangeKey, (v) => _syncOnChange = v),
        _switch('firefly-connection-apply-rules', _applyRules,
            FireflyConfig.applyRulesKey, (v) => _applyRules = v),
        _switch('firefly-connection-fire-webhooks', _fireWebhooks,
            FireflyConfig.fireWebhooksKey, (v) => _fireWebhooks = v),
        _number('firefly-connection-window-days', config.transactionWindowDays,
            FireflyConfig.transactionWindowDaysKey,
            min: 0),
        _number('firefly-connection-page-size', config.pageSize,
            FireflyConfig.pageSizeKey),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: TextFormField(
            initialValue: config.subcategorySeparator,
            decoration:
                InputDecoration(labelText: 'firefly-connection-separator'.tr()),
            onChanged: (value) {
              if (value.isNotEmpty) {
                _write(FireflyConfig.subcategorySeparatorKey, value);
              }
            },
          ),
        ),
      ],
    );
  }
}
