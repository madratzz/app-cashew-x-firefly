import 'package:budget/database/tables.dart';
import 'package:budget/firefly/api/models/transaction_link.dart';
import 'package:budget/firefly/api/transport.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:budget/firefly/sync/entities/transaction_link_syncer.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'link_editor.dart';

const _syncer = TransactionLinkSyncer();

class FireflyLinksPage extends StatefulWidget {
  const FireflyLinksPage({super.key, this.db, this.syncContext});

  final FinanceDatabase? db;
  final Future<SyncContext?> Function()? syncContext;

  @override
  State<FireflyLinksPage> createState() => _FireflyLinksPageState();
}

class _FireflyLinksPageState extends State<FireflyLinksPage> {
  late final _db = widget.db ?? database;
  late final _links = _db.watchFireflyTransactionLinks();
  late final _types = _db.watchFireflyLinkTypes();
  late final _targets = _db.watchFireflyLinkTargets();

  bool _online = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() => _attempt(() async {
        final sync = await _currentSyncContext();
        if (sync != null) await _syncer.pull(sync);
        if (mounted) setState(() => _online = sync != null);
      });

  Future<SyncContext?> _currentSyncContext() async {
    final sync = await (widget.syncContext ?? _appSyncContext)();
    return sync?.config.mode == true ? sync : null;
  }

  Future<SyncContext> _writeContext() async =>
      await _currentSyncContext() ??
      (throw const FireflyTransportUnavailable());

  Future<SyncContext?> _appSyncContext() async =>
      (await fireflySchedulerIfEnabled())?.engine.context;

  Future<void> _attempt(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on FireflyException catch (error) {
      if (!mounted) return;
      if (error is FireflyNetworkError ||
          error is FireflyTimeout ||
          error is FireflyUnauthorized ||
          error is FireflyTransportUnavailable) {
        setState(() => _online = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('firefly-links-request-failed'.tr()),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create(
      List<FireflyLinkType> types, List<FireflyLinkTarget> targets) async {
    final draft = await showDialog<_LinkDraft>(
      context: context,
      builder: (context) => _LinkEditor(types: types, targets: targets),
    );
    if (!mounted || draft == null || !_online) return;
    await _attempt(() async => _syncer.createLink(
          await _writeContext(),
          inwardTransactionPk: draft.inward,
          outwardTransactionPk: draft.outward,
          linkTypeId: draft.type,
          notes: draft.notes,
        ));
  }

  Future<void> _delete(FireflyTransactionLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('firefly-links-delete-title'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('firefly-links-cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('firefly-links-delete'.tr()),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || !_online) return;
    await _attempt(
        () async => _syncer.deleteLink(await _writeContext(), link.id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('firefly-links-title'.tr()),
          actions: [
            IconButton(
              tooltip: 'firefly-links-refresh'.tr(),
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _busy ? null : _refresh,
            ),
          ],
        ),
        body: StreamBuilder<List<FireflyTransactionLink>>(
          stream: _links,
          builder: (context, links) => StreamBuilder<List<FireflyLinkType>>(
            stream: _types,
            builder: (context, types) => StreamBuilder<List<FireflyLinkTarget>>(
              stream: _targets,
              builder: (context, targets) {
                if (links.hasError || types.hasError || targets.hasError) {
                  return Center(child: Text('firefly-links-load-failed'.tr()));
                }
                if (!links.hasData || !types.hasData || !targets.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _content(links.data!, types.data!, targets.data!);
              },
            ),
          ),
        ),
      );

  Widget _content(List<FireflyTransactionLink> links,
      List<FireflyLinkType> types, List<FireflyLinkTarget> targets) {
    final typeById = {for (final type in types) type.id: type};
    final targetNames = {
      for (final target in targets) target.journalId: _targetName(target),
    };
    final canAdd = targets.length >= 2 && types.isNotEmpty;
    return ListView(
      children: [
        if (_busy) const LinearProgressIndicator(),
        if (!_busy && !_online)
          ListTile(title: Text('firefly-links-offline'.tr())),
        if (_online)
          ListTile(
            leading: const Icon(Icons.add_link_rounded),
            title: Text('firefly-links-add'.tr()),
            subtitle:
                canAdd ? null : Text('firefly-links-add-unavailable'.tr()),
            enabled: !_busy && canAdd,
            onTap: !_busy && canAdd ? () => _create(types, targets) : null,
          ),
        if (links.isEmpty) ListTile(title: Text('firefly-links-empty'.tr())),
        for (final link in links)
          ListTile(
            key: ValueKey('firefly-link-${link.id}'),
            title: Text(
              [
                targetNames[link.inwardJournalId] ??
                    _journalLabel(link.inwardJournalId),
                typeById[link.linkTypeId]?.inward ??
                    'firefly-links-related-to'.tr(),
                targetNames[link.outwardJournalId] ??
                    _journalLabel(link.outwardJournalId),
              ].join(' '),
            ),
            subtitle: link.notes == null ? null : Text(link.notes!),
            trailing: IconButton(
              tooltip: 'firefly-links-delete'.tr(),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _busy || !_online ? null : () => _delete(link),
            ),
          ),
      ],
    );
  }
}

String _journalLabel(String id) =>
    'firefly-links-journal'.tr(namedArgs: {'id': id});

String _targetName(FireflyLinkTarget target) =>
    target.name.trim().isEmpty ? _journalLabel(target.journalId) : target.name;
