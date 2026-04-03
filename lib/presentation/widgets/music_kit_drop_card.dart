import 'package:flutter/material.dart';

import '../../domain/dropped_music_kit.dart';
import '../helpers/music_kit_ui_helper.dart';
import 'collectible_drop_card.dart';

class MusicKitDropCard extends StatelessWidget {
  final DroppedMusicKit drop;

  const MusicKitDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = MusicKitUiHelper.rarityColor(drop.musicKit);

    return CollectibleDropCard(
      imagePath: drop.musicKit.musicKitImage,
      title: drop.musicKit.displayName,
      subtitle: MusicKitUiHelper.secondaryText(drop.musicKit),
      accentColor: rarityColor,
      entries: [
        CollectibleInfoEntry(
          title: 'Rarity',
          value: MusicKitUiHelper.rarityLabel(drop.musicKit),
          valueColor: rarityColor,
        ),
        CollectibleInfoEntry(
          title: 'Type',
          value: MusicKitUiHelper.typeLabel(drop.musicKit),
        ),
        if ((drop.musicKit.collection ?? '').isNotEmpty)
          CollectibleInfoEntry(title: 'Series', value: drop.musicKit.collection!),
      ],
    );
  }
}
