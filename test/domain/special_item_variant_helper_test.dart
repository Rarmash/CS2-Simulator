import 'dart:math';

import 'package:cs2_simulator/domain/special_item_variant_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_data_builders.dart';

void main() {
  group('SpecialItemVariantHelper', () {
    final phase1 = buildSkin(
      id: '101',
      itemKind: 'KNIFE',
      weaponType: 'KNIFE',
      itemId: 'BAYONET',
      name: 'Doppler',
      finishCatalogName: 'DOPPLER',
      phase: 'Phase 1',
    );
    final ruby = buildSkin(
      id: '102',
      itemKind: 'KNIFE',
      weaponType: 'KNIFE',
      itemId: 'BAYONET',
      name: 'Doppler',
      finishCatalogName: 'DOPPLER',
      phase: 'Ruby',
    );
    final sapphire = buildSkin(
      id: '103',
      itemKind: 'KNIFE',
      weaponType: 'KNIFE',
      itemId: 'BAYONET',
      name: 'Doppler',
      finishCatalogName: 'DOPPLER',
      phase: 'Sapphire',
    );
    final tigerTooth = buildSkin(
      id: '104',
      itemKind: 'KNIFE',
      weaponType: 'KNIFE',
      itemId: 'BAYONET',
      name: 'Tiger Tooth',
      finishCatalogName: 'TIGER TOOTH',
    );

    test('groups skins by family', () {
      final families = SpecialItemVariantHelper.groupFamilies([
        sapphire,
        tigerTooth,
        ruby,
        phase1,
      ]);

      expect(families, hasLength(2));
      expect(families.first.map((skin) => skin.id), ['101', '102', '103']);
      expect(families.last.single.id, '104');
    });

    test('uses weighted probabilities for configured doppler variants', () {
      final probabilities = SpecialItemVariantHelper.variantProbabilities([
        phase1,
        ruby,
        sapphire,
      ]);

      expect(
        probabilities.values.reduce((a, b) => a + b),
        closeTo(1.0, 0.000001),
      );
      expect(probabilities['101']!, greaterThan(probabilities['102']!));
      expect(probabilities['101']!, greaterThan(probabilities['103']!));
    });

    test('maps generated seed back to selected variant bucket', () {
      final variants = [phase1, ruby, sapphire];
      final random = Random(7);

      for (final selected in variants) {
        final seed = SpecialItemVariantHelper.generateSeedForVariant(
          random,
          variants,
          selected,
        );
        final resolved = SpecialItemVariantHelper.variantForSeed(
          variants,
          seed,
        );
        expect(resolved.id, selected.id);
      }
    });

    test('falls back to uniform probabilities for non-configured variants', () {
      final probabilities = SpecialItemVariantHelper.variantProbabilities([
        tigerTooth,
        buildSkin(
          id: '105',
          itemKind: 'KNIFE',
          weaponType: 'KNIFE',
          itemId: 'BAYONET',
          name: 'Tiger Tooth',
          finishCatalogName: 'TIGER TOOTH',
          variantName: 'Alt',
        ),
      ]);

      expect(probabilities['104'], closeTo(0.5, 0.000001));
      expect(probabilities['105'], closeTo(0.5, 0.000001));
    });
  });
}
