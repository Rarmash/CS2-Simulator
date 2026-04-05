import 'dart:math';

import '../data/models/skin_dto.dart';
import 'skin_float_helper.dart';

class TradeUpInputItem {
  final SkinDto skin;
  final double floatValue;

  const TradeUpInputItem({required this.skin, required this.floatValue});
}

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
  final double floatValue;
  final String exterior;

  const TradeUpChance({
    required this.skin,
    required this.probability,
    required this.floatValue,
    required this.exterior,
  });
}

class TradeUpService {
  final Random _random = Random();

  TradeUpResult tradeUp({
    required List<TradeUpInputItem> input,
    required List<SkinDto> allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    if (input.isEmpty) {
      throw Exception('No skins selected');
    }

    final rarity = input.first.skin.rarity;

    if (input.any((s) => s.skin.rarity != rarity)) {
      throw Exception('All skins must have same rarity');
    }

    if (input.any((s) => s.skin.isSpecialItem)) {
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
        skinIdToRegularCaseIds: skinIdToRegularCaseIds,
        regularCaseIdToSkinIds: regularCaseIdToSkinIds,
      );
    }

    if (input.length != 10) {
      throw Exception('Trade-up requires exactly 10 skins');
    }

    final chances = getTradeUpChances(
      input: input,
      allSkins: allSkins,
      skinIdToRegularCaseIds: skinIdToRegularCaseIds,
      regularCaseIdToSkinIds: regularCaseIdToSkinIds,
    );

    if (chances.isEmpty) {
      throw Exception('No valid trade-up outcomes found');
    }

    return _rollFromChances(chances);
  }

