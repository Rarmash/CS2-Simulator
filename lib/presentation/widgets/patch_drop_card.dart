import 'package:flutter/material.dart';

import '../../domain/dropped_patch.dart';
import '../helpers/patch_ui_helper.dart';
import 'info_row.dart';

class PatchDropCard extends StatelessWidget {
  final DroppedPatch drop;

  const PatchDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = PatchUiHelper.rarityColor(drop.patch);
    final collectionText = PatchUiHelper.secondaryText(drop.patch);

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
            colors: [rarityColor.withOpacity(0.18), Colors.transparent],
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
                drop.patch.patchImage,
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
                    drop.patch.name,
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      fontSize: isNarrow ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: rarityColor,
                    ),
                  ),
                  if (collectionText != drop.patch.name) ...[
                    const SizedBox(height: 6),
                    Text(
                      collectionText,
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
                    value: PatchUiHelper.rarityLabel(drop.patch),
                    valueColor: rarityColor,
                  ),
                  InfoRow(title: 'Type', value: 'Patch'),
                  if (drop.patch.collection != null &&
                      drop.patch.collection!.isNotEmpty)
                    InfoRow(
                      title: 'Collection',
                      value: drop.patch.collection!,
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
