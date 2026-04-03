import 'package:flutter/material.dart';

import '../../data/models/patch_dto.dart';
import '../helpers/patch_ui_helper.dart';

class PatchGridTile extends StatelessWidget {
  final PatchDto patch;
  final bool highlighted;
  final int crossAxisCount;

  const PatchGridTile({
    super.key,
    required this.patch,
    required this.highlighted,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = PatchUiHelper.rarityColor(patch);
    final compact = crossAxisCount >= 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? rarityColor : Colors.white10,
          width: highlighted ? 2.5 : 1,
        ),
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
                  patch.patchImage,
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
                    patch.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 11 : 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PatchUiHelper.secondaryText(patch),
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
                    PatchUiHelper.rarityLabel(patch),
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