  List<TradeUpChance> getTradeUpChances({
    required List<TradeUpInputItem> input,
    required List<SkinDto> allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    if (input.isEmpty) return const [];

    final rarity = input.first.skin.rarity;

    if (input.any((s) => s.skin.rarity != rarity)) return const [];
    if (input.any((s) => s.skin.isSpecialItem)) return const [];

    final isSpecialTrade = rarity == 'COVERT';
    if (isSpecialTrade && input.length != 5) return const [];
    if (!isSpecialTrade && input.length != 10) return const [];

    final skinById = {for (final s in allSkins) s.id: s};

    if (isSpecialTrade) {
      final caseWeights = _buildRegularCaseWeights(
        input: input,
        skinIdToRegularCaseIds: skinIdToRegularCaseIds,
      );

      final Map<String, double> skinProbabilityById = {};

      for (final entry in caseWeights.entries) {
        final containerId = entry.key;
        final caseProbability = entry.value;

        final possibleSpecialSkins = _getSpecialSkinsForRegularCase(
          containerId: containerId,
          allSkins: allSkins,
          regularCaseIdToSkinIds: regularCaseIdToSkinIds,
        );

        if (possibleSpecialSkins.isEmpty) continue;

        final perSkinProbability =
            caseProbability / possibleSpecialSkins.length;

        for (final skin in possibleSpecialSkins) {
          skinProbabilityById[skin.id] =
              (skinProbabilityById[skin.id] ?? 0) + perSkinProbability;
        }
      }

      final chances = skinProbabilityById.entries
          .map(
            (e) {
              final skin = skinById[e.key]!;
              final floatValue = _calculateOutputFloat(input, skin);
              return TradeUpChance(
                skin: skin,
                probability: e.value,
                floatValue: floatValue,
                exterior: _getExterior(floatValue),
              );
            },
          )
          .toList();

      chances.sort((a, b) => b.probability.compareTo(a.probability));
      return chances;
    }

    final collectionWeights = _buildCollectionWeights(input: input);
    final targetRarity = _nextRarity(rarity);

    final Map<String, double> skinProbabilityById = {};

    for (final entry in collectionWeights.entries) {
      final collectionName = entry.key;
      final collectionProbability = entry.value;

      final possibleSkins = allSkins.where((s) {
        return _sameCollection(s.collection, collectionName) &&
            s.rarity == targetRarity &&
            !s.isSpecialItem;
      }).toList();

      if (possibleSkins.isEmpty) continue;

      final perSkinProbability = collectionProbability / possibleSkins.length;

      for (final skin in possibleSkins) {
        skinProbabilityById[skin.id] =
            (skinProbabilityById[skin.id] ?? 0) + perSkinProbability;
      }
    }

    final chances = skinProbabilityById.entries
        .map((e) {
          final skin = skinById[e.key]!;
          final floatValue = _calculateOutputFloat(input, skin);
          return TradeUpChance(
            skin: skin,
            probability: e.value,
            floatValue: floatValue,
            exterior: _getExterior(floatValue),
          );
        })
        .toList();

    chances.sort((a, b) => b.probability.compareTo(a.probability));
    return chances;
  }

  TradeUpResult _covertToSpecial({
    required List<TradeUpInputItem> input,
    required List<SkinDto> allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    final chances = getTradeUpChances(
      input: input,
      allSkins: allSkins,
      skinIdToRegularCaseIds: skinIdToRegularCaseIds,
      regularCaseIdToSkinIds: regularCaseIdToSkinIds,
    );

    if (chances.isEmpty) {
      throw Exception('No knives/gloves found in related regular cases');
    }

    return _rollFromChances(chances);
  }

  List<SkinDto> _getSpecialSkinsForRegularCase({
    required String containerId,
    required List<SkinDto> allSkins,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    final ids = regularCaseIdToSkinIds[containerId] ?? const [];
    final idSet = ids.toSet();

    return allSkins.where((s) {
      return idSet.contains(s.id) && s.isSpecialItem;
    }).toList();
  }

  double _calculateOutputFloat(
    List<TradeUpInputItem> input,
    SkinDto resultSkin,
  ) {
    final avgNormalizedFloat =
        input.map(_normalizedInputFloat).reduce((a, b) => a + b) / input.length;

    return resultSkin.floatTop +
        avgNormalizedFloat * (resultSkin.floatBottom - resultSkin.floatTop);
  }

  double _normalizedInputFloat(TradeUpInputItem input) {
    final min = input.skin.floatTop;
    final max = input.skin.floatBottom;
    final range = max - min;

    if (range <= 0) {
      return 0;
    }

    final normalized = (input.floatValue - min) / range;
    return normalized.clamp(0.0, 1.0);
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
    required List<TradeUpInputItem> input,
  }) {
    final counts = <String, int>{};

    for (final item in input) {
      final collection = _normalizedCollection(item.skin.collection);
      if (collection == null) continue;
      counts[collection] = (counts[collection] ?? 0) + 1;
    }

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      throw Exception('Could not determine collections for selected skins');
    }

    return {for (final entry in counts.entries) entry.key: entry.value / total};
  }

  Map<String, double> _buildRegularCaseWeights({
    required List<TradeUpInputItem> input,
    required Map<String, List<String>> skinIdToRegularCaseIds,
  }) {
    final counts = <String, double>{};

    for (final item in input) {
      final containerIds = (skinIdToRegularCaseIds[item.skin.id] ?? const [])
          .toSet()
          .toList();
      if (containerIds.isEmpty) continue;

      final contribution = 1.0 / containerIds.length;
      for (final containerId in containerIds) {
        counts[containerId] = (counts[containerId] ?? 0) + contribution;
      }
    }

    final total = counts.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) {
      throw Exception(
        'Could not determine related regular cases for selected skins',
      );
    }

    return {for (final entry in counts.entries) entry.key: entry.value / total};
  }

  TradeUpResult _rollFromChances(List<TradeUpChance> chances) {
    final roll = _random.nextDouble();
    double cumulative = 0.0;

    for (final chance in chances) {
      cumulative += chance.probability;
      if (roll <= cumulative) {
        return TradeUpResult(
          skin: chance.skin,
          floatValue: chance.floatValue,
          exterior: chance.exterior,
        );
      }
    }

    final fallback = chances.first;
    return TradeUpResult(
      skin: fallback.skin,
      floatValue: fallback.floatValue,
      exterior: fallback.exterior,
    );
  }

  String _getExterior(double value) {
    return SkinFloatHelper.exteriorFromFloat(value);
  }
}
