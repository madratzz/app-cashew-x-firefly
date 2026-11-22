import 'package:budget/database/tables.dart';
import 'package:budget/firefly/db/tag_queries.dart';
import 'package:budget/firefly/ui/draft.dart';
import 'package:budget/struct/syncClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Widget fireflyTagsSection(
        BuildContext context, FireflyTransactionDraft draft) =>
    FireflyTagsSection(draft: draft);

/// Edits the draft's tag memberships. Typing a name that does not exist
/// offers to create the tag; the draft persists membership on save.
class FireflyTagsSection extends StatefulWidget {
  const FireflyTagsSection({required this.draft, super.key});

  final FireflyTransactionDraft draft;

  @override
  State<FireflyTagsSection> createState() => _FireflyTagsSectionState();
}

class _FireflyTagsSectionState extends State<FireflyTagsSection> {
  late final Stream<List<Tag>> _tags = widget.draft.db.watchFireflyTags();
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String tagPk, bool selected) {
    setState(() {
      if (selected) {
        widget.draft.tagPks.add(tagPk);
      } else {
        widget.draft.tagPks.remove(tagPk);
      }
    });
  }

  Future<void> _create(String name) async {
    final tag = await widget.draft.db.saveFireflyTag(name: name);
    fireflyLocalWrite();
    _search.clear();
    if (mounted) _toggle(tag.tagPk, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: StreamBuilder<List<Tag>>(
        stream: _tags,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Tag>[];
          final term = _search.text.trim();
          final lower = term.toLowerCase();
          final selected = [
            for (final tag in all)
              if (widget.draft.tagPks.contains(tag.tagPk)) tag
          ];
          final matches = [
            for (final tag in all)
              if (!widget.draft.tagPks.contains(tag.tagPk) &&
                  (lower.isEmpty || tag.name.toLowerCase().contains(lower)))
                tag
          ];
          final exists = all.any((tag) => tag.name.toLowerCase() == lower);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('firefly-tags-search'),
                controller: _search,
                decoration: InputDecoration(
                  labelText: 'firefly-tags-search'.tr(),
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (term.isNotEmpty && !exists) _create(term);
                },
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in selected)
                    InputChip(
                      key: ValueKey('firefly-tag-selected-${tag.tagPk}'),
                      label: Text(tag.name),
                      selected: true,
                      onDeleted: () => _toggle(tag.tagPk, false),
                      onPressed: () => _toggle(tag.tagPk, false),
                    ),
                  for (final tag in matches.take(20))
                    ActionChip(
                      key: ValueKey('firefly-tag-option-${tag.tagPk}'),
                      label: Text(tag.name),
                      onPressed: () {
                        _search.clear();
                        _toggle(tag.tagPk, true);
                      },
                    ),
                  if (term.isNotEmpty && !exists)
                    ActionChip(
                      key: const ValueKey('firefly-tag-create'),
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: Text('firefly-tags-create-named'.tr(args: [term])),
                      onPressed: () => _create(term),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
