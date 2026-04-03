import 'package:flutter/material.dart';

class CollectionFilterBar<T> extends StatelessWidget {
  final List<T> items;
  final T selectedItem;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onSelected;

  const CollectionFilterBar({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          return ChoiceChip(
            label: Text(labelBuilder(item)),
            selected: item == selectedItem,
            onSelected: (_) => onSelected(item),
          );
        }).toList(),
      ),
    );
  }
}
