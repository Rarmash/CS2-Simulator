import 'package:cs2_simulator/presentation/helpers/sticker_ui_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_data_builders.dart';

void main() {
  group('StickerUiHelper', () {
    test('builds secondary text from effect and collection', () {
      final sticker = buildSticker(
        id: '1',
        effect: 'FOIL',
        collection: 'Antwerp 2022',
      );

      expect(StickerUiHelper.secondaryText(sticker), 'Foil • Antwerp 2022');
    });

    test('falls back to sticker type label when no extra parts exist', () {
      final sticker = buildSticker(
        id: '2',
        collection: null,
        tournament: null,
        stickerType: 'AUTOGRAPH',
      );

      expect(StickerUiHelper.secondaryText(sticker), 'Autograph');
    });

    test('maps effect labels', () {
      expect(StickerUiHelper.effectLabel('GLITTER'), 'Glitter');
      expect(StickerUiHelper.effectLabel('UNKNOWN'), 'Standard');
    });
  });
}
