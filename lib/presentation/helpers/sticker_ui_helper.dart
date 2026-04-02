import 'package:flutter/material.dart';

import '../../data/models/sticker_dto.dart';

class StickerUiHelper {
  static Color rarityColor(StickerDto sticker) {
    switch (sticker.rarity) {
      case 'HIGH_GRADE':
        return Colors.blue;
      case 'REMARKABLE':
        return Colors.purple;
      case 'EXOTIC':
        return Colors.pink;
      case 'EXTRAORDINARY':
        return Colors.amber;
      case 'CONTRABAND':
        return const Color(0xFFFF8A00);
      default:
        return Colors.white24;
    }
  }

  static String rarityLabel(StickerDto sticker) {
    switch (sticker.rarity) {
      case 'HIGH_GRADE':
        return 'High Grade';
      case 'REMARKABLE':
        return 'Remarkable';
      case 'EXOTIC':
        return 'Exotic';
      case 'EXTRAORDINARY':
        return 'Extraordinary';
      case 'CONTRABAND':
        return 'Contraband';
      default:
        return sticker.rarity;
    }
  }

  static String secondaryText(StickerDto sticker) {
    final parts = <String>[];

    if (sticker.effect != 'OTHER') {
      parts.add(effectLabel(sticker.effect));
    }
    if ((sticker.collection ?? '').isNotEmpty) {
      parts.add(sticker.collection!);
    } else if ((sticker.tournament ?? '').isNotEmpty) {
      parts.add(sticker.tournament!);
    }

    if (parts.isEmpty) {
      return sticker.stickerTypeLabel;
    }

    return parts.join(' • ');
  }

  static String effectLabel(String effect) {
    switch (effect) {
      case 'FOIL':
        return 'Foil';
      case 'HOLO':
        return 'Holo';
      case 'GOLD':
        return 'Gold';
      case 'GLITTER':
        return 'Glitter';
      case 'EMBROIDERED':
        return 'Embroidered';
      case 'LENTICULAR':
        return 'Lenticular';
      default:
        return 'Standard';
    }
  }
}
