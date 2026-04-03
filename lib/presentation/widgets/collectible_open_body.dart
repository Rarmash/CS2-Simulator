import 'package:flutter/material.dart';

import '../helpers/responsive_grid_helper.dart';

class CollectibleOpenBody<T> extends StatelessWidget {
  final Future<List<T>> future;
  final List<Widget> Function(
    BuildContext context,
    BoxConstraints constraints,
    List<T> items,
    int gridCount,
    double aspectRatio,
  )
  sliverBuilder;

  const CollectibleOpenBody({
    super.key,
    required this.future,
    required this.sliverBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final gridCount = ResponsiveGridHelper.skinGridCrossAxisCount(
              constraints.maxWidth,
            );
            final aspectRatio = ResponsiveGridHelper.skinGridChildAspectRatio(
              constraints.maxWidth,
            );

            return CustomScrollView(
              slivers: sliverBuilder(
                context,
                constraints,
                items,
                gridCount,
                aspectRatio,
              ),
            );
          },
        );
      },
    );
  }
}
