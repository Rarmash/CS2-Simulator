import 'package:flutter/material.dart';

import '../../data/models/charm_dto.dart';

class CharmUiHelper {
  static const Color _blue = Color(0xFF4B69FF);
  static const Color _purple = Color(0xFF8847FF);
  static const Color _red = Color(0xFFEB4B4B);
  static const Color _pink = Color(0xFFD32CE6);

  static Color rarityColor(CharmDto charm) {
    switch (charm.rarity) {
      case 'REMARKABLE':
        return _purple;
      case 'EXTRAORDINARY':
        return _red;
      case 'EXOTIC':
        return _pink;
      case 'HIGH_GRADE':
      default:
        return _blue;
    }
  }

  static String rarityLabel(CharmDto charm) {
    switch (charm.rarity) {
      case 'HIGH_GRADE':
        return 'High Grade';
      case 'REMARKABLE':
        return 'Remarkable';
      case 'EXTRAORDINARY':
        return 'Extraordinary';
      case 'EXOTIC':
        return 'Exotic';
      default:
        return charm.rarity;
    }
  }

  static String secondaryText(CharmDto charm) {
    return charm.collection ?? 'Charm';
  }
}
