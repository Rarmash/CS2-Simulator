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
      );
    }

    if (input.length != 10) {
      throw Exception('Trade-up requires exactly 10 skins');
    }

    final nextRarity = _nextRarity(rarity);

    final selectedCollection = _weightedCollectionChoice(input: input);

    final possibleSkins = allSkins.where((s) {
      return _sameCollection(s.collection, selectedCollection) &&
          s.rarity == nextRarity &&
          !s.isSpecialItem;
    }).toList();

    if (possibleSkins.isEmpty) {
      throw Exception('No skins found for next rarity in selected collection');
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
  }) {
    if (input.isEmpty) return const [];

    final rarity = input.first.rarity;

    if (input.any((s) => s.rarity != rarity)) return const [];
    if (input.any((s) => s.isSpecialItem)) return const [];

    final isSpecialTrade = rarity == 'COVERT';
    if (isSpecialTrade && input.length != 5) return const [];
    if (!isSpecialTrade && input.length != 10) return const [];

    final collectionWeights = _buildCollectionWeights(input: input);

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

    for (final entry in collectionWeights.entries) {
      final collectionName = entry.key;
      final collectionProbability = entry.value;

      final possibleSkins = allSkins.where((s) {
        if (!_sameCollection(s.collection, collectionName)) return false;

        if (specialOnly) {
          return s.isSpecialItem;
        }

        return s.rarity == targetRarity && !s.isSpecialItem;
      }).toList();

      if (possibleSkins.isEmpty) continue;

      final perSkinProbability = collectionProbability / possibleSkins.length;

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
  }) {
    final selectedCollection = _weightedCollectionChoice(input: input);

    final possibleSkins = allSkins.where((s) {
      return _sameCollection(s.collection, selectedCollection) && s.isSpecialItem;
    }).toList();

    if (possibleSkins.isEmpty) {
      throw Exception('No knives/gloves found in selected collection');
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
      case 'CONSUMER':
        return 'INDUSTRIAL';
      case 'INDUSTRIAL':
        return 'MIL_SPEC';
      case 'MIL_SPEC':
        return 'RESTRICTED';
      case 'RESTRICTED':
        return 'CLASSIFIED';
      case 'CLASSIFIED':
        return 'COVERT';
      default:
        throw Exception('Trade-up is not supported for rarity: $rarity');
    }
  }

  String? _normalizedCollection(String? collection) {
    final value = collection?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool _sameCollection(String? a, String? b) {
    return _normalizedCollection(a) == _normalizedCollection(b);
  }

  Map<String, double> _buildCollectionWeights({
    required List<SkinDto> input,
  }) {
    final counts = <String, int>{};

    for (final skin in input) {
      final collection = _normalizedCollection(skin.collection);
      if (collection == null) continue;
      counts[collection] = (counts[collection] ?? 0) + 1;
    }

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      throw Exception('Could not determine collections for selected skins');
    }

    return {
      for (final entry in counts.entries) entry.key: entry.value / total,
    };
  }

  String _weightedCollectionChoice({
    required List<SkinDto> input,
  }) {
    final weights = _buildCollectionWeights(input: input);

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