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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return builder(context, List<T>.from(snapshot.data!));
      },
    );
  }
}
