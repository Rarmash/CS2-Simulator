import 'package:flutter/material.dart';

import '../../domain/dropped_sticker.dart';
import '../helpers/sticker_ui_helper.dart';
import 'info_row.dart';

class StickerDropCard extends StatelessWidget {
  final DroppedSticker drop;

  const StickerDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = StickerUiHelper.rarityColor(drop.sticker);

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
            colors: [rarityColor.withValues(alpha: 0.18), Colors.transparent],
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
                drop.sticker.stickerImage,
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
                    drop.sticker.name,
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      fontSize: isNarrow ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: rarityColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    StickerUiHelper.secondaryText(drop.sticker),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  InfoRow(
                    title: 'Rarity',
                    value: StickerUiHelper.rarityLabel(drop.sticker),
                    valueColor: rarityColor,
                  ),
                  InfoRow(title: 'Type', value: drop.sticker.stickerTypeLabel),
                  InfoRow(
                    title: 'Effect',
                    value: StickerUiHelper.effectLabel(drop.sticker.effect),
                  ),
                  if ((drop.sticker.collection ?? '').isNotEmpty)
                    InfoRow(
                      title: 'Collection',
                      value: drop.sticker.collection!,
                    ),
                  if ((drop.sticker.tournament ?? '').isNotEmpty)
                    InfoRow(
                      title: 'Tournament',
                      value: drop.sticker.tournament!,
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
