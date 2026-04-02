import 'package:flutter/material.dart';

import '../../data/models/music_kit_dto.dart';
import '../helpers/music_kit_ui_helper.dart';

class MusicKitGridTile extends StatelessWidget {
  final MusicKitDto musicKit;
  final bool highlighted;
  final int crossAxisCount;

  const MusicKitGridTile({
    super.key,
    required this.musicKit,
    required this.highlighted,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = MusicKitUiHelper.rarityColor(musicKit);
    final compact = crossAxisCount >= 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? rarityColor : Colors.white10,
          width: highlighted ? 2.5 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: highlighted ? rarityColor.withValues(alpha: 0.12) : null,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(compact ? 10 : 12),
                child: Image.asset(
                  musicKit.musicKitImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            Container(height: 5, color: rarityColor),
            Padding(
              padding: EdgeInsets.all(compact ? 6 : 8),
              child: Column(
                children: [
                  Text(
                    musicKit.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 11 : 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MusicKitUiHelper.secondaryText(musicKit),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: compact ? 10 : 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MusicKitUiHelper.rarityLabel(musicKit),
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
