import 'package:flutter/material.dart';

import '../../data/models/patch_dto.dart';

class PatchUiHelper {
  static const Color _blue = Color(0xFF4B69FF);
  static const Color _purple = Color(0xFF8847FF);
  static const Color _pink = Color(0xFFD32CE6);

  static Color rarityColor(PatchDto patch) {
    switch (patch.rarity) {
      case 'REMARKABLE':
        return _purple;
      case 'EXOTIC':
        return _pink;
      case 'HIGH_GRADE':
      default:
        return _blue;
    }
  }

  static String rarityLabel(PatchDto patch) {
    switch (patch.rarity) {
      case 'HIGH_GRADE':
        return 'High Grade';
      case 'REMARKABLE':
        return 'Remarkable';
      case 'EXOTIC':
        return 'Exotic';
      default:
        return patch.rarity;
    }
  }

  static String secondaryText(PatchDto patch) {
    return patch.collection ?? 'Patch';
  }
}
