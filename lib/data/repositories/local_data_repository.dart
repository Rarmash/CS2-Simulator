import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/case_content_dto.dart';
import '../models/case_dto.dart';
import '../models/agent_collection_content_dto.dart';
import '../models/agent_collection_dto.dart';
import '../models/agent_dto.dart';
import '../models/graffiti_content_dto.dart';
import '../models/graffiti_dto.dart';
import '../models/operation_collection_content_dto.dart';
import '../models/operation_collection_dto.dart';
import '../models/music_kit_content_dto.dart';
import '../models/music_kit_dto.dart';
import '../models/pin_content_dto.dart';
import '../models/pin_dto.dart';
import '../models/patch_content_dto.dart';
import '../models/patch_dto.dart';
import '../models/reward_collection_content_dto.dart';
import '../models/reward_collection_dto.dart';
import '../models/skin_dto.dart';
import '../models/sticker_content_dto.dart';
import '../models/sticker_dto.dart';

class LocalDataRepository {
  Future<List<CaseDto>> loadCases() async {
    final raw = await rootBundle.loadString('assets/data/cases.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final cases = list
        .map((e) => CaseDto.fromJson(e as Map<String, dynamic>))
        .toList();

    cases.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return cases;
  }

  Future<List<SkinDto>> loadSkins() async {
    final raw = await rootBundle.loadString('assets/data/skins.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SkinDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StickerDto>> loadStickers() async {
    final raw = await rootBundle.loadString('assets/data/stickers.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => StickerDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PinDto>> loadPins() async {
    final raw = await rootBundle.loadString('assets/data/pins.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => PinDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MusicKitDto>> loadMusicKits() async {
    final raw = await rootBundle.loadString('assets/data/music_kits.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MusicKitDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AgentDto>> loadAgents() async {
    final raw = await rootBundle.loadString('assets/data/agents.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AgentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GraffitiDto>> loadGraffiti() async {
    final raw = await rootBundle.loadString('assets/data/graffiti.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GraffitiDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PatchDto>> loadPatches() async {
    final raw = await rootBundle.loadString('assets/data/patches.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PatchDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseContentDto>> loadCaseContents() async {
    final raw = await rootBundle.loadString('assets/data/case_contents.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CaseContentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StickerContentDto>> loadStickerContents() async {
    final raw = await rootBundle.loadString(
      'assets/data/sticker_contents.json',
    );
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => StickerContentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PinContentDto>> loadPinContents() async {
    final raw = await rootBundle.loadString('assets/data/pin_contents.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PinContentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MusicKitContentDto>> loadMusicKitContents() async {
    final raw = await rootBundle.loadString(
      'assets/data/music_kit_contents.json',
    );
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MusicKitContentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AgentCollectionDto>> loadAgentCollections() async {
    final raw = await rootBundle.loadString('assets/data/agent_collections.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final items = list
        .map((e) => AgentCollectionDto.fromJson(e as Map<String, dynamic>))
        .toList();
    items.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });
    return items;
  }

  Future<List<AgentCollectionContentDto>> loadAgentCollectionContents() async {
    final raw = await rootBundle.loadString(
      'assets/data/agent_collection_contents.json',
    );
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) => AgentCollectionContentDto.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<GraffitiContentDto>> loadGraffitiContents() async {
    final raw = await rootBundle.loadString('assets/data/graffiti_contents.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GraffitiContentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PatchContentDto>> loadPatchContents() async {
    final raw = await rootBundle.loadString('assets/data/patch_contents.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PatchContentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RewardCollectionDto>> loadRewardCollections() async {
    final raw = await rootBundle.loadString(
      'assets/data/reward_collections.json',
    );
    final list = jsonDecode(raw) as List<dynamic>;
    final items = list
        .map((e) => RewardCollectionDto.fromJson(e as Map<String, dynamic>))
        .toList();

    items.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<List<RewardCollectionContentDto>>
  loadRewardCollectionContents() async {
    final raw = await rootBundle.loadString(
      'assets/data/reward_collection_contents.json',
    );
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) => RewardCollectionContentDto.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<OperationCollectionDto>> loadOperationCollections() async {
    final raw = await rootBundle.loadString(
      'assets/data/operation_collections.json',
    );
    final list = jsonDecode(raw) as List<dynamic>;
    final items = list
        .map((e) => OperationCollectionDto.fromJson(e as Map<String, dynamic>))
        .toList();

    items.sort((a, b) {
      final byOperation = a.operationName.compareTo(b.operationName);
      if (byOperation != 0) return byOperation;

      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<List<OperationCollectionContentDto>>
  loadOperationCollectionContents() async {
    final raw = await rootBundle.loadString(
      'assets/data/operation_collection_contents.json',
    );
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) =>
              OperationCollectionContentDto.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Map<String, List<String>>> loadCaseToSkinIds() async {
    final caseContents = await loadCaseContents();
    return {
      for (final entry in caseContents)
        entry.caseId: List<String>.from(entry.skinIds),
    };
  }

  Future<Map<String, List<String>>> loadRewardCollectionToSkinIds() async {
    final contents = await loadRewardCollectionContents();
    return {
      for (final entry in contents)
        entry.rewardCollectionId: List<String>.from(entry.skinIds),
    };
  }

  Future<Map<String, List<String>>> loadOperationCollectionToSkinIds() async {
    final contents = await loadOperationCollectionContents();
    return {
      for (final entry in contents)
        entry.operationCollectionId: List<String>.from(entry.skinIds),
    };
  }

  Future<List<SkinDto>> loadSkinsForCase(String caseId) async {
    final skins = await loadSkins();
    final contents = await loadCaseContents();
    final content = contents.firstWhere((c) => c.caseId == caseId);
    final ids = content.skinIds.toSet();

    final result = skins.where((s) => ids.contains(s.id)).toList();

    result.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  Future<List<StickerDto>> loadStickersForCase(String caseId) async {
    final stickers = await loadStickers();
    final contents = await loadStickerContents();
    final content = contents.firstWhere((c) => c.caseId == caseId);
    final ids = content.stickerIds.toSet();

    final result = stickers.where((s) => ids.contains(s.id)).toList();

    result.sort((a, b) {
      final rarityCompare = _stickerRarityOrder(
        a,
      ).compareTo(_stickerRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  Future<List<PinDto>> loadPinsForCase(String caseId) async {
    final pins = await loadPins();
    final contents = await loadPinContents();
    final content = contents.firstWhere((c) => c.caseId == caseId);
    final ids = content.pinIds.toSet();

    final result = pins.where((p) => ids.contains(p.id)).toList();

    result.sort((a, b) {
      final rarityCompare = _pinRarityOrder(a).compareTo(_pinRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  Future<List<MusicKitDto>> loadMusicKitsForCase(String caseId) async {
    final musicKits = await loadMusicKits();
    final contents = await loadMusicKitContents();
    final content = contents.firstWhere((c) => c.caseId == caseId);
    final ids = content.musicKitIds.toSet();

    final result = musicKits.where((m) => ids.contains(m.id)).toList();

    result.sort((a, b) {
      final rarityCompare = _musicKitRarityOrder(
        a,
      ).compareTo(_musicKitRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      final statTrakCompare = a.isStatTrak == b.isStatTrak
          ? 0
          : (a.isStatTrak ? 1 : -1);
      if (statTrakCompare != 0) return statTrakCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  Future<List<GraffitiDto>> loadGraffitiForCase(String caseId) async {
    final graffiti = await loadGraffiti();
    final contents = await loadGraffitiContents();
    final content = contents.firstWhere((c) => c.caseId == caseId);
    final ids = content.graffitiIds.toSet();

    final result = graffiti.where((g) => ids.contains(g.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _graffitiRarityOrder(a).compareTo(
        _graffitiRarityOrder(b),
      );
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<PatchDto>> loadPatchesForCase(String caseId) async {
    final patches = await loadPatches();
    final contents = await loadPatchContents();
    final content = contents.firstWhere((c) => c.caseId == caseId);
    final ids = content.patchIds.toSet();

    final result = patches.where((p) => ids.contains(p.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _patchRarityOrder(a).compareTo(_patchRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<AgentDto>> loadAgentsForCollection(String agentCollectionId) async {
    final agents = await loadAgents();
    final contents = await loadAgentCollectionContents();
    final content = contents.firstWhere(
      (c) => c.agentCollectionId == agentCollectionId,
    );
    final ids = content.agentIds.toSet();

    final result = agents.where((a) => ids.contains(a.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _agentRarityOrder(a).compareTo(_agentRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<SkinDto>> loadSkinsForRewardCollection(
    String rewardCollectionId,
  ) async {
    final skins = await loadSkins();
    final contents = await loadRewardCollectionContents();
    final content = contents.firstWhere(
      (c) => c.rewardCollectionId == rewardCollectionId,
    );
    final ids = content.skinIds.toSet();

    final result = skins
        .where((s) => ids.contains(s.id) && !s.isSpecialItem)
        .toList();

    result.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  Future<List<SkinDto>> loadSkinsForOperationCollection(
    String operationCollectionId,
  ) async {
    final skins = await loadSkins();
    final contents = await loadOperationCollectionContents();
    final content = contents.firstWhere(
      (c) => c.operationCollectionId == operationCollectionId,
    );
    final ids = content.skinIds.toSet();

    final result = skins
        .where((s) => ids.contains(s.id) && !s.isSpecialItem)
        .toList();

    result.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  Future<List<CaseDto>> loadCasesForSkin(String skinId) async {
    final cases = await loadCases();
    final contents = await loadCaseContents();

    final caseIds = contents
        .where((entry) => entry.skinIds.contains(skinId))
        .map((entry) => entry.caseId)
        .toSet();

    final result = cases.where((c) => caseIds.contains(c.id)).toList();

    result.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return result;
  }

  Future<List<CaseDto>> loadCasesForSticker(String stickerId) async {
    final cases = await loadCases();
    final contents = await loadStickerContents();

    final caseIds = contents
        .where((entry) => entry.stickerIds.contains(stickerId))
        .map((entry) => entry.caseId)
        .toSet();

    final result = cases.where((c) => caseIds.contains(c.id)).toList();

    result.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return result;
  }

  Future<List<CaseDto>> loadStickerCollections() async {
    final cases = await loadCases();
    final result = cases.where((c) => c.isStickerCollection).toList();

    result.sort((a, b) {
      final sourceA = a.sourceType ?? '';
      final sourceB = b.sourceType ?? '';
      final bySource = sourceA.compareTo(sourceB);
      if (bySource != 0) return bySource;

      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return result;
  }

  Future<List<CaseDto>> loadPatchCollections() async {
    final cases = await loadCases();
    final result = cases.where((c) => c.isPatchCollection).toList();

    result.sort((a, b) {
      final sourceA = a.sourceType ?? '';
      final sourceB = b.sourceType ?? '';
      final bySource = sourceA.compareTo(sourceB);
      if (bySource != 0) return bySource;

      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return result;
  }

  int _agentRarityOrder(AgentDto agent) {
    switch (agent.rarity) {
      case 'DISTINGUISHED':
        return 0;
      case 'EXCEPTIONAL':
        return 1;
      case 'SUPERIOR':
        return 2;
      case 'MASTER':
        return 3;
      default:
        return 99;
    }
  }

  int _graffitiRarityOrder(GraffitiDto graffiti) {
    switch (graffiti.rarity) {
      case 'BASE_GRADE':
        return 0;
      case 'HIGH_GRADE':
        return 1;
      case 'REMARKABLE':
        return 2;
      case 'EXOTIC':
        return 3;
      default:
        return 99;
    }
  }

  int _patchRarityOrder(PatchDto patch) {
    switch (patch.rarity) {
      case 'HIGH_GRADE':
        return 0;
      case 'REMARKABLE':
        return 1;
      case 'EXOTIC':
        return 2;
      default:
        return 99;
    }
  }

  Future<List<RewardCollectionDto>> loadRewardCollectionsForSkin(
    String skinId,
  ) async {
    final collections = await loadRewardCollections();
    final contents = await loadRewardCollectionContents();

    final ids = contents
        .where((entry) => entry.skinIds.contains(skinId))
        .map((entry) => entry.rewardCollectionId)
        .toSet();

    final result = collections.where((c) => ids.contains(c.id)).toList();

    result.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return result;
  }

  Future<List<OperationCollectionDto>> loadOperationCollectionsForSkin(
    String skinId,
  ) async {
    final collections = await loadOperationCollections();
    final contents = await loadOperationCollectionContents();

    final ids = contents
        .where((entry) => entry.skinIds.contains(skinId))
        .map((entry) => entry.operationCollectionId)
        .toSet();

    final result = collections.where((c) => ids.contains(c.id)).toList();

    result.sort((a, b) {
      final byOperation = a.operationName.compareTo(b.operationName);
      if (byOperation != 0) return byOperation;

      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;

      return a.name.compareTo(b.name);
    });

    return result;
  }

  int _rarityOrder(SkinDto skin) {
    if (skin.isSpecialItem) return 7;

    switch (skin.rarity) {
      case 'CONSUMER':
        return 0;
      case 'INDUSTRIAL':
        return 1;
      case 'MIL_SPEC':
        return 2;
      case 'RESTRICTED':
        return 3;
      case 'CLASSIFIED':
        return 4;
      case 'COVERT':
        return 5;
      case 'CONTRABAND':
        return 6;
      case 'EXTRAORDINARY':
        return 7;
      default:
        return 999;
    }
  }

  int _stickerRarityOrder(StickerDto sticker) {
    switch (sticker.rarity) {
      case 'HIGH_GRADE':
        return 0;
      case 'REMARKABLE':
        return 1;
      case 'EXOTIC':
        return 2;
      case 'EXTRAORDINARY':
        return 3;
      case 'CONTRABAND':
        return 4;
      default:
        return 999;
    }
  }

  int _pinRarityOrder(PinDto pin) {
    switch (pin.rarity) {
      case 'HIGH_GRADE':
        return 0;
      case 'REMARKABLE':
        return 1;
      case 'EXOTIC':
        return 2;
      case 'EXTRAORDINARY':
        return 3;
      default:
        return 999;
    }
  }

  int _musicKitRarityOrder(MusicKitDto musicKit) {
    switch (musicKit.rarity) {
      case 'HIGH_GRADE':
        return 0;
      default:
        return 999;
    }
  }
}
