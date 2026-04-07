import 'dart:math';

import '../data/models/container_dto.dart';
import '../data/models/skin_dto.dart';
import 'case_odds.dart';
import 'dropped_skin.dart';
import 'package_odds.dart';
import 'skin_float_helper.dart';
import 'skin_pattern_helper.dart';
import 'special_item_variant_helper.dart';
import 'terminal_offer.dart';

class ContainerSimulatorService {
  final Random _random = Random();

  DroppedSkin openCase({
    required List<SkinDto> skins,
    required ContainerDto containerDto,
  }) {
    if (skins.isEmpty) {
      throw Exception('No skins found for container');
    }

    if (containerDto.isTerminal) {
      throw Exception('Use buildTerminalOffers() for terminal containers');
    }

    if (containerDto.isXrayPackage) {
      final guaranteedSkin = skins.first;
      final wear = SkinFloatHelper.generateWear(
        random: _random,
        minFloat: guaranteedSkin.floatTop,
        maxFloat: guaranteedSkin.floatBottom,
      );

      return DroppedSkin(
        skin: guaranteedSkin,
        isStatTrak: false,
        isSouvenir: false,
        skinFloat: wear.floatValue,
        exterior: wear.exterior,
        patternSeed: SkinPatternHelper.generateSeed(
          random: _random,
          skin: guaranteedSkin,
        ),
      );
    }

    final SkinDto selectedSkin;
    if (containerDto.isSouvenirPackage || containerDto.isCollectionPackage) {
      selectedSkin = _selectPackageSkin(skins);
    } else {
      selectedSkin = _selectCaseSkin(skins);
    }

    final isSouvenir = containerDto.isSouvenirPackage;
    final isStatTrak =
        containerDto.isRegularCase &&
        !selectedSkin.isGloves &&
        !selectedSkin.isKnife &&
        _generateStatTrak();

    final isVanillaKnife =
        selectedSkin.isKnife && selectedSkin.name == 'Vanilla';

    double? value;
    String? exterior;

    if (!isVanillaKnife) {
      final wear = SkinFloatHelper.generateWear(
        random: _random,
        minFloat: selectedSkin.floatTop,
        maxFloat: selectedSkin.floatBottom,
      );
      value = wear.floatValue;
      exterior = wear.exterior;
    }

    return DroppedSkin(
      skin: selectedSkin,
      isStatTrak: isStatTrak,
      isSouvenir: isSouvenir,
      skinFloat: value,
      exterior: exterior,
      patternSeed: SkinPatternHelper.generateSeed(
        random: _random,
        skin: selectedSkin,
      ),
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
        final wear = SkinFloatHelper.generateWear(
          random: _random,
          minFloat: skin.floatTop,
          maxFloat: skin.floatBottom,
        );
        value = wear.floatValue;
        exterior = wear.exterior;
      }

      return TerminalOffer(
        skin: skin,
        isStatTrak: isStatTrak,
        skinFloat: value,
        exterior: exterior,
        patternSeed: SkinPatternHelper.generateSeed(
          random: _random,
          skin: skin,
        ),
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

    if (odds == CaseOdds.specialItem) {
      return _selectSpecialItemSkin(filtered);
    }

    return filtered[_random.nextInt(filtered.length)];
  }

  SkinDto _selectSpecialItemSkin(List<SkinDto> skins) {
    final families = SpecialItemVariantHelper.groupFamilies(skins);
    if (families.isEmpty) {
      throw Exception('No special items available');
    }

    final family = families[_random.nextInt(families.length)];
    return SpecialItemVariantHelper.rollVariant(_random, family);
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
          final specialLike =
              s.rarity == 'COVERT' || s.rarity == 'EXTRAORDINARY';
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
        return skins
            .where(
              (s) =>
                  s.rarity == 'COVERT' ||
                  s.rarity == 'CONTRABAND' ||
                  s.isSpecialItem,
            )
            .toList();
    }
  }

  bool _generateStatTrak() => _random.nextInt(10) == 0;
}
