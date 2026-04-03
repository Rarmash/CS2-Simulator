import 'package:flutter/material.dart';

class CollectibleDetailsCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final List<Widget> tags;
  final List<Widget> infoRows;

  const CollectibleDetailsCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.infoRows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 700;

            final image = Container(
              alignment: Alignment.center,
              child: Image.asset(
                imagePath,
                height: narrow ? 150 : 200,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
                isAntiAlias: false,
                gaplessPlayback: true,
                cacheWidth: narrow ? 420 : 640,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported, size: 64),
              ),
            );

            final info = Column(
              crossAxisAlignment: narrow
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: narrow ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: narrow ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags,
                  ),
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
                  image,
                  const SizedBox(height: 16),
                  info,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: image),
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
