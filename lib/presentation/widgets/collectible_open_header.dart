import 'package:flutter/material.dart';

import 'asset_collection_image.dart';

class CollectibleOpenHeader extends StatelessWidget {
  final String assetPath;
  final double imageHeight;
  final List<Widget> badges;
  final List<Widget> metadata;
  final String? releaseDateText;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const CollectibleOpenHeader({
    super.key,
    required this.assetPath,
    required this.imageHeight,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.badges = const [],
    this.metadata = const [],
    this.releaseDateText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          AssetCollectionImage(assetPath: assetPath, height: imageHeight),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: badges,
            ),
          ],
          for (final widget in metadata) widget,
          if (releaseDateText != null) ...[
            const SizedBox(height: 8),
            Text(
              'Released: $releaseDateText',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
