import 'dart:math';

import 'package:cs2_simulator/domain/skin_pattern_helper.dart';
import 'package:cs2_simulator/domain/special_item_variant_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_data_builders.dart';

void main() {
  group('SkinPatternHelper', () {
    final gammaPhase1 = buildSkin(
      id: '201',
      itemKind: 'KNIFE',
      weaponType: 'KNIFE',
      itemId: 'BAYONET',
      name: 'Gamma Doppler',
      finishCatalogName: 'GAMMA DOPPLER',
      phase: 'Phase 1',
    );
    final gammaEmerald = buildSkin(
      id: '202',
      itemKind: 'KNIFE',
      weaponType: 'KNIFE',
      itemId: 'BAYONET',
      name: 'Gamma Doppler',
      finishCatalogName: 'GAMMA DOPPLER',
      phase: 'Emerald',
    );
    final fade = buildSkin(
      id: '203',
      itemKind: 'WEAPON',
      weaponType: 'PISTOL',
      itemId: 'GLOCK_18',
      name: 'Fade',
      finishCatalogName: 'FADE',
    );
    final caseHardened = buildSkin(
      id: '204',
      itemKind: 'WEAPON',
      weaponType: 'RIFLE',
      itemId: 'AK_47',
      name: 'Case Hardened',
      finishCatalogName: 'CASE HARDENED',
    );
    final vanillaKnife = buildSkin(
      id: '205',
      itemKind: 'KNIFE',
      weaponType: 'KNIFE',
      itemId: 'BAYONET',
      name: 'Vanilla',
    );

    test('detects seed support for seed-driven and special items', () {
      expect(SkinPatternHelper.supportsPatternSeed(fade), isTrue);
      expect(SkinPatternHelper.supportsPatternSeed(vanillaKnife), isTrue);
      expect(
        SkinPatternHelper.supportsPatternSeed(
          buildSkin(id: '206', name: 'Redline', finishCatalogName: 'REDLINE'),
        ),
        isFalse,
      );
    });

    test('detects explicit phase variants', () {
      expect(SkinPatternHelper.hasExplicitPhaseVariant(gammaPhase1), isTrue);
      expect(SkinPatternHelper.hasExplicitPhaseVariant(fade), isFalse);
    });

    test('generateSeed keeps doppler seed within selected variant bucket', () {
      final variants = [gammaPhase1, gammaEmerald];
      final seed = SkinPatternHelper.generateSeed(
        random: Random(3),
        skin: gammaEmerald,
        siblingVariants: variants,
      );

      expect(seed, isNotNull);
      final resolved = SpecialItemVariantHelper.variantForSeed(variants, seed!);
      expect(resolved.id, gammaEmerald.id);
    });

    test('does not duplicate phase in generic pattern description', () {
      expect(
        SkinPatternHelper.describePattern(skin: gammaPhase1, patternSeed: 123),
        isNull,
      );
      expect(
        SkinPatternHelper.describePatternMetric(
          skin: gammaPhase1,
          patternSeed: 123,
        ),
        isNull,
      );
    });

    test('provides descriptions and metrics for supported finishes', () {
      expect(
        SkinPatternHelper.describePattern(skin: fade, patternSeed: 20),
        isNotNull,
      );
      expect(
        SkinPatternHelper.describePatternMetric(skin: fade, patternSeed: 20),
        contains('Fade index'),
      );
      expect(
        SkinPatternHelper.describePattern(skin: caseHardened, patternSeed: 999),
        isNotNull,
      );
      expect(
        SkinPatternHelper.patternExplanation(gammaEmerald),
        contains('Emerald'),
      );
      expect(
        SkinPatternHelper.possiblePatternOutcomes(gammaEmerald),
        isNotEmpty,
      );
    });
  });
}
