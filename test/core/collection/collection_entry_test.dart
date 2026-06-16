import 'package:cs2_simulator/core/collection/collection_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollectionEntry', () {
    test('round-trips through json', () {
      final entry = CollectionEntry(
        entryId: 'entry-1',
        category: 'skin',
        filterCategory: 'knife',
        itemId: '9001',
        stackKey: 'skin:9001:true:false',
        title: '★ Karambit | Doppler',
        subtitle: 'Factory New',
        imagePath: 'assets/skins/9001.webp',
        rarity: 'COVERT',
        sourceName: 'Gamma Case',
        sourceType: 'CASE',
        acquiredAt: DateTime.parse('2026-04-12T12:00:00Z'),
        isStatTrak: true,
        isSouvenir: false,
        floatValue: 0.0321,
        exterior: 'Factory New',
        patternSeed: 305,
      );

      final decoded = CollectionEntry.fromJson(entry.toJson());

      expect(decoded.entryId, entry.entryId);
      expect(decoded.filterCategory, 'knife');
      expect(decoded.isStatTrak, isTrue);
      expect(decoded.patternSeed, 305);
      expect(decoded.acquiredAt, entry.acquiredAt);
    });

    test('falls back to category when legacy filter category is missing', () {
      final decoded = CollectionEntry.fromJson({
        'entryId': 'entry-2',
        'category': 'sticker',
        'itemId': '10',
        'stackKey': 'sticker:10',
        'title': 'Sticker',
        'subtitle': 'Paper',
        'imagePath': 'assets/stickers/10.webp',
        'rarity': 'HIGH_GRADE',
        'acquiredAt': '2026-04-12T12:00:00.000Z',
      });

      expect(decoded.filterCategory, 'sticker');
      expect(decoded.sourceName, '');
      expect(decoded.sourceType, '');
      expect(decoded.isStatTrak, isFalse);
    });
  });
}
