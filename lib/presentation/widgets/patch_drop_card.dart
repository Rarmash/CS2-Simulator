import 'package:flutter/material.dart';

import '../../domain/dropped_patch.dart';
import '../helpers/patch_ui_helper.dart';
import 'collectible_drop_card.dart';

class PatchDropCard extends StatelessWidget {
  final DroppedPatch drop;

  const PatchDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = PatchUiHelper.rarityColor(drop.patch);
    final collectionText = PatchUiHelper.secondaryText(drop.patch);

    return CollectibleDropCard(
      imagePath: drop.patch.patchImage,
      title: drop.patch.name,
      subtitle: collectionText != drop.patch.name ? collectionText : null,
      accentColor: rarityColor,
      entries: [
        CollectibleInfoEntry(
          title: 'Rarity',
          value: PatchUiHelper.rarityLabel(drop.patch),
          valueColor: rarityColor,
        ),
        const CollectibleInfoEntry(title: 'Type', value: 'Patch'),
        if ((drop.patch.collection ?? '').isNotEmpty)
          CollectibleInfoEntry(
            title: 'Collection',
            value: drop.patch.collection!,
          ),
      ],
    );
  }
}
