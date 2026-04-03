import 'package:flutter/material.dart';

import 'opening_roller.dart';

class CollectibleRollerSliver<T> extends StatelessWidget {
  final ScrollController controller;
  final List<T> items;
  final int winningIndex;
  final bool isRolling;
  final Widget Function(T item, bool isWinner, double itemWidth) itemBuilder;

  const CollectibleRollerSliver({
    super.key,
    required this.controller,
    required this.items,
    required this.winningIndex,
    required this.isRolling,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: OpeningRoller<T>(
        controller: controller,
        items: items,
        winningIndex: winningIndex,
        isRolling: isRolling,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
