import 'package:cs2_simulator/core/collection/collection_tracking_service.dart';
import 'package:cs2_simulator/domain/dropped_skin.dart';
import 'package:cs2_simulator/domain/dropped_sticker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../test_data_builders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  group('CollectionTrackingService', () {
    test('records skin drops and preserves knife filter category', () async {
      final service = CollectionTrackingService();
      final knife = buildSkin(
        id: '301',
        itemKind: 'KNIFE',
        weaponType: 'KNIFE',
        itemId: 'BAYONET',
        name: 'Doppler',
      );

      await service.recordSkinDrop(
        drop: DroppedSkin(
          skin: knife,
          isStatTrak: false,
          isSouvenir: false,
          skinFloat: 0.12345,
          exterior: 'Minimal Wear',
          patternSeed: 17,
        ),
        sourceName: 'Dreams & Nightmares Case',
        sourceType: 'Case',
      );

      final entries = await service.loadEntries();

      expect(entries, hasLength(1));
      expect(entries.single.category, 'skin');
      expect(entries.single.filterCategory, 'knife');
      expect(entries.single.patternSeed, 17);
    });

    test('groups summaries and computes best float and flags', () async {
      final service = CollectionTrackingService();
      final skin = buildSkin(id: '302', name: 'Printstream');

      await service.recordSkinDrop(
        drop: DroppedSkin(
          skin: skin,
          isStatTrak: false,
          isSouvenir: false,
          skinFloat: 0.30,
          exterior: 'Field-Tested',
          patternSeed: null,
        ),
        sourceName: 'Container A',
        sourceType: 'Case',
      );
      await service.recordSkinDrop(
        drop: DroppedSkin(
          skin: skin,
          isStatTrak: true,
          isSouvenir: false,
          skinFloat: 0.12,
          exterior: 'Minimal Wear',
          patternSeed: null,
        ),
        sourceName: 'Container A',
        sourceType: 'Case',
      );

      final summaries = await service.loadSummaries();

      expect(summaries, hasLength(2));
      expect(summaries.map((summary) => summary.bestFloat), contains(0.12));
      expect(summaries.any((summary) => summary.hasStatTrak), isTrue);
    });

    test('calculates per-source stats with unique item counting', () async {
      final service = CollectionTrackingService();
      final skin = buildSkin(id: '303', name: 'Redline');
      final sticker = buildSticker(id: '401', name: 'Team Spirit');

      await service.recordSkinDrop(
        drop: DroppedSkin(
          skin: skin,
          isStatTrak: false,
          isSouvenir: false,
          skinFloat: 0.20,
          exterior: 'Field-Tested',
          patternSeed: null,
        ),
        sourceName: 'Source A',
        sourceType: 'Case',
      );
      await service.recordSkinDrop(
        drop: DroppedSkin(
          skin: skin,
          isStatTrak: false,
          isSouvenir: false,
          skinFloat: 0.25,
          exterior: 'Field-Tested',
          patternSeed: null,
        ),
        sourceName: 'Source A',
        sourceType: 'Case',
      );
      await service.recordStickerDrop(
        drop: DroppedSticker(sticker: sticker),
        sourceName: 'Source A',
        sourceType: 'Case',
      );

      final stats = await service.loadSourceStats(
        sourceName: 'Source A',
        sourceType: 'Case',
      );

      expect(stats.openedCount, 3);
      expect(stats.collectedUniqueCount, 2);
    });

    test('clears saved collection data', () async {
      final service = CollectionTrackingService();

      await service.recordStickerDrop(
        drop: DroppedSticker(sticker: buildSticker(id: '402')),
        sourceName: 'Source B',
        sourceType: 'Capsule',
      );
      expect(await service.loadEntries(), isNotEmpty);

      await service.clearAll();

      expect(await service.loadEntries(), isEmpty);
      expect(await service.loadSummaries(), isEmpty);
    });
  });
}
