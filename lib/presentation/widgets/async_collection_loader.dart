import 'package:flutter/material.dart';

class AsyncCollectionLoader<T> extends StatelessWidget {
  final Future<List<T>> future;
  final Widget Function(BuildContext context, List<T> items) builder;

  const AsyncCollectionLoader({
    super.key,
    required this.future,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load data:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return builder(context, List<T>.from(snapshot.data!));
      },
    );
  }
}
