part of 'local_data_repository.dart';

mixin _LocalDataRepositoryLoaders {
  Future<List<CaseDto>> loadCases() async {
    final cases = await _loadDtoList('assets/data/cases.json', CaseDto.fromJson);
    cases.sort(_compareCaseByReleaseDateAsc);
    return cases;
  }

  Future<List<SkinDto>> loadSkins() async {
    return _loadDtoList('assets/data/skins.json', SkinDto.fromJson);
  }

  Future<List<StickerDto>> loadStickers() async {
    return _loadDtoList('assets/data/stickers.json', StickerDto.fromJson);
  }

  Future<List<PinDto>> loadPins() async {
    return _loadDtoList('assets/data/pins.json', PinDto.fromJson);
  }

  Future<List<MusicKitDto>> loadMusicKits() async {
    return _loadDtoList('assets/data/music_kits.json', MusicKitDto.fromJson);
  }

  Future<List<AgentDto>> loadAgents() async {
    return _loadDtoList('assets/data/agents.json', AgentDto.fromJson);
  }

  Future<List<GraffitiDto>> loadGraffiti() async {
    return _loadDtoList('assets/data/graffiti.json', GraffitiDto.fromJson);
  }

  Future<List<PatchDto>> loadPatches() async {
    return _loadDtoList('assets/data/patches.json', PatchDto.fromJson);
  }

  Future<List<CaseContentDto>> loadCaseContents() async {
    return _loadDtoList('assets/data/case_contents.json', CaseContentDto.fromJson);
  }

  Future<List<StickerContentDto>> loadStickerContents() async {
    return _loadDtoList(
      'assets/data/sticker_contents.json',
      StickerContentDto.fromJson,
    );
  }

  Future<List<PinContentDto>> loadPinContents() async {
    return _loadDtoList('assets/data/pin_contents.json', PinContentDto.fromJson);
  }

  Future<List<MusicKitContentDto>> loadMusicKitContents() async {
    return _loadDtoList(
      'assets/data/music_kit_contents.json',
      MusicKitContentDto.fromJson,
    );
  }

  Future<List<AgentCollectionDto>> loadAgentCollections() async {
    final items = await _loadDtoList(
      'assets/data/agent_collections.json',
      AgentCollectionDto.fromJson,
    );
    items.sort(_compareNamedReleaseDateAsc);
    return items;
  }

  Future<List<AgentCollectionContentDto>> loadAgentCollectionContents() async {
    return _loadDtoList(
      'assets/data/agent_collection_contents.json',
      AgentCollectionContentDto.fromJson,
    );
  }

  Future<List<GraffitiContentDto>> loadGraffitiContents() async {
    return _loadDtoList(
      'assets/data/graffiti_contents.json',
      GraffitiContentDto.fromJson,
    );
  }

  Future<List<PatchContentDto>> loadPatchContents() async {
    return _loadDtoList(
      'assets/data/patch_contents.json',
      PatchContentDto.fromJson,
    );
  }

  Future<List<RewardCollectionDto>> loadRewardCollections() async {
    final items = await _loadDtoList(
      'assets/data/reward_collections.json',
      RewardCollectionDto.fromJson,
    );
    items.sort(_compareNamedReleaseDateAsc);
    return items;
  }

  Future<List<RewardCollectionContentDto>> loadRewardCollectionContents() async {
    return _loadDtoList(
      'assets/data/reward_collection_contents.json',
      RewardCollectionContentDto.fromJson,
    );
  }

  Future<List<OperationCollectionDto>> loadOperationCollections() async {
    final items = await _loadDtoList(
      'assets/data/operation_collections.json',
      OperationCollectionDto.fromJson,
    );
    items.sort(_compareOperationCollectionAsc);
    return items;
  }

  Future<List<OperationCollectionContentDto>>
  loadOperationCollectionContents() async {
    return _loadDtoList(
      'assets/data/operation_collection_contents.json',
      OperationCollectionContentDto.fromJson,
    );
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
}

Future<List<T>> _loadDtoList<T>(
  String assetPath,
  T Function(Map<String, dynamic> json) fromJson,
) async {
  final raw = await rootBundle.loadString(assetPath);
  final list = jsonDecode(raw) as List<dynamic>;
  return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
