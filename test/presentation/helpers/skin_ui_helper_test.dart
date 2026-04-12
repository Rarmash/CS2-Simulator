import 'package:cs2_simulator/presentation/helpers/skin_ui_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_data_builders.dart';

void main() {
  group('SkinUiHelper', () {
    test('secondary text includes display variant when present', () {
      final skin = buildSkin(
        id: '1',
        name: 'Gamma Doppler',
        variantName: 'Phase 2',
      );

      expect(SkinUiHelper.secondaryText(skin), 'Gamma Doppler - Phase 2');
    });

    test('family text collapses configured weighted variants', () {
      final variants = [
        buildSkin(
          id: '1',
          itemKind: 'WEAPON',
          weaponType: 'PISTOL',
          itemId: 'GLOCK_18',
          name: 'Gamma Doppler',
          finishCatalogName: 'GAMMA DOPPLER',
          phase: 'Phase 1',
        ),
        buildSkin(
          id: '2',
          itemKind: 'WEAPON',
          weaponType: 'PISTOL',
          itemId: 'GLOCK_18',
          name: 'Gamma Doppler',
          finishCatalogName: 'GAMMA DOPPLER',
          phase: 'Emerald',
        ),
      ];

      expect(SkinUiHelper.familySecondaryText(variants), 'Gamma Doppler');
      expect(SkinUiHelper.familyDetailText(variants), 'Phase 1, Emerald');
    });

    test('full drop display name includes prefixes', () {
      final knife = buildSkin(
        id: '3',
        itemKind: 'KNIFE',
        weaponType: 'KNIFE',
        itemId: 'BAYONET',
        name: 'Doppler',
      );

      expect(
        SkinUiHelper.fullDropDisplayName(
          skin: knife,
          isStatTrak: true,
          isSouvenir: false,
        ),
        '★ StatTrak™ Bayonet | Doppler',
      );
    });
  });
}
