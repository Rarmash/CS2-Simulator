import 'package:flutter/material.dart';

import 'info_row.dart';

class CollectibleInfoEntry {
  final String title;
  final String value;
  final Color? valueColor;

  const CollectibleInfoEntry({
    required this.title,
    required this.value,
    this.valueColor,
  });
}

class CollectibleDropCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final List<CollectibleInfoEntry> entries;

  const CollectibleDropCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.accentColor,
    required this.entries,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accentColor, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [accentColor.withValues(alpha: 0.18), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;

              final image = Image.asset(
                imagePath,
                height: isNarrow ? 120 : 160,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.image_not_supported, size: isNarrow ? 64 : 80),
              );

              final info = Column(
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      fontSize: isNarrow ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  if ((subtitle ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ...entries.map(
                    (entry) => InfoRow(
                      title: entry.title,
                      value: entry.value,
                      valueColor: entry.valueColor,
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [image, const SizedBox(height: 12), info],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 4, child: Center(child: image)),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: info),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
