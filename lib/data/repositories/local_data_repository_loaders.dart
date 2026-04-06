part of 'local_data_repository.dart';

mixin _LocalDataRepositoryLoaders {
  Future<List<ContainerDto>> loadContainers() async {
    final cases = await _loadDtoList(
      'assets/data/containers.json',
      ContainerDto.fromJson,
    );
    cases.sort(_compareContainerByReleaseDateAsc);
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

  Future<List<CharmDto>> loadCharms() async {
    return _loadDtoList('assets/data/charms.json', CharmDto.fromJson);
  }

  Future<List<TournamentMetadataDto>> loadTournamentMetadata() async {
    return _loadDtoList(
      'assets/data/tournament_metadata.json',
      TournamentMetadataDto.fromJson,
    );
  }

  Future<List<ContainerContentDto>> loadContainerContents() async {
    return _loadDtoList(
      'assets/data/container_contents.json',
      ContainerContentDto.fromJson,
    );
  }

  Future<List<StickerContentDto>> loadStickerContents() async {
    return _loadDtoList(
      'assets/data/sticker_contents.json',
      StickerContentDto.fromJson,
    );
  }

  Future<List<PinContentDto>> loadPinContents() async {
    return _loadDtoList(
      'assets/data/pin_contents.json',
      PinContentDto.fromJson,
    );
  }

  Future<List<MusicKitContentDto>> loadMusicKitContents() async {
    return _loadDtoList(
      'assets/data/music_kit_contents.json',
      MusicKitContentDto.fromJson,
    );
  }

  Future<List<ContainerDto>> loadAgentCollections() async {
    final items = await loadContainers();
    final result = items.where((item) => item.isAgentCollection).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
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

  Future<List<CharmContentDto>> loadCharmContents() async {
    return _loadDtoList(
      'assets/data/charm_contents.json',
      CharmContentDto.fromJson,
    );
  }

  Future<List<ContainerDto>> loadRewardCollections() async {
    final items = await loadContainers();
    final result = items.where((item) => item.isRewardCollection).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
  }

  Future<List<RewardCollectionContentDto>>
  loadRewardCollectionContents() async {
    return _loadDtoList(
      'assets/data/reward_collection_contents.json',
      RewardCollectionContentDto.fromJson,
    );
  }

  Future<List<ContainerDto>> loadOperationCollections() async {
    final items = await loadContainers();
    final result = items.where((item) => item.isOperationCollection).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
  }

  Future<List<OperationCollectionContentDto>>
  loadOperationCollectionContents() async {
    return _loadDtoList(
      'assets/data/operation_collection_contents.json',
      OperationCollectionContentDto.fromJson,
    );
  }

  Future<Map<String, List<String>>> loadContainerToSkinIds() async {
    final caseContents = await loadContainerContents();
    return {
      for (final entry in caseContents)
        entry.containerId: List<String>.from(entry.skinIds),
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
