import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/skin_dto.dart';
import '../../data/models/sticker_dto.dart';
import '../../domain/dropped_agent.dart';
import '../../domain/dropped_charm.dart';
import '../../domain/dropped_graffiti.dart';
import '../../domain/dropped_music_kit.dart';
import '../../domain/dropped_patch.dart';
import '../../domain/dropped_pin.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/dropped_sticker.dart';
import '../../presentation/helpers/agent_ui_helper.dart';
import '../../presentation/helpers/charm_ui_helper.dart';
import '../../presentation/helpers/graffiti_ui_helper.dart';
import '../../presentation/helpers/music_kit_ui_helper.dart';
import '../../presentation/helpers/patch_ui_helper.dart';
import '../../presentation/helpers/pin_ui_helper.dart';
import '../../presentation/helpers/skin_ui_helper.dart';
import '../../presentation/helpers/sticker_ui_helper.dart';
import 'collection_entry.dart';
import 'collection_summary.dart';

class CollectionTrackingService {
  static const _entriesKey = 'collection_entries_v1';
  static const _maxEntries = 5000;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final Random _random = Random();

  Future<List<CollectionEntry>> loadEntries() async {
    final raw = await _prefs.getString(_entriesKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final entries = decoded
        .whereType<Map>()
        .map(
          (item) => CollectionEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    entries.sort((a, b) => b.acquiredAt.compareTo(a.acquiredAt));
    return entries;
  }

  Future<List<CollectionSummary>> loadSummaries() async {
    final entries = await loadEntries();
    final grouped = <String, List<CollectionEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.stackKey, () => <CollectionEntry>[]).add(entry);
    }

    final summaries = grouped.entries.map((entry) {
      final items = List<CollectionEntry>.from(entry.value)
        ..sort((a, b) => b.acquiredAt.compareTo(a.acquiredAt));
      final latest = items.first;
      final floatCandidates = items
          .map((item) => item.floatValue)
          .whereType<double>()
          .toList();

      return CollectionSummary(
        stackKey: latest.stackKey,
        category: latest.category,
        filterCategory: latest.filterCategory,
        title: latest.title,
        subtitle: latest.subtitle,
        imagePath: latest.imagePath,
        rarity: latest.rarity,
        count: items.length,
        latestAcquiredAt: latest.acquiredAt,
        bestFloat: floatCandidates.isEmpty ? null : floatCandidates.reduce(min),
        hasStatTrak: items.any((item) => item.isStatTrak),
        hasSouvenir: items.any((item) => item.isSouvenir),
        latestEntry: latest,
      );
    }).toList();

    summaries.sort((a, b) => b.latestAcquiredAt.compareTo(a.latestAcquiredAt));
    return summaries;
  }

  Future<void> clearAll() async {
    await _prefs.remove(_entriesKey);
  }

  Future<void> recordSkinDrop({
    required DroppedSkin drop,
    required String sourceName,
    required String sourceType,
  }) async {
    final skin = drop.skin;
    final qualityPrefix = drop.isSouvenir
        ? 'Souvenir '
        : drop.isStatTrak
        ? 'StatTrak™ '
        : '';

    await _appendEntry(
      CollectionEntry(
        entryId: _entryId(),
        category: 'skin',
        filterCategory: _skinFilterCategory(skin),
        itemId: skin.id,
        stackKey: 'skin:${skin.id}:${drop.isStatTrak}:${drop.isSouvenir}',
        title: '$qualityPrefix${skin.itemDisplayName}',
        subtitle: SkinUiHelper.secondaryText(skin),
        imagePath: skin.skinImage,
        rarity: skin.rarity,
        sourceName: sourceName,
        sourceType: sourceType,
        acquiredAt: DateTime.now(),
        isStatTrak: drop.isStatTrak,
        isSouvenir: drop.isSouvenir,
        floatValue: drop.skinFloat,
        exterior: drop.exterior,
        patternSeed: drop.patternSeed,
      ),
    );
  }

  Future<void> recordStickerDrop({
    required DroppedSticker drop,
    required String sourceName,
    required String sourceType,
  }) async {
    await _appendEntry(
      _entryFromSticker(
        sticker: drop.sticker,
        sourceName: sourceName,
        sourceType: sourceType,
      ),
    );
  }

  Future<void> recordPinDrop({
    required DroppedPin drop,
    required String sourceName,
    required String sourceType,
  }) async {
    await _appendEntry(
      _simpleEntry(
        category: 'pin',
        itemId: drop.pin.id,
        title: drop.pin.name,
        subtitle: PinUiHelper.secondaryText(drop.pin),
        imagePath: drop.pin.pinImage,
        rarity: drop.pin.rarity,
        sourceName: sourceName,
        sourceType: sourceType,
      ),
    );
  }

