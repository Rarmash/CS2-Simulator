import 'package:flutter/material.dart';

import '../../data/models/graffiti_dto.dart';

class GraffitiUiHelper {
  static const Color _base = Color(0xFFB0C3D9);
  static const Color _blue = Color(0xFF4B69FF);
  static const Color _purple = Color(0xFF8847FF);
  static const Color _pink = Color(0xFFD32CE6);

  static Color rarityColor(GraffitiDto graffiti) {
    switch (graffiti.rarity) {
      case 'HIGH_GRADE':
        return _blue;
      case 'REMARKABLE':
        return _purple;
      case 'EXOTIC':
        return _pink;
      case 'BASE_GRADE':
      default:
        return _base;
    }
  }

  static String rarityLabel(GraffitiDto graffiti) {
    switch (graffiti.rarity) {
      case 'BASE_GRADE':
        return 'Base Grade';
      case 'HIGH_GRADE':
        return 'High Grade';
      case 'REMARKABLE':
        return 'Remarkable';
      case 'EXOTIC':
        return 'Exotic';
      default:
        return graffiti.rarity;
    }
  }

  static String secondaryText(GraffitiDto graffiti) {
    return graffiti.collection ?? 'Graffiti';
  }
}
