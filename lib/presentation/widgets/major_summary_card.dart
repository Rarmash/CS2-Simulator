import 'package:flutter/material.dart';

class MajorSummaryCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final List<Widget> tags;
  final List<Widget> infoRows;

  const MajorSummaryCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.tags = const [],
    this.infoRows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 700;

            final info = Column(
              crossAxisAlignment: narrow
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: narrow ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    textAlign: narrow ? TextAlign.center : TextAlign.left,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: tags),
                ],
                if (infoRows.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...infoRows,
                ],
              ],
            );

            if (narrow) {
              return Column(
                children: [
                  Center(child: leading),
                  const SizedBox(height: 16),
                  info,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: Center(child: leading)),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: info),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MajorSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const MajorSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.amber.shade300),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((subtitle ?? '').trim().isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
