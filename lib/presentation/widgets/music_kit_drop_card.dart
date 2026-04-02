import 'package:flutter/material.dart';

import '../../domain/dropped_music_kit.dart';
import '../helpers/music_kit_ui_helper.dart';
import 'info_row.dart';

class MusicKitDropCard extends StatelessWidget {
  final DroppedMusicKit drop;

  const MusicKitDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = MusicKitUiHelper.rarityColor(drop.musicKit);

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
                drop.musicKit.musicKitImage,
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
                    drop.musicKit.displayName,
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      fontSize: isNarrow ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: rarityColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    MusicKitUiHelper.secondaryText(drop.musicKit),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  InfoRow(
                    title: 'Rarity',
                    value: MusicKitUiHelper.rarityLabel(drop.musicKit),
                    valueColor: rarityColor,
                  ),
                  InfoRow(
                    title: 'Type',
                    value: MusicKitUiHelper.typeLabel(drop.musicKit),
                  ),
                  if ((drop.musicKit.collection ?? '').isNotEmpty)
                    InfoRow(title: 'Series', value: drop.musicKit.collection!),
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
