import 'dart:math';

import '../data/models/skin_dto.dart';

class SpecialItemVariantHelper {
  static const _dopplerWeights = <String, double>{
    'Phase 1': 22.5,
    'Phase 2': 22.5,
    'Phase 3': 22.5,
    'Phase 4': 22.5,
    'Ruby': 4.0,
    'Sapphire': 4.0,
    'Black Pearl': 2.0,
  };

  static const _gammaDopplerWeights = <String, double>{
    'Phase 1': 23.0,
    'Phase 2': 23.0,
    'Phase 3': 23.0,
    'Phase 4': 23.0,
    'Emerald': 8.0,
  };

  static List<List<SkinDto>> groupFamilies(Iterable<SkinDto> skins) {
    final grouped = <String, List<SkinDto>>{};
    for (final skin in skins) {
      grouped.putIfAbsent(familyKeyForSkin(skin), () => <SkinDto>[]).add(skin);
    }

    final families = grouped.values
        .map((items) => List<SkinDto>.from(items)..sort(_compareVariants))
        .toList();
    families.sort((a, b) => _familyKey(a.first).compareTo(_familyKey(b.first)));
    return families;
  }

  static Map<String, double> variantProbabilities(List<SkinDto> variants) {
    if (variants.isEmpty) {
      return const {};
    }

    final finish = (variants.first.finishCatalogName ?? '')
        .trim()
        .toUpperCase();
    final configured = switch (finish) {
      'DOPPLER' => _dopplerWeights,
      'GAMMA DOPPLER' => _gammaDopplerWeights,
      _ => null,
    };

    if (configured == null) {
      final uniform = 1 / variants.length;
      return {for (final variant in variants) variant.id: uniform};
    }

    final rawWeights = <String, double>{};
    for (final variant in variants) {
      final label = (variant.displayVariant ?? '').trim();
      rawWeights[variant.id] = configured[label] ?? 0;
    }

    final total = rawWeights.values.fold<double>(0, (sum, item) => sum + item);
    if (total <= 0) {
      final uniform = 1 / variants.length;
      return {for (final variant in variants) variant.id: uniform};
    }

    return {
      for (final entry in rawWeights.entries) entry.key: entry.value / total,
    };
  }

  static SkinDto rollVariant(Random random, List<SkinDto> variants) {
    final probabilities = variantProbabilities(variants);
    if (probabilities.isEmpty) {
      return variants.first;
    }

    final roll = random.nextDouble();
    double cumulative = 0;
    for (final variant in variants) {
      cumulative += probabilities[variant.id] ?? 0;
      if (roll <= cumulative) {
        return variant;
      }
    }

    return variants.last;
  }

  static String familyKeyForSkin(SkinDto skin) => _familyKey(skin);

  static String _familyKey(SkinDto skin) {
    return [
      skin.itemKind,
      skin.itemId,
      skin.name.trim().toLowerCase(),
      (skin.finishCatalogName ?? '').trim().toLowerCase(),
    ].join('|');
  }

  static int _compareVariants(SkinDto a, SkinDto b) {
    final phaseCompare = _variantOrder(a).compareTo(_variantOrder(b));
    if (phaseCompare != 0) {
      return phaseCompare;
    }
    return int.parse(a.id).compareTo(int.parse(b.id));
  }

  static int _variantOrder(SkinDto skin) {
    return switch ((skin.displayVariant ?? '').trim()) {
      '' => 0,
      'Phase 1' => 1,
      'Phase 2' => 2,
      'Phase 3' => 3,
      'Phase 4' => 4,
      'Ruby' => 5,
      'Sapphire' => 6,
      'Black Pearl' => 7,
      'Emerald' => 8,
      _ => 100,
    };
  }
}
