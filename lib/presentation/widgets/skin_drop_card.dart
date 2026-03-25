import 'package:flutter/material.dart';

import '../../domain/dropped_skin.dart';
import '../helpers/skin_ui_helper.dart';
import 'info_row.dart';

class SkinDropCard extends StatelessWidget {
  final DroppedSkin drop;

  const SkinDropCard({
    super.key,
    required this.drop,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = SkinUiHelper.rarityColor(drop.skin);
    final variantText = SkinUiHelper.secondaryText(drop.skin);

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: rarityColor, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              rarityColor.withOpacity(0.18),
              Colors.transparent,
            ],
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
                drop.skin.skinImage,
                height: isNarrow ? 120 : 160,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported,
                  size: isNarrow ? 64 : 80,
                ),
              );

              final info = Column(
                crossAxisAlignment:
                isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    SkinUiHelper.fullDropDisplayName(
                      skin: drop.skin,
                      isStatTrak: drop.isStatTrak,
                      isSouvenir: drop.isSouvenir,
                    ),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      fontSize: isNarrow ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: rarityColor,
                    ),
                  ),
                  if (variantText != drop.skin.name) ...[
                    const SizedBox(height: 6),
                    Text(
                      variantText,
                      textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  InfoRow(
                    title: 'Rarity',
                    value: SkinUiHelper.rarityLabel(drop.skin),
                    valueColor: rarityColor,
                  ),
                  InfoRow(
                    title: 'Weapon type',
                    value: SkinUiHelper.weaponTypeLabel(drop.skin.weaponType),
                  ),
                  InfoRow(
                    title: 'Float',
                    value: drop.skinFloat?.toStringAsFixed(6) ?? '-',
                  ),
                  InfoRow(
                    title: 'Exterior',
                    value: drop.exterior ?? '-',
                  ),
                  if (drop.skin.collection != null &&
                      drop.skin.collection!.isNotEmpty)
                    InfoRow(
                      title: 'Collection',
                      value: drop.skin.collection!,
                    ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    image,
                    const SizedBox(height: 12),
                    info,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Center(child: image),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: info,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}