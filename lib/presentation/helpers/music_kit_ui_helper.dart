import 'package:flutter/material.dart';

import '../../data/models/music_kit_dto.dart';

class MusicKitUiHelper {
  static Color rarityColor(MusicKitDto musicKit) {
    switch (musicKit.rarity) {
      case 'HIGH_GRADE':
        return Colors.blue;
      default:
        return Colors.white24;
    }
  }

  static String rarityLabel(MusicKitDto musicKit) {
    switch (musicKit.rarity) {
      case 'HIGH_GRADE':
        return 'High Grade';
      default:
        return musicKit.rarity;
    }
  }

  static String typeLabel(MusicKitDto musicKit) {
    return musicKit.isStatTrak ? 'StatTrak™ Music Kit' : 'Music Kit';
  }

  static String secondaryText(MusicKitDto musicKit) {
    final parts = <String>[typeLabel(musicKit)];
    final collection = (musicKit.collection ?? '').trim();
    if (collection.isNotEmpty) {
      parts.add(collection);
    }
    return parts.join(' | ');
  }
}
