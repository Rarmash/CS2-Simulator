import 'dart:math';

import '../data/models/case_dto.dart';
import '../data/models/skin_dto.dart';
import 'case_odds.dart';
import 'dropped_skin.dart';
import 'package_odds.dart';
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

    final SkinDto selectedSkin;
    if (caseDto.isSouvenirPackage || caseDto.isCollectionPackage) {
      selectedSkin = _selectPackageSkin(skins);
    } else {
      selectedSkin = _selectCaseSkin(skins);
    }

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
      final skin = _selectTerminalSkin(skins);

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
    final odds = _getRandomCaseOdds();
    final filtered = _filterCaseSkins(skins, odds);

    if (filtered.isEmpty) {
      throw Exception('No skins available for rarity: $odds');
    }

    return filtered[_random.nextInt(filtered.length)];
  }

  SkinDto _selectPackageSkin(List<SkinDto> skins) {
    final odds = _getRandomPackageOdds();
    final filtered = _filterPackageSkins(skins, odds);

    if (filtered.isEmpty) {
      final fallback = skins.where((s) => !s.isSpecialItem).toList();
      if (fallback.isEmpty) {
        throw Exception('No valid skins in package');
      }
      return fallback[_random.nextInt(fallback.length)];
    }

    return filtered[_random.nextInt(filtered.length)];
  }

  SkinDto _selectTerminalSkin(List<SkinDto> skins) {
    final odds = _getRandomTerminalOdds();
    final filtered = _filterTerminalSkins(skins, odds);

    if (filtered.isEmpty) {
      return skins[_random.nextInt(skins.length)];
    }

    return filtered[_random.nextInt(filtered.length)];
  }

  CaseOdds _getRandomCaseOdds() {
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

  PackageOdds _getRandomPackageOdds() {
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

  PackageOdds _getRandomTerminalOdds() {
    final randomValue = _random.nextDouble();

    if (randomValue < 0.7992327) return PackageOdds.milSpec;
    if (randomValue < 0.9590792) return PackageOdds.restricted;
    if (randomValue < 0.9910485) return PackageOdds.classified;
    return PackageOdds.covert;
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

  List<SkinDto> _filterPackageSkins(List<SkinDto> skins, PackageOdds odds) {
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

  List<SkinDto> _filterTerminalSkins(List<SkinDto> skins, PackageOdds odds) {
    switch (odds) {
      case PackageOdds.consumer:
      case PackageOdds.industrial:
        return const [];
      case PackageOdds.milSpec:
        return skins.where((s) => s.rarity == 'MIL_SPEC').toList();
      case PackageOdds.restricted:
        return skins.where((s) => s.rarity == 'RESTRICTED').toList();
      case PackageOdds.classified:
        return skins.where((s) => s.rarity == 'CLASSIFIED').toList();
      case PackageOdds.covert:
        return skins.where((s) =>
        s.rarity == 'COVERT' ||
            s.rarity == 'CONTRABAND' ||
            s.isSpecialItem).toList();
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
    return 'Battle-Scarred';
  }
}