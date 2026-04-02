import 'package:flutter/material.dart';

class OpeningRollLayout {
  static const double rollItemGap = 10;
  static const double rollViewportPadding = 12;

  static double rollItemWidth(double viewportWidth) {
    final raw = viewportWidth * 0.18;
    return raw.clamp(120.0, 170.0);
  }

  static double computeTargetOffset({
    required int winningIndex,
    required double viewportWidth,
    required double itemWidth,
    required double maxScrollExtent,
  }) {
    final itemExtent = itemWidth + rollItemGap;
    final itemLeft = rollViewportPadding + winningIndex * itemExtent;
    final itemCenter = itemLeft + itemWidth / 2;
    final target = itemCenter - viewportWidth / 2;

    return target.clamp(0.0, maxScrollExtent);
  }
}

class OpeningRoller<T> extends StatelessWidget {
  final ScrollController controller;
  final List<T> items;
  final int winningIndex;
  final bool isRolling;
  final Widget Function(T item, bool isWinner, double itemWidth) itemBuilder;

  const OpeningRoller({
    super.key,
    required this.controller,
    required this.items,
    required this.winningIndex,
    required this.isRolling,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final itemWidth = OpeningRollLayout.rollItemWidth(viewportWidth);
        final rollerHeight = viewportWidth < 600 ? 190.0 : 228.0;
        final lineHeight = viewportWidth < 600 ? 160.0 : 200.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(
            height: rollerHeight,
            child: Stack(
              children: [
                ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: OpeningRollLayout.rollViewportPadding,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final isWinner = !isRolling && index == winningIndex;
                    return itemBuilder(item, isWinner, itemWidth);
                  },
                ),
                Positioned(
                  left: viewportWidth / 2 - 2,
                  top: (rollerHeight - lineHeight) / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: 4,
                      height: lineHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Colors.white38, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
