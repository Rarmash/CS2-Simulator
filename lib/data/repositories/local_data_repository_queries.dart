part of 'local_data_repository.dart';

mixin _LocalDataRepositoryQueries on _LocalDataRepositoryLoaders {
  Future<List<SkinDto>> loadSkinsForContainer(String containerId) async {
    final skins = await loadSkins();
    final contents = await loadContainerContents();
    final content = contents.firstWhere((c) => c.containerId == containerId);
    final ids = content.skinIds.toSet();

    final result = skins.where((s) => ids.contains(s.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<StickerDto>> loadStickersForContainer(String containerId) async {
    final stickers = await loadStickers();
    final contents = await loadStickerContents();
    final content = contents.firstWhere((c) => c.containerId == containerId);
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

  Future<List<PinDto>> loadPinsForContainer(String containerId) async {
    final pins = await loadPins();
    final contents = await loadPinContents();
    final content = contents.firstWhere((c) => c.containerId == containerId);
    final ids = content.pinIds.toSet();

    final result = pins.where((p) => ids.contains(p.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _pinRarityOrder(a).compareTo(_pinRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<MusicKitDto>> loadMusicKitsForContainer(
    String containerId,
  ) async {
    final musicKits = await loadMusicKits();
    final contents = await loadMusicKitContents();
    final content = contents.firstWhere((c) => c.containerId == containerId);
    final entriesById = {
      for (final entry in content.items) entry.musicKitId: entry,
    };

    final result = musicKits.where((m) => entriesById.containsKey(m.id)).map((
      musicKit,
    ) {
      final entry = entriesById[musicKit.id]!;
      return musicKit.copyWith(
        hasRegular: entry.hasRegular,
        hasStatTrak: entry.hasStatTrak,
      );
    }).toList();
    result.sort((a, b) {
      final rarityCompare = _musicKitRarityOrder(
        a,
      ).compareTo(_musicKitRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      final variantCompare = _musicKitVariantOrder(
        a,
      ).compareTo(_musicKitVariantOrder(b));
      if (variantCompare != 0) return variantCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<MusicKitGroupDto>> loadGroupedMusicKits() async {
    final musicKits = await loadMusicKits();
    final grouped = <String, List<MusicKitDto>>{};

    for (final musicKit in musicKits) {
      final key =
          '${musicKit.name.trim().toLowerCase()}|${(musicKit.collection ?? '').trim().toLowerCase()}';
      grouped.putIfAbsent(key, () => <MusicKitDto>[]).add(musicKit);
    }

    final result = grouped.values.map(MusicKitGroupDto.fromVariants).toList();

    result.sort((a, b) {
      final rarityCompare = _musicKitRarityOrder(
        a.primary,
      ).compareTo(_musicKitRarityOrder(b.primary));
      if (rarityCompare != 0) return rarityCompare;
      final statTrakCompare = a.hasStatTrak == b.hasStatTrak
          ? 0
          : (a.hasStatTrak ? 1 : -1);
      if (statTrakCompare != 0) return statTrakCompare;
      return a.trackName.compareTo(b.trackName);
    });

    return result;
  }

  Future<MusicKitGroupDto?> loadMusicKitGroup(
    String musicKitName,
    String? collection,
  ) async {
    final groups = await loadGroupedMusicKits();
    final normalizedCollection = (collection ?? '').trim().toLowerCase();

    for (final group in groups) {
      if (group.name == musicKitName &&
          (group.collection ?? '').trim().toLowerCase() ==
              normalizedCollection) {
        return group;
      }
    }

    return null;
  }

  Future<List<GraffitiDto>> loadGraffitiForContainer(String containerId) async {
    final graffiti = await loadGraffiti();
    final contents = await loadGraffitiContents();
    final content = contents.firstWhere((c) => c.containerId == containerId);
    final ids = content.graffitiIds.toSet();

    final result = graffiti.where((g) => ids.contains(g.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _graffitiRarityOrder(
        a,
      ).compareTo(_graffitiRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<PatchDto>> loadPatchesForContainer(String containerId) async {
    final patches = await loadPatches();
    final contents = await loadPatchContents();
    final content = contents.firstWhere((c) => c.containerId == containerId);
    final ids = content.patchIds.toSet();

    final result = patches.where((p) => ids.contains(p.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _patchRarityOrder(
        a,
      ).compareTo(_patchRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<CharmDto>> loadCharmsForContainer(String containerId) async {
    final charms = await loadCharms();
    final contents = await loadCharmContents();
    final content = contents.firstWhere((c) => c.containerId == containerId);
    final ids = content.charmIds.toSet();

    final result = charms.where((c) => ids.contains(c.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _charmRarityOrder(
        a,
      ).compareTo(_charmRarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });
    return result;
  }

  Future<List<AgentDto>> loadAgentsForCollection(
    String agentCollectionId,
  ) async {
    final agents = await loadAgents();
    final contents = await loadAgentCollectionContents();
    final content = contents.firstWhere(
      (c) => c.agentCollectionId == agentCollectionId,
    );
    final ids = content.agentIds.toSet();

    final result = agents.where((a) => ids.contains(a.id)).toList();
    result.sort((a, b) {
      final rarityCompare = _agentRarityOrder(
        a,
      ).compareTo(_agentRarityOrder(b));
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

  Future<List<ContainerDto>> loadContainersForSkin(String skinId) async {
    final containers = await loadContainers();
    final contents = await loadContainerContents();

    final containerIds = contents
        .where((entry) => entry.skinIds.contains(skinId))
        .map((entry) => entry.containerId)
        .toSet();

    final result = containers
        .where((c) => containerIds.contains(c.id))
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<ContainerDto>> loadContainersForSticker(String stickerId) async {
    final containers = await loadContainers();
    final contents = await loadStickerContents();

    final containerIds = contents
        .where((entry) => entry.stickerIds.contains(stickerId))
        .map((entry) => entry.containerId)
        .toSet();

    final result = containers
        .where((c) => containerIds.contains(c.id))
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<ContainerDto>> loadContainersForPin(String pinId) async {
    final containers = await loadContainers();
    final contents = await loadPinContents();

    final containerIds = contents
        .where((entry) => entry.pinIds.contains(pinId))
        .map((entry) => entry.containerId)
        .toSet();

    final result = containers
        .where((c) => containerIds.contains(c.id))
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<ContainerDto>> loadContainersForMusicKit(
    String musicKitId,
  ) async {
    final containers = await loadContainers();
    final contents = await loadMusicKitContents();

    final containerIds = contents
        .where(
          (entry) => entry.items.any((item) => item.musicKitId == musicKitId),
        )
        .map((entry) => entry.containerId)
        .toSet();

    final result = containers
        .where((c) => containerIds.contains(c.id))
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<ContainerDto>> loadContainersForMusicKitGroup(
    String musicKitName,
    String? collection,
  ) async {
    final group = await loadMusicKitGroup(musicKitName, collection);
    if (group == null) return const [];

    final seenContainerIds = <String>{};
    final containers = <ContainerDto>[];

    for (final variant in group.variants) {
      final sources = await loadContainersForMusicKit(variant.id);
      for (final container in sources) {
        if (seenContainerIds.add(container.id)) {
          containers.add(container);
        }
      }
    }

    containers.sort(_compareContainerByReleaseDateAsc);
    return containers;
  }

  Future<List<ContainerDto>> loadContainersForGraffiti(
    String graffitiId,
  ) async {
    final containers = await loadContainers();
    final contents = await loadGraffitiContents();

    final containerIds = contents
        .where((entry) => entry.graffitiIds.contains(graffitiId))
        .map((entry) => entry.containerId)
        .toSet();

    final result = containers
        .where((c) => containerIds.contains(c.id))
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<ContainerDto>> loadContainersForPatch(String patchId) async {
    final containers = await loadContainers();
    final contents = await loadPatchContents();

    final containerIds = contents
        .where((entry) => entry.patchIds.contains(patchId))
        .map((entry) => entry.containerId)
        .toSet();

    final result = containers
        .where((c) => containerIds.contains(c.id))
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<ContainerDto>> loadContainersForCharm(String charmId) async {
    final containers = await loadContainers();
    final contents = await loadCharmContents();

    final containerIds = contents
        .where((entry) => entry.charmIds.contains(charmId))
        .map((entry) => entry.containerId)
        .toSet();

    final result = containers
        .where((c) => containerIds.contains(c.id))
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<ContainerDto>> loadAgentCollectionsForAgent(
    String agentId,
  ) async {
    final collections = await loadAgentCollections();
    final contents = await loadAgentCollectionContents();

    final ids = contents
        .where((entry) => entry.agentIds.contains(agentId))
        .map((entry) => entry.agentCollectionId)
        .toSet();

    final result = collections.where((c) => ids.contains(c.id)).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
  }

  Future<List<ContainerDto>> loadStickerCollections() async {
    final containers = await loadContainers();
    final result = containers.where((c) => c.isStickerCollection).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
  }

  Future<List<ContainerDto>> loadPatchCollections() async {
    final containers = await loadContainers();
    final result = containers.where((c) => c.isPatchCollection).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
  }

  Future<List<ContainerDto>> loadCharmCollections() async {
    final containers = await loadContainers();
    final result = containers.where((c) => c.isCharmCollection).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
  }

  Future<List<ContainerDto>> loadRewardCollectionsForSkin(String skinId) async {
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

  Future<List<ContainerDto>> loadOperationCollectionsForSkin(
    String skinId,
  ) async {
    final collections = await loadOperationCollections();
    final contents = await loadOperationCollectionContents();

    final ids = contents
        .where((entry) => entry.skinIds.contains(skinId))
        .map((entry) => entry.operationCollectionId)
        .toSet();

    final result = collections.where((c) => ids.contains(c.id)).toList();
    result.sort(_compareCollectibleCollectionAsc);
    return result;
  }
}
