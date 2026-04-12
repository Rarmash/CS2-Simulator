import 'package:cs2_simulator/domain/terminal_offer.dart';
import 'package:cs2_simulator/domain/terminal_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_data_builders.dart';

void main() {
  group('TerminalSession', () {
    test('returns current offer when index is in range', () {
      final offers = [
        TerminalOffer(
          skin: buildSkin(id: '1'),
          isStatTrak: false,
          skinFloat: 0.15,
          exterior: 'Field-Tested',
          patternSeed: 123,
          offerIndex: 1,
        ),
        TerminalOffer(
          skin: buildSkin(id: '2'),
          isStatTrak: true,
          skinFloat: 0.02,
          exterior: 'Factory New',
          patternSeed: 456,
          offerIndex: 2,
        ),
      ];

      final session = TerminalSession(
        offers: offers,
        currentIndex: 1,
        acceptedOffer: null,
      );

      expect(session.currentOffer, same(offers[1]));
      expect(session.isFinished, isFalse);
      expect(session.offersRemaining, 1);
    });

    test('treats accepted or exhausted sessions as finished', () {
      final offer = TerminalOffer(
        skin: buildSkin(id: '1'),
        isStatTrak: false,
        skinFloat: 0.15,
        exterior: 'Field-Tested',
        patternSeed: 123,
        offerIndex: 1,
      );

      final accepted = TerminalSession(
        offers: [offer],
        currentIndex: 0,
        acceptedOffer: offer,
      );
      final exhausted = TerminalSession(
        offers: [offer],
        currentIndex: 1,
        acceptedOffer: null,
      );

      expect(accepted.isFinished, isTrue);
      expect(exhausted.isFinished, isTrue);
      expect(exhausted.currentOffer, isNull);
      expect(exhausted.offersRemaining, 0);
    });
  });
}
