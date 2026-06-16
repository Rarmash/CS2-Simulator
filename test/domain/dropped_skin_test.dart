import 'package:cs2_simulator/domain/dropped_skin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_data_builders.dart';

void main() {
  group('DroppedSkin', () {
    test('detects vanilla knives', () {
      final vanilla = DroppedSkin(
        skin: buildSkin(
          id: '1',
          itemKind: 'KNIFE',
          weaponType: 'KNIFE',
          itemId: 'BAYONET',
          name: 'Vanilla',
        ),
        isStatTrak: false,
        isSouvenir: false,
        skinFloat: null,
        exterior: null,
        patternSeed: null,
      );

      expect(vanilla.isVanillaKnife, isTrue);
    });

    test('builds readable full display name', () {
      final drop = DroppedSkin(
        skin: buildSkin(id: '2', itemId: 'AK_47', name: 'Redline'),
        isStatTrak: true,
        isSouvenir: false,
        skinFloat: 0.15,
        exterior: 'Minimal Wear',
        patternSeed: 33,
      );

      expect(drop.fullDisplayName, 'StatTrak™ AK-47 | Redline');
    });
  });
}
