import 'package:flutter/material.dart';

import '../../domain/dropped_sticker.dart';
import '../helpers/sticker_ui_helper.dart';
import 'collectible_drop_card.dart';

class StickerDropCard extends StatelessWidget {
  final DroppedSticker drop;

  const StickerDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = StickerUiHelper.rarityColor(drop.sticker);

    return CollectibleDropCard(
      imagePath: drop.sticker.stickerImage,
      title: drop.sticker.name,
      subtitle: StickerUiHelper.secondaryText(drop.sticker),
      accentColor: rarityColor,
      entries: [
        CollectibleInfoEntry(
          title: 'Rarity',
          value: StickerUiHelper.rarityLabel(drop.sticker),
          valueColor: rarityColor,
        ),
        CollectibleInfoEntry(
          title: 'Type',
          value: drop.sticker.stickerTypeLabel,
        ),
        CollectibleInfoEntry(
          title: 'Effect',
          value: StickerUiHelper.effectLabel(drop.sticker.effect),
        ),
        if ((drop.sticker.collection ?? '').isNotEmpty)
          CollectibleInfoEntry(
            title: 'Collection',
            value: drop.sticker.collection!,
          ),
        if ((drop.sticker.tournament ?? '').isNotEmpty)
          CollectibleInfoEntry(
            title: 'Tournament',
            value: drop.sticker.tournament!,
          ),
      ],
    );
  }
}
