import 'dart:math';

import '../data/models/case_dto.dart';
import '../data/models/skin_dto.dart';
import 'case_odds.dart';
import 'dropped_skin.dart';
import 'terminal_offer.dart';

class CaseSimulatorService {
  final Random _random = Random();

  DroppedSkin openCase({
    required List<SkinDto> skins,
    required CaseDto caseDto,
  }) {
    if (skins.isEmpty) {
      throw Exception('No skins found for container');
    }

    if (caseDto.isTerminal) {
      throw Exception('Use buildTerminalOffers() for terminal containers');
    }

    if (caseDto.isXrayPackage) {
      final guaranteedSkin = skins.first;
      final floatValue = _generateFloat(
        guaranteedSkin.floatTop,
        guaranteedSkin.floatBottom,
      );

      return DroppedSkin(
        skin: guaranteedSkin,
        isStatTrak: false,
        isSouvenir: false,
        skinFloat: floatValue,
        exterior: _getExterior(floatValue),
      );
    }

    final selectedSkin = caseDto.isCollectionPackage
        ? _selectCollectionLikeSkin(skins)
        : _selectCaseSkin(skins);

    final isSouvenir = caseDto.isSouvenirPackage;
    final isStatTrak = caseDto.isRegularCase &&
        !selectedSkin.isGloves &&
        !selectedSkin.isKnife &&
        _generateStatTrak();

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
      isSouvenir: isSouvenir,
      skinFloat: value,
      exterior: exterior,
    );
  }

  List<TerminalOffer> buildTerminalOffers({
    required List<SkinDto> skins,
    int count = 5,
  }) {
    if (skins.isEmpty) {
      throw Exception('No skins found for terminal');
    }

    return List.generate(count, (index) {
      final skin = _selectCollectionLikeSkin(skins);

      final canRollStatTrak = !skin.isGloves;
      final isStatTrak = canRollStatTrak && _generateStatTrak();

      final isVanillaKnife = skin.isKnife && skin.name == 'Vanilla';

      double? value;
      String? exterior;

      if (!isVanillaKnife) {
        value = _generateFloat(skin.floatTop, skin.floatBottom);
        exterior = _getExterior(value);
      }

      return TerminalOffer(
        skin: skin,
        isStatTrak: isStatTrak,
        skinFloat: value,
        exterior: exterior,
        offerIndex: index + 1,
      );
    });
  }

  SkinDto _selectCaseSkin(List<SkinDto> skins) {
    final odds = _getRandomOdds();
    final filtered = _filterCaseSkins(skins, odds);

    if (filtered.isEmpty) {
      throw Exception('No skins available for rarity: $odds');
    }

    return filtered[_random.nextInt(filtered.length)];
  }

  SkinDto _selectCollectionLikeSkin(List<SkinDto> skins) {
    final odds = _getRandomCollectionOdds();
    final filtered = _filterCollectionLikeSkins(skins, odds);

    if (filtered.isEmpty) {
      final nonSpecial = skins.where((s) => !s.isSpecialItem).toList();
      if (nonSpecial.isEmpty) {
        throw Exception('No valid skins in container');
      }
      return nonSpecial[_random.nextInt(nonSpecial.length)];
    }

    return filtered[_random.nextInt(filtered.length)];
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

  CaseOdds _getRandomCollectionOdds() {
    final randomValue = _random.nextDouble();

    if (randomValue < 0.7992327) return CaseOdds.milSpec;
    if (randomValue < 0.9590792) return CaseOdds.restricted;
    if (randomValue < 0.9910485) return CaseOdds.classified;
    return CaseOdds.covert;
  }

  List<SkinDto> _filterCaseSkins(List<SkinDto> skins, CaseOdds odds) {
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

  List<SkinDto> _filterCollectionLikeSkins(List<SkinDto> skins, CaseOdds odds) {
    switch (odds) {
      case CaseOdds.milSpec:
        return skins.where((s) => s.rarity == 'MIL_SPEC').toList();
      case CaseOdds.restricted:
        return skins.where((s) => s.rarity == 'RESTRICTED').toList();
      case CaseOdds.classified:
        return skins.where((s) => s.rarity == 'CLASSIFIED').toList();
      case CaseOdds.covert:
        return skins.where((s) =>
        s.rarity == 'COVERT' ||
            s.rarity == 'CONTRABAND' ||
            s.isSpecialItem).toList();
      case CaseOdds.specialItem:
        return const [];
    }
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