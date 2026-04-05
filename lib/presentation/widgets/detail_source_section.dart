import 'package:flutter/material.dart';

class DetailSourceSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  const DetailSourceSection({
    super.key,
    required this.title,
    required this.items,
    required this.emptyText,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${items.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(emptyText, style: const TextStyle(color: Colors.white70))
            else
              ...items.map(itemBuilder),
          ],
        ),
      ),
    );
  }
}
