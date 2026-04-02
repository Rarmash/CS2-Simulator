import 'package:flutter/material.dart';

class CollectibleGridSliver<T> extends StatelessWidget {
  final List<T> items;
  final int crossAxisCount;
  final double childAspectRatio;
  final Widget Function(T item) itemBuilder;

  const CollectibleGridSliver({
    super.key,
    required this.items,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, index) => itemBuilder(items[index]),
          childCount: items.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
        ),
      ),
    );
  }
}
