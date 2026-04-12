import 'package:cs2_simulator/domain/tradeup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_data_builders.dart';

void main() {
  group('TradeUpService', () {
    final service = TradeUpService();

    test('returns validation issue for souvenir inputs', () {
      final input = [
        TradeUpInputItem(
          skin: buildSkin(id: '1', rarity: 'MIL_SPEC'),
          floatValue: 0.1,
          quality: TradeUpInputQuality.souvenir,
        ),
      ];

      final issue = service.validationIssue(
        input: input,
        skinIdToRegularCaseIds: const {},
      );

      expect(issue, 'Souvenir items cannot be used in trade-up contracts');
    });

    test('returns validation issue for mixed quality contract', () {
      final skin = buildSkin(id: '1', rarity: 'MIL_SPEC');
      final issue = service.validationIssue(
        input: [
          TradeUpInputItem(
            skin: skin,
            floatValue: 0.1,
            quality: TradeUpInputQuality.regular,
          ),
          TradeUpInputItem(
            skin: skin,
            floatValue: 0.1,
            quality: TradeUpInputQuality.statTrak,
          ),
        ],
        skinIdToRegularCaseIds: const {},
      );

      expect(issue, 'All selected skins must use the same quality mode');
    });

    test('weights standard outcomes by represented collections', () {
      final inputSkinA = buildSkin(
        id: '10',
        rarity: 'RESTRICTED',
        collection: 'Collection A',
      );
      final inputSkinB = buildSkin(
        id: '11',
        rarity: 'RESTRICTED',
        collection: 'Collection B',
      );
      final outputA = buildSkin(
        id: '20',
        rarity: 'CLASSIFIED',
        collection: 'Collection A',
      );
      final outputB = buildSkin(
        id: '21',
        rarity: 'CLASSIFIED',
        collection: 'Collection B',
      );

      final input = [
        ...List.generate(
          7,
          (_) => TradeUpInputItem(skin: inputSkinA, floatValue: 0.15),
        ),
        ...List.generate(
          3,
          (_) => TradeUpInputItem(skin: inputSkinB, floatValue: 0.15),
        ),
      ];

      final chances = service.getTradeUpChances(
        input: input,
        allSkins: [inputSkinA, inputSkinB, outputA, outputB],
        skinIdToRegularCaseIds: const {},
        regularCaseIdToSkinIds: const {},
      );

      expect(chances, hasLength(2));
      expect(
        chances.fold<double>(0, (sum, chance) => sum + chance.probability),
        closeTo(1.0, 0.000001),
      );
      expect(
        chances.firstWhere((chance) => chance.skin.id == '20').probability,
        closeTo(0.7, 0.000001),
      );
      expect(
        chances.firstWhere((chance) => chance.skin.id == '21').probability,
        closeTo(0.3, 0.000001),
      );
    });

    test('projects output float using normalized input wear', () {
      final inputSkin = buildSkin(
        id: '30',
        rarity: 'RESTRICTED',
        collection: 'Collection A',
        floatTop: 0.0,
        floatBottom: 0.8,
      );
      final outputSkin = buildSkin(
        id: '40',
        rarity: 'CLASSIFIED',
        collection: 'Collection A',
        floatTop: 0.06,
        floatBottom: 0.8,
      );

      final input = [
        ...List.generate(
          8,
          (_) => TradeUpInputItem(skin: inputSkin, floatValue: 0.8),
        ),
        ...List.generate(
          2,
          (_) => TradeUpInputItem(skin: inputSkin, floatValue: 0.4),
        ),
      ];

      final chances = service.getTradeUpChances(
        input: input,
        allSkins: [inputSkin, outputSkin],
        skinIdToRegularCaseIds: const {},
        regularCaseIdToSkinIds: const {},
      );

      expect(chances.single.floatValue, closeTo(0.726, 0.000001));
      expect(chances.single.exterior, 'Battle-Scarred');
    });

    test('builds covert outcomes from linked regular cases', () {
      final covertInput = buildSkin(
        id: '50',
        rarity: 'COVERT',
        collection: 'Collection A',
      );
      final knifePhase1 = buildSkin(
        id: '60',
        itemKind: 'KNIFE',
        weaponType: 'KNIFE',
        itemId: 'BAYONET',
        name: 'Gamma Doppler',
        rarity: 'CONTRABAND',
        finishCatalogName: 'GAMMA DOPPLER',
        phase: 'Phase 1',
      );
      final knifeEmerald = buildSkin(
        id: '61',
        itemKind: 'KNIFE',
        weaponType: 'KNIFE',
        itemId: 'BAYONET',
        name: 'Gamma Doppler',
        rarity: 'CONTRABAND',
        finishCatalogName: 'GAMMA DOPPLER',
        phase: 'Emerald',
      );
      final gloves = buildSkin(
        id: '62',
        itemKind: 'GLOVES',
        weaponType: 'GLOVES',
        itemId: 'SPORT',
        name: 'Nocts',
        rarity: 'CONTRABAND',
      );

      final chances = service.getTradeUpChances(
        input: List.generate(
          5,
          (_) => TradeUpInputItem(skin: covertInput, floatValue: 0.3),
        ),
        allSkins: [covertInput, knifePhase1, knifeEmerald, gloves],
        skinIdToRegularCaseIds: const {
          '50': ['900'],
        },
        regularCaseIdToSkinIds: const {
          '900': ['60', '61', '62'],
        },
      );

      expect(
        chances.fold<double>(0, (sum, chance) => sum + chance.probability),
        closeTo(1.0, 0.000001),
      );
      expect(chances.any((chance) => chance.skin.id == '61'), isTrue);
      expect(
        chances.firstWhere((chance) => chance.skin.id == '61').probability,
        lessThan(
          chances.firstWhere((chance) => chance.skin.id == '60').probability,
        ),
      );
    });
  });
}
