import 'dart:math';

import '../data/models/operation_collection_dto.dart';
import '../data/models/skin_dto.dart';
import 'dropped_skin.dart';
import 'package_odds.dart';

class OperationCollectionSimulatorService {
  final Random _random = Random();

  DroppedSkin openCollection({
    required List<SkinDto> skins,
    required OperationCollectionDto collection,
  }) {
    if (skins.isEmpty) {
      throw Exception('No skins found for operation collection');
    }

    final selectedSkin = _selectSkin(skins);
    final floatValue = _generateFloat(
      selectedSkin.floatTop,
      selectedSkin.floatBottom,
    );

    return DroppedSkin(
      skin: selectedSkin,
      isStatTrak: false,
      isSouvenir: false,
      skinFloat: floatValue,
      exterior: _getExterior(floatValue),
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

  double _generateFloat(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  String _getExterior(double value) {
    if (value <= 0.07) return 'Factory New';
    if (value <= 0.15) return 'Minimal Wear';
    if (value <= 0.37) return 'Field-Tested';
    if (value <= 0.44) return 'Well-Worn';
    return 'Battle-Scarred';
  }
}