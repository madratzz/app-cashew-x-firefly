import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Lists tags and lets the user create, rename and delete them.
class FireflyTagsPage extends StatefulWidget {
  const FireflyTagsPage({super.key, this.db, this.onLocalWrite});

  final FinanceDatabase? db;

  /// Called after each change; defaults to [fireflyLocalWrite].
  final VoidCallback? onLocalWrite;

  @override
  State<FireflyTagsPage> createState() => FireflyTagsPageState();
}

class FireflyTagsPageState extends State<FireflyTagsPage> {
  late final FinanceDatabase _db = widget.db ?? database;
  late final Stream<List<Tag>> _tags = _db.watchFireflyTags();

  void _written() => (widget.onLocalWrite ?? fireflyLocalWrite)();

  Future<void> _edit(List<Tag> all, [Tag? tag]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TagDialog(db: _db, tag: tag, existing: all),
    );
    if (saved == true) _written();
  }

  Future<void> _delete(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tag.name),
        content: Text('firefly-tags-delete-confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('firefly-tags-cancel'.tr())),
          TextButton(
              key: const ValueKey('firefly-tag-delete-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text('firefly-tags-delete'.tr())),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteFireflyTag(tag.tagPk);
    _written();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tag>>(
      stream: _tags,
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <Tag>[];
        return Scaffold(
          appBar: AppBar(title: Text('firefly-tags-title'.tr())),
          floatingActionButton: FloatingActionButton(
            key: const ValueKey('firefly-tags-add'),
            tooltip: 'firefly-tags-add'.tr(),
            onPressed: () => _edit(tags),
            child: const Icon(Icons.add_rounded),
          ),
          body: snapshot.hasData && tags.isEmpty
              ? Center(child: Text('firefly-tags-empty'.tr()))
              : ListView(
                  children: [
                    for (final tag in tags)
                      ListTile(
                        key: ValueKey('firefly-tag-${tag.tagPk}'),
                        leading: const Icon(Icons.sell_outlined),
                        title: Text(tag.name),
                        subtitle: tag.description == null
                            ? null
                            : Text(tag.description!),
                        onTap: () => _edit(tags, tag),
                        trailing: IconButton(
                          key: ValueKey('firefly-tag-delete-${tag.tagPk}'),
                          tooltip: 'firefly-tags-delete'.tr(),
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _delete(tag),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _TagDialog extends StatefulWidget {
  const _TagDialog({required this.db, required this.existing, this.tag});

  final FinanceDatabase db;
  final List<Tag> existing;
  final Tag? tag;

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.tag?.name);
  late final TextEditingController _description =
      TextEditingController(text: widget.tag?.description);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'firefly-tags-name-required'.tr());
      return;
    }
    // Firefly III requires unique tag names
    final taken = widget.existing.any((tag) =>
        tag.tagPk != widget.tag?.tagPk &&
        tag.name.toLowerCase() == name.toLowerCase());
    if (taken) {
      setState(() => _error = 'firefly-tags-name-taken'.tr());
      return;
    }
    await widget.db.saveFireflyTag(
      tagPk: widget.tag?.tagPk,
      name: name,
      description: _description.text,
      date: widget.tag?.date,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null
          ? 'firefly-tags-new'.tr()
          : 'firefly-tags-edit'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('firefly-tag-name-field'),
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
                labelText: 'firefly-tags-name'.tr(), errorText: _error),
          ),
          TextField(
            key: const ValueKey('firefly-tag-description-field'),
            controller: _description,
            decoration: InputDecoration(
                labelText: 'firefly-tags-description-field'.tr()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('firefly-tags-cancel'.tr())),
        TextButton(
            key: const ValueKey('firefly-tag-save'),
            onPressed: _save,
            child: Text('firefly-tags-save'.tr())),
      ],
    );
  }
}
