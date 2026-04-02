import 'package:flutter/material.dart';

import '../../domain/dropped_pin.dart';
import '../helpers/pin_ui_helper.dart';
import 'collectible_drop_card.dart';

class PinDropCard extends StatelessWidget {
  final DroppedPin drop;

  const PinDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = PinUiHelper.rarityColor(drop.pin);

    return CollectibleDropCard(
      imagePath: drop.pin.pinImage,
      title: drop.pin.name,
      subtitle: PinUiHelper.secondaryText(drop.pin),
      accentColor: rarityColor,
      entries: [
        CollectibleInfoEntry(
          title: 'Rarity',
          value: PinUiHelper.rarityLabel(drop.pin),
          valueColor: rarityColor,
        ),
        const CollectibleInfoEntry(title: 'Type', value: 'Collectible Pin'),
        if ((drop.pin.collection ?? '').isNotEmpty)
          CollectibleInfoEntry(title: 'Series', value: drop.pin.collection!),
      ],
    );
  }
}
