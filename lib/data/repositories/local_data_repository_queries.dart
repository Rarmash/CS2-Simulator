part of 'local_data_repository.dart';

mixin _LocalDataRepositoryQueries on _LocalDataRepositoryLoaders {
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
      final rarityCompare = _stickerRarityOrder(a).compareTo(
        _stickerRarityOrder(b),
      );
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
      final rarityCompare = _musicKitRarityOrder(a).compareTo(
        _musicKitRarityOrder(b),
      );
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
    result.sort(_compareCaseByReleaseDateAsc);
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
    result.sort(_compareCaseByReleaseDateAsc);
    return result;
  }

  Future<List<CaseDto>> loadStickerCollections() async {
    final cases = await loadCases();
    final result = cases.where((c) => c.isStickerCollection).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
  }

  Future<List<CaseDto>> loadPatchCollections() async {
    final cases = await loadCases();
    final result = cases.where((c) => c.isPatchCollection).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
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
    result.sort(_compareNamedReleaseDateAsc);
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
    result.sort(_compareOperationCollectionAsc);
    return result;
  }
}
