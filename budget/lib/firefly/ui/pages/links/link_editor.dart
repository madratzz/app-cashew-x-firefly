part of 'links_page.dart';

typedef _LinkDraft = ({
  String inward,
  String outward,
  String type,
  String notes
});

class _LinkEditor extends StatefulWidget {
  const _LinkEditor({required this.types, required this.targets});

  final List<FireflyLinkType> types;
  final List<FireflyLinkTarget> targets;

  @override
  State<_LinkEditor> createState() => _LinkEditorState();
}

class _LinkEditorState extends State<_LinkEditor> {
  FireflyLinkTarget? _inward;
  FireflyLinkTarget? _outward;
  FireflyLinkType? _type;
  String _notes = '';

  Future<void> _selectTarget({required bool inward}) async {
    final excluded = inward ? _outward : _inward;
    final target = await showDialog<FireflyLinkTarget>(
      context: context,
      builder: (context) => _TargetPicker(
        targets: widget.targets
            .where((target) => target.journalId != excluded?.journalId)
            .toList(),
      ),
    );
    if (target == null || !mounted) return;
    setState(() {
      if (inward) {
        _inward = target;
      } else {
        _outward = target;
      }
    });
  }

  void _save() => Navigator.pop<_LinkDraft>(
        context,
        (
          inward: _inward!.transactionPk,
          outward: _outward!.transactionPk,
          type: _type!.id,
          notes: _notes,
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('firefly-links-add'.tr()),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _targetField('firefly-links-inward'.tr(), _inward, inward: true),
            DropdownButtonFormField<FireflyLinkType>(
              isExpanded: true,
              decoration: InputDecoration(labelText: 'firefly-links-type'.tr()),
              items: [
                for (final type in widget.types)
                  DropdownMenuItem(
                    value: type,
                    child: Text(type.inward, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (type) => setState(() => _type = type),
            ),
            _targetField('firefly-links-outward'.tr(), _outward, inward: false),
            TextField(
              decoration:
                  InputDecoration(labelText: 'firefly-links-notes'.tr()),
              onChanged: (notes) => _notes = notes,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('firefly-links-cancel'.tr()),
          ),
          FilledButton(
            onPressed: _inward != null && _outward != null && _type != null
                ? _save
                : null,
            child: Text('firefly-links-save'.tr()),
          ),
        ],
      );

  Widget _targetField(String label, FireflyLinkTarget? target,
          {required bool inward}) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: target == null ? null : Text(_targetName(target)),
        trailing: const Icon(Icons.search_rounded),
        onTap: () => _selectTarget(inward: inward),
      );
}

class _TargetPicker extends StatefulWidget {
  const _TargetPicker({required this.targets});

  final List<FireflyLinkTarget> targets;

  @override
  State<_TargetPicker> createState() => _TargetPickerState();
}

class _TargetPickerState extends State<_TargetPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final targets = widget.targets
        .where((target) =>
            target.name.toLowerCase().contains(_query) ||
            target.journalId.contains(_query))
        .toList();
    return AlertDialog(
      title: TextField(
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'firefly-links-search'.tr(),
        ),
        onChanged: (value) =>
            setState(() => _query = value.toLowerCase().trim()),
      ),
      content: SizedBox(
        width: 440,
        height: MediaQuery.sizeOf(context).height * .32,
        child: ListView.builder(
          itemCount: targets.length,
          itemBuilder: (context, index) {
            final target = targets[index];
            return ListTile(
              title: Text(_targetName(target)),
              subtitle: target.name.trim().isEmpty
                  ? null
                  : Text(_journalLabel(target.journalId)),
              onTap: () => Navigator.pop(context, target),
            );
          },
        ),
      ),
    );
  }
}
