import 'package:flutter/material.dart';

import '../../domain/dropped_charm.dart';
import '../helpers/charm_ui_helper.dart';
import 'collectible_drop_card.dart';

class CharmDropCard extends StatelessWidget {
  final DroppedCharm drop;

  const CharmDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = CharmUiHelper.rarityColor(drop.charm);

    return CollectibleDropCard(
      imagePath: drop.charm.charmImage,
      title: drop.charm.name,
      subtitle: CharmUiHelper.secondaryText(drop.charm),
      accentColor: rarityColor,
      entries: [
        CollectibleInfoEntry(
          title: 'Rarity',
          value: CharmUiHelper.rarityLabel(drop.charm),
          valueColor: rarityColor,
        ),
        const CollectibleInfoEntry(title: 'Type', value: 'Charm'),
        if ((drop.charm.collection ?? '').isNotEmpty)
          CollectibleInfoEntry(
            title: 'Collection',
            value: drop.charm.collection!,
          ),
      ],
    );
  }
}
