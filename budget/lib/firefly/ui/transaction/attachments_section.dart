import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/attachment_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/firefly/ui/pages/attachments/attachment_actions.dart';
import 'package:drift/drift.dart' show Value;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyAttachmentsSection(
        BuildContext context, FireflyTransactionDraft draft) =>
    FireflyAttachmentsSection(draft: draft);

/// Edits the draft's attachment list. Changes are saved by the draft.
class FireflyAttachmentsSection extends StatefulWidget {
  const FireflyAttachmentsSection({required this.draft, super.key});

  final FireflyTransactionDraft draft;

  @override
  State<FireflyAttachmentsSection> createState() =>
      _FireflyAttachmentsSectionState();
}

class _FireflyAttachmentsSectionState extends State<FireflyAttachmentsSection> {
  FireflyTransactionDraft get draft => widget.draft;
  bool busy = false;

  void showError(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> add(FireflyAttachmentSource source) async {
    setState(() => busy = true);
    try {
      final picked = await FireflyAttachmentActions.pick(source);
      if (picked == null) return;
      final row = await draft.db.prepareFireflyAttachment(
        filename: picked.name,
        bytes: picked.bytes,
        mime: picked.mime,
        supportDirectory: FireflyAttachmentActions.supportDirectory,
      );
      if (!mounted) return;
      setState(() => draft.attachments = [...draft.attachments, row]);
    } catch (error) {
      if (mounted) showError(fireflyAttachmentError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove(Attachment row) async {
    setState(() => draft.attachments = [
          for (final item in draft.attachments)
            if (item.attachmentPk != row.attachmentPk) item
        ]);
    await draft.db.discardFireflyAttachmentDraftFile(row,
        supportDirectory: FireflyAttachmentActions.supportDirectory);
  }

  Future<void> rename(Attachment row) async {
    final title = await showFireflyRenameDialog(context, row);
    if (title == null || !mounted) return;
    setState(() => draft.attachments = [
          for (final item in draft.attachments)
            item.attachmentPk == row.attachmentPk
                ? item.copyWith(title: Value(title))
                : item
        ]);
  }

  Future<void> open(Attachment row) async {
    final error = await openFireflyAttachmentFile(draft.db, row);
    if (error != null && mounted) showError(error);
  }

  @override
  Widget build(BuildContext context) {
    final sources = FireflyAttachmentActions.sources();
    return Column(
      key: const ValueKey('firefly-attachments-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.attach_file_rounded),
          title: Text('firefly-attachments-title'.tr()),
          trailing: busy
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : PopupMenuButton<FireflyAttachmentSource>(
                  key: const ValueKey('firefly-attachments-add'),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'firefly-attachments-add'.tr(),
                  onSelected: add,
                  itemBuilder: (_) => [
                    for (final source in sources)
                      PopupMenuItem(
                          value: source,
                          child: Text(fireflySourceLabel(source))),
                  ],
                ),
        ),
        for (final row in draft.attachments)
          FireflyAttachmentTile(
            row: row,
            onOpen: () => open(row),
            onRename: () => rename(row),
            onRemove: () => remove(row),
          ),
      ],
    );
  }
}

enum _TileAction { rename, remove }

class FireflyAttachmentTile extends StatelessWidget {
  const FireflyAttachmentTile({
    required this.row,
    required this.onOpen,
    required this.onRemove,
    this.onRename,
    super.key,
  });

  final Attachment row;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final queued = row.uploadState == fireflyAttachmentQueued;
    return ListTile(
      key: ValueKey('firefly-attachment-${row.attachmentPk}'),
      leading: Icon((row.mime ?? '').startsWith('image/')
          ? Icons.image_outlined
          : Icons.insert_drive_file_outlined),
      title: Text(fireflyAttachmentLabel(row),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        fireflyAttachmentSize(row.size),
        if (queued) 'firefly-attachments-queued'.tr(),
      ].where((part) => part.isNotEmpty).join(' · ')),
      onTap: onOpen,
      trailing: PopupMenuButton<_TileAction>(
        onSelected: (action) => switch (action) {
          _TileAction.rename => onRename?.call(),
          _TileAction.remove => onRemove(),
        },
        itemBuilder: (_) => [
          if (onRename != null)
            PopupMenuItem(
                value: _TileAction.rename,
                child: Text('firefly-attachments-rename'.tr())),
          PopupMenuItem(
              value: _TileAction.remove,
              child: Text('firefly-attachments-remove'.tr())),
        ],
      ),
    );
  }
}

/// Returns the trimmed new title, or null when cancelled.
Future<String?> showFireflyRenameDialog(BuildContext context, Attachment row) {
  final controller = TextEditingController(text: fireflyAttachmentLabel(row));
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      String? error;
      try {
        validateFireflyAttachmentName(controller.text);
      } on FireflyAttachmentException {
        error = 'firefly-attachments-error-name'.tr();
      }
      return AlertDialog(
        title: Text('firefly-attachments-rename'.tr()),
        content: TextField(
          key: const ValueKey('firefly-attachment-name'),
          controller: controller,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
              labelText: 'firefly-attachments-name'.tr(), errorText: error),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
          TextButton(
              onPressed: error == null
                  ? () => Navigator.pop(context, controller.text.trim())
                  : null,
              child: Text(MaterialLocalizations.of(context).okButtonLabel)),
        ],
      );
    }),
  );
}
