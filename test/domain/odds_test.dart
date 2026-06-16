import 'package:cs2_simulator/domain/case_odds.dart';
import 'package:cs2_simulator/domain/package_odds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseOdds', () {
    test('sum to 100% within a tiny tolerance', () {
      final total = CaseOdds.values.fold<double>(
        0,
        (sum, entry) => sum + entry.chance,
      );

      expect(total, closeTo(1.0, 0.0001));
    });

    test('decrease monotonically from mil-spec to special item', () {
      for (var i = 1; i < CaseOdds.values.length; i++) {
        expect(
          CaseOdds.values[i - 1].chance,
          greaterThan(CaseOdds.values[i].chance),
        );
      }
    });
  });

  group('PackageOdds', () {
    test('sum to 100% within a tiny tolerance', () {
      final total = PackageOdds.values.fold<double>(
        0,
        (sum, entry) => sum + entry.chance,
      );

      expect(total, closeTo(1.0, 0.0001));
    });

    test('decrease monotonically from consumer to covert', () {
      for (var i = 1; i < PackageOdds.values.length; i++) {
        expect(
          PackageOdds.values[i - 1].chance,
          greaterThan(PackageOdds.values[i].chance),
        );
      }
    });
  });
}
