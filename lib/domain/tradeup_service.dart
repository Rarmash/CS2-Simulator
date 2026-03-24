import 'dart:math';

import '../data/models/skin_dto.dart';

class TradeUpResult {
  final SkinDto skin;
  final double floatValue;
  final String exterior;

  const TradeUpResult({
    required this.skin,
    required this.floatValue,
    required this.exterior,
  });
}

class TradeUpChance {
  final SkinDto skin;
  final double probability; // 0..1

  const TradeUpChance({
    required this.skin,
    required this.probability,
  });
}

class TradeUpService {
  final Random _random = Random();

  TradeUpResult tradeUp({
    required List<SkinDto> input,
    required List<SkinDto> allSkins,
    required Map<String, List<String>> caseToSkinIds,
  }) {
    if (input.isEmpty) {
      throw Exception('No skins selected');
    }

    final rarity = input.first.rarity;

    if (input.any((s) => s.rarity != rarity)) {
      throw Exception('All skins must have same rarity');
    }

    if (input.any((s) => s.isSpecialItem)) {
      throw Exception('Knives and gloves are not allowed as input');
    }

    final isSpecialTrade = rarity == 'COVERT';

    if (isSpecialTrade) {
      if (input.length != 5) {
        throw Exception('Covert trade-up requires exactly 5 skins');
      }
      return _covertToSpecial(
        input: input,
        allSkins: allSkins,
        caseToSkinIds: caseToSkinIds,
      );
    }

    if (input.length != 10) {
      throw Exception('Trade-up requires exactly 10 skins');
    }

    final nextRarity = _nextRarity(rarity);

    final selectedCaseId = _weightedCaseChoice(
      input: input,
      caseToSkinIds: caseToSkinIds,
    );

    final possibleSkinIds = caseToSkinIds[selectedCaseId] ?? [];

    final possibleSkins = allSkins.where((s) {
      return possibleSkinIds.contains(s.id) &&
          s.rarity == nextRarity &&
          !s.isSpecialItem;
    }).toList();

    if (possibleSkins.isEmpty) {
      throw Exception('No skins found for next rarity in selected case');
    }

    final resultSkin = possibleSkins[_random.nextInt(possibleSkins.length)];
    final floatValue = _calculateOutputFloat(input, resultSkin);

    return TradeUpResult(
      skin: resultSkin,
      floatValue: floatValue,
      exterior: _getExterior(floatValue),
    );
  }

  List<TradeUpChance> getTradeUpChances({
    required List<SkinDto> input,
    required List<SkinDto> allSkins,
    required Map<String, List<String>> caseToSkinIds,
  }) {
    if (input.isEmpty) return const [];

    final rarity = input.first.rarity;

    if (input.any((s) => s.rarity != rarity)) return const [];
    if (input.any((s) => s.isSpecialItem)) return const [];

    final isSpecialTrade = rarity == 'COVERT';
    if (isSpecialTrade && input.length != 5) return const [];
    if (!isSpecialTrade && input.length != 10) return const [];

    final caseWeights = _buildCaseWeights(
      input: input,
      caseToSkinIds: caseToSkinIds,
    );

    final String targetRarity;
    final bool specialOnly;

    if (isSpecialTrade) {
      targetRarity = '';
      specialOnly = true;
    } else {
      targetRarity = _nextRarity(rarity);
      specialOnly = false;
    }

    final Map<String, double> skinProbabilityById = {};

    for (final entry in caseWeights.entries) {
      final caseId = entry.key;
      final caseProbability = entry.value;

      final possibleSkinIds = caseToSkinIds[caseId] ?? [];

      final possibleSkins = allSkins.where((s) {
        final inCase = possibleSkinIds.contains(s.id);
        if (!inCase) return false;

        if (specialOnly) {
          return s.isSpecialItem;
        }

        return s.rarity == targetRarity && !s.isSpecialItem;
      }).toList();

      if (possibleSkins.isEmpty) continue;

      final perSkinProbability = caseProbability / possibleSkins.length;

      for (final skin in possibleSkins) {
        skinProbabilityById[skin.id] =
            (skinProbabilityById[skin.id] ?? 0) + perSkinProbability;
      }
    }

    final skinById = {for (final s in allSkins) s.id: s};

    final chances = skinProbabilityById.entries
        .map((e) => TradeUpChance(
      skin: skinById[e.key]!,
      probability: e.value,
    ))
        .toList();

    chances.sort((a, b) => b.probability.compareTo(a.probability));
    return chances;
  }

  TradeUpResult _covertToSpecial({
    required List<SkinDto> input,
    required List<SkinDto> allSkins,
    required Map<String, List<String>> caseToSkinIds,
  }) {
    final selectedCaseId = _weightedCaseChoice(
      input: input,
      caseToSkinIds: caseToSkinIds,
    );

    final possibleSkinIds = caseToSkinIds[selectedCaseId] ?? [];

    final possibleSkins = allSkins.where((s) {
      return possibleSkinIds.contains(s.id) && s.isSpecialItem;
    }).toList();

    if (possibleSkins.isEmpty) {
      throw Exception('No knives/gloves found in selected case');
    }

    final resultSkin = possibleSkins[_random.nextInt(possibleSkins.length)];
    final floatValue = _calculateOutputFloat(input, resultSkin);

    return TradeUpResult(
      skin: resultSkin,
      floatValue: floatValue,
      exterior: _getExterior(floatValue),
    );
  }

  double _calculateOutputFloat(List<SkinDto> input, SkinDto resultSkin) {
    final avgFloat = input
        .map((s) => (s.floatTop + s.floatBottom) / 2)
        .reduce((a, b) => a + b) /
        input.length;

    return resultSkin.floatTop +
        avgFloat * (resultSkin.floatBottom - resultSkin.floatTop);
  }

  String _nextRarity(String rarity) {
    switch (rarity) {
      case 'MIL_SPEC':
        return 'RESTRICTED';
      case 'RESTRICTED':
        return 'CLASSIFIED';
      case 'CLASSIFIED':
        return 'COVERT';
      default:
        throw Exception('Trade-up is supported only up to Classified -> Covert');
    }
  }

  String? _findCaseId(String skinId, Map<String, List<String>> map) {
    for (final entry in map.entries) {
      if (entry.value.contains(skinId)) {
        return entry.key;
      }
    }
    return null;
  }

  Map<String, double> _buildCaseWeights({
    required List<SkinDto> input,
    required Map<String, List<String>> caseToSkinIds,
  }) {
    final counts = <String, int>{};

    for (final skin in input) {
      final caseId = _findCaseId(skin.id, caseToSkinIds);
      if (caseId == null) continue;
      counts[caseId] = (counts[caseId] ?? 0) + 1;
    }

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      throw Exception('Could not determine source cases for selected skins');
    }

    return {
      for (final entry in counts.entries) entry.key: entry.value / total,
    };
  }

  String _weightedCaseChoice({
    required List<SkinDto> input,
    required Map<String, List<String>> caseToSkinIds,
  }) {
    final weights = _buildCaseWeights(
      input: input,
      caseToSkinIds: caseToSkinIds,
    );

    final roll = _random.nextDouble();
    double cumulative = 0.0;

    for (final entry in weights.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        return entry.key;
      }
    }

    return weights.keys.first;
  }

  String _getExterior(double value) {
    if (value <= 0.07) return 'Factory New';
    if (value <= 0.15) return 'Minimal Wear';
    if (value <= 0.37) return 'Field-Tested';
    if (value <= 0.44) return 'Well-Worn';
    return 'Battle-Scarred';
  }
}