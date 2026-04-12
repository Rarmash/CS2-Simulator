import 'package:cs2_simulator/core/utils/team_name_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeamNameHelper', () {
    test('canonicalizes known aliases', () {
      expect(TeamNameHelper.canonicalize('mousesports'), 'MOUZ');
      expect(TeamNameHelper.canonicalize('Heroic'), 'HEROIC');
      expect(TeamNameHelper.canonicalize('Complexity Gaming'), 'Complexity');
      expect(TeamNameHelper.canonicalize('Gambit Gaming'), 'Gambit Esports');
    });

    test('normalizes whitespace without changing unknown teams', () {
      expect(TeamNameHelper.canonicalize('  Team   Spirit  '), 'Team Spirit');
    });
  });
}
