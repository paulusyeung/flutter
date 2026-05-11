import 'package:flutter/material.dart';

/// Bottom-sheet body for one custom-field column (1..4).
///
/// Options are fed in as a list (snapshotted from
/// `vm.watchCustomValueOptions(columnIndex)`); selection is applied on Done.
class CustomFilterSheet extends StatefulWidget {
  const CustomFilterSheet({
    required this.columnIndex,
    required this.options,
    required this.initial,
    required this.onApply,
    super.key,
  });

  final int columnIndex;
  final List<String> options;
  final Set<String> initial;
  final void Function(Set<String>) onApply;

  @override
  State<CustomFilterSheet> createState() => _CustomFilterSheetState();
}

class _CustomFilterSheetState extends State<CustomFilterSheet> {
  late Set<String> _local;

  @override
  void initState() {
    super.initState();
    _local = Set<String>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Custom ${widget.columnIndex}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: TextButton(
              onPressed: () => setState(_local.clear),
              child: const Text('Clear'),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final v in widget.options)
                  CheckboxListTile(
                    value: _local.contains(v),
                    title: Text(v),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _local.add(v);
                        } else {
                          _local.remove(v);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () {
                    widget.onApply(_local);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
