import 'package:flutter/material.dart';

import '../../domain/dropped_graffiti.dart';
import '../helpers/graffiti_ui_helper.dart';
import 'collectible_drop_card.dart';

class GraffitiDropCard extends StatelessWidget {
  final DroppedGraffiti drop;

  const GraffitiDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = GraffitiUiHelper.rarityColor(drop.graffiti);
    final collectionText = GraffitiUiHelper.secondaryText(drop.graffiti);

    return CollectibleDropCard(
      imagePath: drop.graffiti.graffitiImage,
      title: drop.graffiti.name,
      subtitle: collectionText != drop.graffiti.name ? collectionText : null,
      accentColor: rarityColor,
      entries: [
        CollectibleInfoEntry(
          title: 'Rarity',
          value: GraffitiUiHelper.rarityLabel(drop.graffiti),
          valueColor: rarityColor,
        ),
        const CollectibleInfoEntry(title: 'Type', value: 'Graffiti'),
        if ((drop.graffiti.collection ?? '').isNotEmpty)
          CollectibleInfoEntry(
            title: 'Collection',
            value: drop.graffiti.collection!,
          ),
      ],
    );
  }
}
