import 'package:flutter/material.dart';

import '../helpers/responsive_grid_helper.dart';

class ResponsiveCollectionGrid<T> extends StatelessWidget {
  final List<T> items;
  final String emptyMessage;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? header;

  const ResponsiveCollectionGrid({
    super.key,
    required this.items,
    required this.emptyMessage,
    required this.itemBuilder,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveGridHelper.listCrossAxisCount(
          constraints.maxWidth,
        );
        final aspectRatio = ResponsiveGridHelper.listChildAspectRatio(
          constraints.maxWidth,
        );

        final gridOrEmpty = items.isEmpty
            ? Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) =>
                    itemBuilder(context, items[index]),
              );

        if (header == null) {
          return gridOrEmpty;
        }

        return Column(
          children: [
            header!,
            Expanded(child: gridOrEmpty),
          ],
        );
      },
    );
  }
}
