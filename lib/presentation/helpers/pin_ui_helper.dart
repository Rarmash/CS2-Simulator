import 'package:flutter/material.dart';

import '../../data/models/pin_dto.dart';

class PinUiHelper {
  static Color rarityColor(PinDto pin) {
    switch (pin.rarity) {
      case 'GENUINE':
        return const Color(0xFF4D7455);
      case 'HIGH_GRADE':
        return Colors.blue;
      case 'REMARKABLE':
        return Colors.purple;
      case 'EXOTIC':
        return Colors.pink;
      case 'EXTRAORDINARY':
        return const Color(0xFFEB4B4B);
      default:
        return Colors.white24;
    }
  }

  static String rarityLabel(PinDto pin) {
    switch (pin.rarity) {
      case 'GENUINE':
        return 'Genuine';
      case 'HIGH_GRADE':
        return 'High Grade';
      case 'REMARKABLE':
        return 'Remarkable';
      case 'EXOTIC':
        return 'Exotic';
      case 'EXTRAORDINARY':
        return 'Extraordinary';
      default:
        return pin.rarity;
    }
  }

  static String secondaryText(PinDto pin) {
    final collection = (pin.collection ?? '').trim();
    if (collection.isNotEmpty) {
      return collection;
    }
    return pin.rarity == 'GENUINE' ? 'Genuine Pin' : 'Collectible Pin';
  }
}
