import 'package:cs2_simulator/data/models/skin_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_data_builders.dart';

void main() {
  group('SkinDto', () {
    test('maps display names for weapons, knives, and gloves', () {
      expect(
        buildSkin(id: '1', itemKind: 'WEAPON', itemId: 'USP_S').itemDisplayName,
        'USP-S',
      );
      expect(
        buildSkin(
          id: '2',
          itemKind: 'KNIFE',
          weaponType: 'KNIFE',
          itemId: 'BUTTERFLY',
        ).itemDisplayName,
        'Butterfly Knife',
      );
      expect(
        buildSkin(
          id: '3',
          itemKind: 'GLOVES',
          weaponType: 'GLOVES',
          itemId: 'SPORT',
        ).itemDisplayName,
        'Sport Gloves',
      );
    });

    test('exposes special item and collection flags', () {
      final armorySkin = SkinDto.fromJson({
        'id': '4',
        'name': 'Test',
        'skinImage': 'assets/skins/4.webp',
        'floatTop': 0,
        'floatBottom': 1,
        'rarity': 'MIL_SPEC',
        'weaponType': 'RIFLE',
        'itemKind': 'WEAPON',
        'itemId': 'AK_47',
        'collection': 'Test',
        'finishCatalogName': 'Test',
        'variantName': null,
        'phase': null,
        'apiPaintIndex': '123',
        'collectionSourceType': 'ARMORY',
        'collectionSourceId': 'ARMORY',
      });
      final operationSkin = SkinDto.fromJson({
        'id': '5',
        'name': 'Test',
        'skinImage': 'assets/skins/5.webp',
        'floatTop': 0,
        'floatBottom': 1,
        'rarity': 'MIL_SPEC',
        'weaponType': 'RIFLE',
        'itemKind': 'WEAPON',
        'itemId': 'AK_47',
        'collection': 'Test',
        'finishCatalogName': 'Test',
        'variantName': null,
        'phase': null,
        'apiPaintIndex': '111',
        'collectionSourceType': 'OPERATION',
        'collectionSourceId': 'RIPTIDE',
        'operationCollectionIds': ['10008'],
        'isOperationCollection': true,
      });

      expect(armorySkin.isArmoryRewardCollection, isTrue);
      expect(armorySkin.isOperationRewardCollection, isFalse);
      expect(operationSkin.isOperationRewardCollection, isTrue);
      expect(operationSkin.belongsToAnyOperationCollection, isTrue);
      expect(operationSkin.isOperationCollection, isTrue);
    });

    test('prefers variant name over phase for display variant', () {
      final withVariant = buildSkin(
        id: '6',
        variantName: 'Ruby',
        phase: 'Phase 2',
      );
      final withPhaseOnly = buildSkin(id: '7', phase: 'Phase 4');

      expect(withVariant.displayVariant, 'Ruby');
      expect(withPhaseOnly.displayVariant, 'Phase 4');
    });
  });
}
