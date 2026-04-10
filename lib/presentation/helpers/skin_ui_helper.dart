import 'package:flutter/material.dart';

import '../../data/models/skin_dto.dart';
import '../../domain/special_item_variant_helper.dart';

class SkinUiHelper {
  static Color rarityColor(SkinDto skin) {
    if (skin.isSpecialItem) return Colors.amber;

    switch (skin.rarity) {
      case 'CONSUMER':
        return Colors.grey;
      case 'INDUSTRIAL':
        return Colors.lightBlueAccent;
      case 'MIL_SPEC':
        return Colors.blue;
      case 'RESTRICTED':
        return Colors.purple;
      case 'CLASSIFIED':
        return Colors.pink;
      case 'COVERT':
        return Colors.red;
      case 'CONTRABAND':
        return const Color(0xFFFF8A00);
      case 'EXTRAORDINARY':
        return Colors.amber;
      default:
        return Colors.white24;
    }
  }

  static String rarityLabel(SkinDto skin) {
    if (skin.isSpecialItem) return 'Special Item';

    switch (skin.rarity) {
      case 'CONSUMER':
        return 'Consumer';
      case 'INDUSTRIAL':
        return 'Industrial';
      case 'MIL_SPEC':
        return 'Mil-Spec';
      case 'RESTRICTED':
        return 'Restricted';
      case 'CLASSIFIED':
        return 'Classified';
      case 'COVERT':
        return 'Covert';
      case 'CONTRABAND':
        return 'Contraband';
      case 'EXTRAORDINARY':
        return 'Extraordinary';
      default:
        return skin.rarity;
    }
  }

  static String weaponTypeLabel(String type) {
    switch (type) {
      case 'PISTOL':
        return 'Pistol';
      case 'SMG':
        return 'SMG';
      case 'SNIPER_RIFLE':
        return 'Sniper Rifle';
      case 'RIFLE':
        return 'Rifle';
      case 'KNIFE':
        return 'Knife';
      case 'SHOTGUN':
        return 'Shotgun';
      case 'MACHINE_GUN':
        return 'Machine Gun';
      case 'GLOVES':
        return 'Gloves';
      case 'EQUIPMENT':
        return 'Equipment';
      default:
        return type;
    }
  }

  static String secondaryText(SkinDto skin) {
    final variant = skin.displayVariant;
    if (variant != null && variant.isNotEmpty) {
      return '${skin.name} - $variant';
    }
    return skin.name;
  }

  static String familySecondaryText(List<SkinDto> variants) {
    if (variants.isEmpty) {
      return '';
    }

    final primary = variants.first;
    final hasWeightedVariants =
        variants.length > 1 &&
        SpecialItemVariantHelper.hasConfiguredVariantWeights(variants);

    if (!hasWeightedVariants) {
      return secondaryText(primary);
    }

    return primary.name;
  }

  static String? familyDetailText(List<SkinDto> variants) {
    final hasWeightedVariants =
        variants.length > 1 &&
        SpecialItemVariantHelper.hasConfiguredVariantWeights(variants);
    if (!hasWeightedVariants) {
      return null;
    }

    final count = variants.length;
    final labels = variants
        .map((variant) => variant.displayVariant?.trim())
        .whereType<String>()
        .where((label) => label.isNotEmpty)
        .toList();

    if (labels.isEmpty) {
      return '$count finish variants';
    }

    return count <= 3 ? labels.join(', ') : '$count finish variants';
  }

  static String fullDropDisplayName({
    required SkinDto skin,
    required bool isStatTrak,
    required bool isSouvenir,
  }) {
    final star = skin.isSpecialItem ? '\u2605 ' : '';
    final souvenirPrefix = isSouvenir ? 'Souvenir ' : '';
    final statTrakPrefix = isStatTrak ? 'StatTrak\u2122 ' : '';
    return '$star$souvenirPrefix$statTrakPrefix${skin.itemDisplayName} | ${skin.name}';
  }
}
