import 'dart:math';

import 'package:cs2_simulator/domain/skin_float_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkinFloatHelper', () {
    test('exteriorFromFloat uses expected thresholds', () {
      expect(SkinFloatHelper.exteriorFromFloat(0.07), 'Factory New');
      expect(SkinFloatHelper.exteriorFromFloat(0.08), 'Minimal Wear');
      expect(SkinFloatHelper.exteriorFromFloat(0.20), 'Field-Tested');
      expect(SkinFloatHelper.exteriorFromFloat(0.40), 'Well-Worn');
      expect(SkinFloatHelper.exteriorFromFloat(0.80), 'Battle-Scarred');
    });

    test('generateWear stays within supplied bounds', () {
      final random = Random(42);
      for (var index = 0; index < 50; index++) {
        final result = SkinFloatHelper.generateWear(
          random: random,
          minFloat: 0.10,
          maxFloat: 0.20,
        );
        expect(result.floatValue, isNotNull);
        expect(result.floatValue!, inInclusiveRange(0.10, 0.20));
        expect(result.exterior, isNotNull);
      }
    });

    test('generateWear collapses when max is not above min', () {
      final result = SkinFloatHelper.generateWear(
        random: Random(1),
        minFloat: 0.45,
        maxFloat: 0.45,
      );
      expect(result.floatValue, 0.45);
      expect(result.exterior, 'Well-Worn');
    });
  });
}