  Future<void> recordMusicKitDrop({
    required DroppedMusicKit drop,
    required String sourceName,
    required String sourceType,
  }) async {
    await _appendEntry(
      _simpleEntry(
        category: 'music_kit',
        itemId: drop.musicKit.id,
        title: drop.musicKit.displayName,
        subtitle: MusicKitUiHelper.secondaryText(drop.musicKit),
        imagePath: drop.musicKit.musicKitImage,
        rarity: drop.musicKit.rarity,
        sourceName: sourceName,
        sourceType: sourceType,
      ),
    );
  }

  Future<void> recordAgentDrop({
    required DroppedAgent drop,
    required String sourceName,
    required String sourceType,
  }) async {
    await _appendEntry(
      _simpleEntry(
        category: 'agent',
        itemId: drop.agent.id,
        title: drop.agent.name,
        subtitle: AgentUiHelper.secondaryText(drop.agent),
        imagePath: drop.agent.agentImage,
        rarity: drop.agent.rarity,
        sourceName: sourceName,
        sourceType: sourceType,
      ),
    );
  }

  Future<void> recordGraffitiDrop({
    required DroppedGraffiti drop,
    required String sourceName,
    required String sourceType,
  }) async {
    await _appendEntry(
      _simpleEntry(
        category: 'graffiti',
        itemId: drop.graffiti.id,
        title: drop.graffiti.name,
        subtitle: GraffitiUiHelper.secondaryText(drop.graffiti),
        imagePath: drop.graffiti.graffitiImage,
        rarity: drop.graffiti.rarity,
        sourceName: sourceName,
        sourceType: sourceType,
      ),
    );
  }

  Future<void> recordPatchDrop({
    required DroppedPatch drop,
    required String sourceName,
    required String sourceType,
  }) async {
    await _appendEntry(
      _simpleEntry(
        category: 'patch',
        itemId: drop.patch.id,
        title: drop.patch.name,
        subtitle: PatchUiHelper.secondaryText(drop.patch),
        imagePath: drop.patch.patchImage,
        rarity: drop.patch.rarity,
        sourceName: sourceName,
        sourceType: sourceType,
      ),
    );
  }

  Future<void> recordCharmDrop({
    required DroppedCharm drop,
    required String sourceName,
    required String sourceType,
  }) async {
    await _appendEntry(
      _simpleEntry(
        category: 'charm',
        itemId: drop.charm.id,
        title: drop.charm.name,
        subtitle: CharmUiHelper.secondaryText(drop.charm),
        imagePath: drop.charm.charmImage,
        rarity: drop.charm.rarity,
        sourceName: sourceName,
        sourceType: sourceType,
      ),
    );
  }

  Future<void> _appendEntry(CollectionEntry entry) async {
    final entries = List<CollectionEntry>.from(await loadEntries());
    entries.insert(0, entry);
    final trimmed = entries.take(_maxEntries).toList();
    await _prefs.setString(
      _entriesKey,
      jsonEncode(trimmed.map((item) => item.toJson()).toList()),
    );
  }

  CollectionEntry _simpleEntry({
    required String category,
    required String itemId,
    required String title,
    required String subtitle,
    required String imagePath,
    required String rarity,
    required String sourceName,
    required String sourceType,
  }) {
    return CollectionEntry(
      entryId: _entryId(),
      category: category,
      filterCategory: category,
      itemId: itemId,
      stackKey: '$category:$itemId',
      title: title,
      subtitle: subtitle,
      imagePath: imagePath,
      rarity: rarity,
      sourceName: sourceName,
      sourceType: sourceType,
      acquiredAt: DateTime.now(),
      isStatTrak: false,
      isSouvenir: false,
      floatValue: null,
      exterior: null,
      patternSeed: null,
    );
  }

  CollectionEntry _entryFromSticker({
    required StickerDto sticker,
    required String sourceName,
    required String sourceType,
  }) {
    return CollectionEntry(
      entryId: _entryId(),
      category: 'sticker',
      filterCategory: 'sticker',
      itemId: sticker.id,
      stackKey: 'sticker:${sticker.id}',
      title: sticker.name,
      subtitle: StickerUiHelper.secondaryText(sticker),
      imagePath: sticker.stickerImage,
      rarity: sticker.rarity,
      sourceName: sourceName,
      sourceType: sourceType,
      acquiredAt: DateTime.now(),
      isStatTrak: false,
      isSouvenir: false,
      floatValue: null,
      exterior: null,
      patternSeed: null,
    );
  }

  String _entryId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(0x7fffffff)}';
  }

  String _skinFilterCategory(SkinDto skin) {
    if (skin.isKnife) {
      return 'knife';
    }
    if (skin.isGloves) {
      return 'gloves';
    }
    return 'skin';
  }
}
