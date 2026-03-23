import 'dart:math';

import '../data/models/skin_dto.dart';
import 'case_odds.dart';
import 'dropped_skin.dart';

class CaseSimulatorService {
  final Random _random = Random();

  DroppedSkin openCase(List<SkinDto> skins) {
    final odds = _getRandomOdds();
    final selectedSkin = _selectSkin(skins, odds);

    final isStatTrak = !selectedSkin.isGloves && _generateStatTrak();
    final isVanillaKnife = selectedSkin.isKnife && selectedSkin.name == 'Vanilla';

    double? value;
    String? exterior;

    if (!isVanillaKnife) {
      value = _generateFloat(selectedSkin.floatTop, selectedSkin.floatBottom);
      exterior = _getExterior(value);
    }

    return DroppedSkin(
      skin: selectedSkin,
      isStatTrak: isStatTrak,
      skinFloat: value,
      exterior: exterior,
    );
  }

  CaseOdds _getRandomOdds() {
    final randomValue = _random.nextDouble();
    double cumulative = 0.0;

    for (final odds in CaseOdds.values) {
      cumulative += odds.chance;
      if (randomValue <= cumulative) {
        return odds;
      }
    }
    return CaseOdds.milSpec;
  }

  List<SkinDto> _filterSkins(List<SkinDto> skins, CaseOdds odds) {
    switch (odds) {
      case CaseOdds.milSpec:
        return skins.where((s) => s.rarity == 'MIL_SPEC').toList();
      case CaseOdds.restricted:
        return skins.where((s) => s.rarity == 'RESTRICTED').toList();
      case CaseOdds.classified:
        return skins.where((s) => s.rarity == 'CLASSIFIED').toList();
      case CaseOdds.covert:
        return skins.where((s) {
          final covertLike = s.rarity == 'COVERT' || s.rarity == 'CONTRABAND';
          return covertLike && !s.isSpecialItem;
        }).toList();
      case CaseOdds.specialItem:
        return skins.where((s) {
          final specialLike = s.rarity == 'COVERT' || s.rarity == 'EXTRAORDINARY';
          return specialLike && s.isSpecialItem;
        }).toList();
    }
  }

  SkinDto _selectSkin(List<SkinDto> skins, CaseOdds odds) {
    final filtered = _filterSkins(skins, odds);
    return filtered[_random.nextInt(filtered.length)];
  }

  bool _generateStatTrak() => _random.nextInt(10) == 0;

  double _generateFloat(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  String _getExterior(double value) {
    if (value >= 0.00 && value <= 0.07) return 'Factory New';
    if (value > 0.07 && value <= 0.15) return 'Minimal Wear';
    if (value > 0.15 && value <= 0.37) return 'Field-Tested';
    if (value > 0.37 && value <= 0.44) return 'Well-Worn';
    if (value > 0.44 && value <= 1.00) return 'Battle-Scarred';
    throw ArgumentError('Float out of range: $value');
  }
}