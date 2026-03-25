import 'package:flutter/material.dart';

import '../../data/models/skin_dto.dart';
import '../helpers/skin_ui_helper.dart';

class SkinGridTile extends StatelessWidget {
  final SkinDto skin;
  final bool highlighted;
  final int crossAxisCount;

  const SkinGridTile({
    super.key,
    required this.skin,
    this.highlighted = false,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = SkinUiHelper.rarityColor(skin);
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
            color: rarityColor.withOpacity(0.45),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: highlighted ? rarityColor.withOpacity(0.12) : null,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(compact ? 6 : 8),
                child: Image.asset(
                  skin.skinImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            Container(
              height: 5,
              color: rarityColor,
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 6 : 8),
              child: Column(
                children: [
                  Text(
                    skin.itemDisplayName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 11 : 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    SkinUiHelper.secondaryText(skin),
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
                    SkinUiHelper.rarityLabel(skin),
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (skin.collection != null &&
                      skin.collection!.isNotEmpty &&
                      !compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      skin.collection!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}