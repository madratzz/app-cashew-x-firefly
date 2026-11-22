import 'package:budget/database/tables.dart';
import 'package:budget/firefly/sync/bootstrap_upload.dart';
import 'package:budget/firefly/sync/contracts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FireflyUploadFlow extends StatefulWidget {
  const FireflyUploadFlow({super.key, required this.upload});

  final FireflyBootstrapUpload upload;

  @override
  State<FireflyUploadFlow> createState() => _FireflyUploadFlowState();
}

class _FireflyUploadFlowState extends State<FireflyUploadFlow> {
  FireflyUploadPreview? _preview;
  FireflyUploadReport? _report;
  List<FireflyUploadIssue> _pending = const [];
  FireflyUploadIssue? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _busy = false;
    _perform(_load);
  }

  Future<void> _load() async {
    _preview = null;
    _error = null;
    _pending = await widget.upload.pending();
    _preview = await widget.upload.prepare();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on FireflyUploadIssue catch (issue) {
      _error = issue;
    } catch (_) {
      _error = const FireflyUploadIssue('firefly-upload-unverified');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmUpload() => _perform(() async {
        final report = await widget.upload.run(confirmed: _preview);
        if (!mounted) return;
        if (report.succeeded && report.cleanupWarnings.isEmpty) {
          await _finish();
          return;
        }
        _report = report;
        _pending = await widget.upload.pending();
      });

  Future<void> _finish() async {
    setState(() => _busy = false);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _checkAgain() => _perform(() async {
        _report = null;
        await widget.upload.checkAgain();
        await _load();
      });

  Future<void> _link(String intent) => _perform(() async {
        final candidates = await widget.upload.candidates(intent);
        if (!mounted) return;
        if (candidates.isEmpty) {
          _error =
              const FireflyUploadIssue('firefly-upload-no-matching-object');
          return;
        }
        final id = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text('firefly-upload-select-object'.tr()),
            children: [
              for (final candidate in candidates)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, candidate.id),
                  child: Text('firefly-upload-candidate'.tr(namedArgs: {
                    'label': candidate.label,
                    'id': candidate.id,
                  })),
                ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text('firefly-connection-cancel'.tr()),
              ),
            ],
          ),
        );
        if (id == null) return;
        await widget.upload.link(intent, id);
        _report = null;
        await _load();
      });

  Future<void> _authorizeResend(String intent) => _perform(() async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('firefly-upload-resend'.tr()),
            content: Text('firefly-upload-resend-warning'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('firefly-connection-cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('firefly-upload-resend'.tr()),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await widget.upload.authorizeResend(intent);
        _report = null;
        await _load();
      });

  Widget _issue(SyncIssue issue) {
    final detail = issue is FireflyUploadIssue
        ? [
            if (issue.item != null) issue.item!,
            if (issue.detail != null) issue.detail!
          ]
        : const <String>[];
    return ListTile(
      dense: true,
      title: Text(issue.message.tr()),
      subtitle: detail.isEmpty ? null : Text(detail.join('\n')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final report = _report;
    final canFinish = report?.succeeded == true;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text('firefly-upload-title'.tr()),
          automaticallyImplyLeading: !_busy,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (preview != null) ...[
                Text((preview.resuming
                        ? 'firefly-upload-resume-summary'
                        : 'firefly-upload-summary')
                    .tr()),
                for (final entry in preview.counts.entries)
                  _count(_entityLabel(entry.key), entry.value),
                _count('firefly-upload-transfers', preview.transfers),
                _count('firefly-upload-splits', preview.splits),
                _count('firefly-upload-split-groups', preview.splitGroups),
                if (preview.roundedTransactions > 0)
                  Text('firefly-upload-rounding'.tr(namedArgs: {
                    'count': '${preview.roundedTransactions}',
                  })),
                if (preview.currencies.isNotEmpty)
                  Text(preview.currencies.join(', ')),
                if (preview.skipped.isNotEmpty)
                  ExpansionTile(
                    title: Text('firefly-upload-skipped'.tr(namedArgs: {
                      'count': '${preview.skipped.length}',
                    })),
                    children: preview.skipped.map(_issue).toList(),
                  ),
              ],
              if (_error != null) _issue(_error!),
              if (report != null) ...[
                for (final issue in report.issues)
                  if (issue is! FireflyUploadIssue || issue.intent == null)
                    _issue(issue),
                for (final warning in report.cleanupWarnings) _issue(warning),
              ],
              for (final issue in _pending) ...[
                _issue(issue),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => _link(issue.intent!),
                      child: Text('firefly-upload-link'.tr()),
                    ),
                    TextButton(
                      onPressed:
                          _busy ? null : () => _authorizeResend(issue.intent!),
                      child: Text('firefly-upload-resend'.tr()),
                    ),
                  ],
                ),
              ],
              if (!canFinish &&
                  (_pending.isNotEmpty || _error != null || report != null))
                OutlinedButton(
                  onPressed: _busy ? null : _checkAgain,
                  child: Text('firefly-upload-check-again'.tr()),
                ),
              if (canFinish)
                FilledButton(
                  onPressed: _busy ? null : _finish,
                  child: Text('firefly-upload-continue'.tr()),
                )
              else if (preview != null && _error == null)
                FilledButton(
                  key: const ValueKey('firefly-upload-confirm'),
                  onPressed: _busy ? null : _confirmUpload,
                  child: Text((preview.resuming
                          ? 'firefly-upload-resume'
                          : 'firefly-upload-confirm')
                      .tr()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _count(String title, int count) => ListTile(
        dense: true,
        title: Text(title.tr()),
        trailing: Text('$count'),
      );
}

String _entityLabel(FireflyEntityType type) => switch (type) {
      FireflyEntityType.currency => 'firefly-upload-currencies',
      FireflyEntityType.walletAccount => 'firefly-upload-accounts',
      FireflyEntityType.liabilityAccount => 'firefly-upload-liabilities',
      FireflyEntityType.category => 'firefly-upload-categories',
      FireflyEntityType.payeeAccount => 'firefly-upload-payees',
      FireflyEntityType.tag => 'firefly-upload-tags',
      FireflyEntityType.budget => 'firefly-upload-budgets',
      FireflyEntityType.budgetLimit => 'firefly-upload-budget-limits',
      FireflyEntityType.piggyBank => 'firefly-upload-piggy-banks',
      FireflyEntityType.bill => 'firefly-upload-bills',
      FireflyEntityType.transaction => 'firefly-upload-transactions',
      FireflyEntityType.attachment => 'firefly-upload-attachments',
      _ => 'firefly-upload-title',
    };
