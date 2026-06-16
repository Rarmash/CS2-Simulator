import 'package:flutter_test/flutter_test.dart';

import '../../test_data_builders.dart';

void main() {
  group('MusicKitDto', () {
    test('splits artist and track name', () {
      final kit = buildMusicKit(id: '1', name: 'AWOLNATION, I Am');

      expect(kit.artist, 'AWOLNATION');
      expect(kit.trackName, 'I Am');
    });

    test('keeps full name when comma is missing', () {
      final kit = buildMusicKit(id: '2', name: 'NoCommaTrack');

      expect(kit.artist, isNull);
      expect(kit.trackName, 'NoCommaTrack');
    });

    test('adds StatTrak prefix only for stattrak-only kits', () {
      final stattrakOnly = buildMusicKit(
        id: '3',
        hasRegular: false,
        hasStatTrak: true,
      );
      final shared = buildMusicKit(
        id: '4',
        hasRegular: true,
        hasStatTrak: true,
      );

      expect(stattrakOnly.displayName, startsWith('StatTrak™ '));
      expect(shared.displayName, 'Artist, Track');
    });
  });
}
