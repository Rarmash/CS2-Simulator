import 'package:cs2_simulator/domain/tradeup_service.dart';
import 'package:cs2_simulator/presentation/helpers/tradeup_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_data_builders.dart';

void main() {
  group('TradeUpController', () {
    test('starts with default empty state', () {
      final controller = TradeUpController(service: _FakeTradeUpService());

      expect(controller.selected, isEmpty);
      expect(controller.tradeReady, isFalse);
      expect(controller.canExecuteTrade, isFalse);
      expect(controller.maxSelectable(), 10);
      expect(controller.canAddMore, isTrue);
    });

    test('caps covert contracts at five items', () {
      final controller = TradeUpController(service: _FakeTradeUpService());
      final covert = buildSkin(id: '1', rarity: 'COVERT');

      for (var index = 0; index < 6; index++) {
        controller.add(
          covert,
          allSkins: [covert],
          skinIdToRegularCaseIds: const {
            '1': ['100'],
          },
          regularCaseIdToSkinIds: const {
            '100': ['1'],
          },
        );
      }

      expect(controller.selected, hasLength(5));
      expect(controller.maxSelectable(), 5);
      expect(controller.tradeReady, isTrue);
    });

    test('throws when trying to mix rarities', () {
      final controller = TradeUpController(service: _FakeTradeUpService());
      final milSpec = buildSkin(id: '1', rarity: 'MIL_SPEC');
      final restricted = buildSkin(id: '2', rarity: 'RESTRICTED');

      controller.add(
        milSpec,
        allSkins: [milSpec],
        skinIdToRegularCaseIds: const {},
        regularCaseIdToSkinIds: const {},
      );

      expect(
        () => controller.add(
          restricted,
          allSkins: [milSpec, restricted],
          skinIdToRegularCaseIds: const {},
          regularCaseIdToSkinIds: const {},
        ),
        throwsException,
      );
    });

    test('recalculates chances and can execute when trade is valid', () {
      final service = _FakeTradeUpService();
      final controller = TradeUpController(service: service);
      final skin = buildSkin(id: '1', rarity: 'MIL_SPEC');

      for (var index = 0; index < 10; index++) {
        controller.add(
          skin,
          allSkins: [skin],
          skinIdToRegularCaseIds: const {},
          regularCaseIdToSkinIds: const {},
        );
      }

      expect(controller.tradeReady, isTrue);
      expect(controller.tradeIssue, isNull);
      expect(controller.chances, isNotEmpty);
      expect(controller.canExecuteTrade, isTrue);

      controller.executeTrade(
        allSkins: [skin],
        skinIdToRegularCaseIds: const {},
        regularCaseIdToSkinIds: const {},
      );

      expect(controller.result, isNotNull);
      expect(service.tradeUpCalls, 1);
    });

    test('clear resets controller state', () {
      final controller = TradeUpController(service: _FakeTradeUpService());
      final skin = buildSkin(id: '1', rarity: 'MIL_SPEC');

      controller.add(
        skin,
        allSkins: [skin],
        skinIdToRegularCaseIds: const {},
        regularCaseIdToSkinIds: const {},
      );

      controller.clear();

      expect(controller.selected, isEmpty);
      expect(controller.chances, isEmpty);
      expect(controller.tradeIssue, isNull);
      expect(controller.result, isNull);
    });
  });
}

class _FakeTradeUpService extends TradeUpService {
  int tradeUpCalls = 0;

  @override
  String? validationIssue({
    required List<TradeUpInputItem> input,
    required Map<String, List<String>> skinIdToRegularCaseIds,
  }) {
    return null;
  }

  @override
  List<TradeUpChance> getTradeUpChances({
    required List<TradeUpInputItem> input,
    required List allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    if (input.isEmpty) {
      return const [];
    }

    return [
      TradeUpChance(
        skin: input.first.skin,
        probability: 1.0,
        floatValue: 0.2,
        exterior: 'Field-Tested',
        isStatTrak: false,
        isSouvenir: false,
      ),
    ];
  }

  @override
  TradeUpResult tradeUp({
    required List<TradeUpInputItem> input,
    required List allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    tradeUpCalls += 1;
    return TradeUpResult(
      skin: input.first.skin,
      floatValue: 0.2,
      exterior: 'Field-Tested',
      isStatTrak: false,
      isSouvenir: false,
      patternSeed: 7,
    );
  }
}
