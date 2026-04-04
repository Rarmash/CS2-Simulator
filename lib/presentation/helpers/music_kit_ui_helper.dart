import 'package:flutter/material.dart';

import '../../data/models/music_kit_dto.dart';
import '../../data/models/music_kit_group_dto.dart';

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
    if (musicKit.hasRegular && musicKit.hasStatTrak) {
      return 'Music Kit / StatTrak™';
    }
    if (musicKit.hasStatTrak) {
      return 'StatTrak™ Music Kit';
    }
    return 'Music Kit';
  }

  static String secondaryText(MusicKitDto musicKit) {
    final parts = <String>[
      typeLabel(musicKit),
      if (musicKit.hasRegular && musicKit.hasStatTrak) 'Both variants',
    ];
    final collection = (musicKit.collection ?? '').trim();
    if (collection.isNotEmpty) {
      parts.add(collection);
    }
    return parts.join(' | ');
  }

  static String groupedTypeLabel(MusicKitGroupDto group) {
    if (group.hasRegular && group.hasStatTrak) {
      return 'Music Kit / StatTrak™';
    }
    if (group.hasStatTrak) {
      return 'StatTrak™ Music Kit';
    }
    return 'Music Kit';
  }

  static String groupedSecondaryText(MusicKitGroupDto group) {
    final parts = <String>[
      if ((group.artist ?? '').isNotEmpty) group.artist!,
      groupedTypeLabel(group),
      if (group.hasRegular && group.hasStatTrak) 'Both variants',
      if ((group.collection ?? '').isNotEmpty) group.collection!,
    ];
    return parts.join(' | ');
  }
}
