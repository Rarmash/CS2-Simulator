import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import 'asset_collection_image.dart';

class CollectionListCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String? releaseDate;
  final List<Widget> chips;
  final List<Widget> metadata;
  final VoidCallback onTap;

  const CollectionListCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.releaseDate,
    required this.chips,
    required this.metadata,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate =
    DateFormatHelper.formatReleaseDate(releaseDate);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 320;

              final image = AssetCollectionImage(
                assetPath: imagePath,
                fit: BoxFit.contain,
              );

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (chips.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips,
                    ),
                  if (chips.isNotEmpty) const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...metadata,
                  if (formattedReleaseDate != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Released: $formattedReleaseDate',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              );

              if (constraints.maxWidth < 500) {
                return Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: image,
                      ),
                    ),
                    Expanded(child: textBlock),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: image,
                    ),
                  ),
                  textBlock,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}