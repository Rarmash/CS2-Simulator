import 'dart:math';

import '../data/models/container_dto.dart';
import '../data/models/skin_dto.dart';
import 'dropped_skin.dart';
import 'package_odds.dart';
import 'skin_float_helper.dart';

class OperationCollectionSimulatorService {
  final Random _random = Random();

  DroppedSkin openCollection({
    required List<SkinDto> skins,
    required ContainerDto collection,
  }) {
    if (skins.isEmpty) {
      throw Exception('No skins found for operation collection');
    }

    final selectedSkin = _selectSkin(skins);
    final wear = SkinFloatHelper.generateWear(
      random: _random,
      minFloat: selectedSkin.floatTop,
      maxFloat: selectedSkin.floatBottom,
    );

    return DroppedSkin(
      skin: selectedSkin,
      isStatTrak: false,
      isSouvenir: false,
      skinFloat: wear.floatValue,
      exterior: wear.exterior,
    );
  }

  SkinDto _selectSkin(List<SkinDto> skins) {
    final odds = _getRandomOdds();
    final filtered = _filterSkins(skins, odds);

    if (filtered.isEmpty) {
      final fallback = skins.where((s) => !s.isSpecialItem).toList();
      if (fallback.isEmpty) {
        throw Exception('No valid skins in operation collection');
      }
      return fallback[_random.nextInt(fallback.length)];
    }

    return filtered[_random.nextInt(filtered.length)];
  }

  PackageOdds _getRandomOdds() {
    final randomValue = _random.nextDouble();
    double cumulative = 0.0;

    for (final odds in PackageOdds.values) {
      cumulative += odds.chance;
      if (randomValue <= cumulative) {
        return odds;
      }
    }

    return PackageOdds.consumer;
  }

  List<SkinDto> _filterSkins(List<SkinDto> skins, PackageOdds odds) {
    final nonSpecial = skins.where((s) => !s.isSpecialItem).toList();

    switch (odds) {
      case PackageOdds.consumer:
        return nonSpecial.where((s) => s.rarity == 'CONSUMER').toList();
      case PackageOdds.industrial:
        return nonSpecial.where((s) => s.rarity == 'INDUSTRIAL').toList();
      case PackageOdds.milSpec:
        return nonSpecial.where((s) => s.rarity == 'MIL_SPEC').toList();
      case PackageOdds.restricted:
        return nonSpecial.where((s) => s.rarity == 'RESTRICTED').toList();
      case PackageOdds.classified:
        return nonSpecial.where((s) => s.rarity == 'CLASSIFIED').toList();
      case PackageOdds.covert:
        return nonSpecial.where((s) {
          return s.rarity == 'COVERT' || s.rarity == 'CONTRABAND';
        }).toList();
    }
  }
}
