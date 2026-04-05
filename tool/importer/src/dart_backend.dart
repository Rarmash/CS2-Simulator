import 'dart:io';

import 'backend.dart';
import 'config.dart';
import 'io_utils.dart';
import 'normalization.dart';

class DartImporterBackend implements ImporterBackend {
  DartImporterBackend(this._io);

  final IoUtils _io;

  @override
  Future<void> run() async {
    await _io.ensureDirs();
    await _io.resetCollectibleOutputs();

    final rewardSourceOverrides = _loadRewardOverrides();
    final operationCollectionOverrides = _loadOperationOverrides();

    final allExistingCases = _io
        .loadJsonList(File('${dataDir.path}/containers.json'))
        .map(_normalizeExistingContainerMeta)
        .toList();
    final existingSkins = _io.loadJsonList(File('${dataDir.path}/skins.json'));
    final existingStickers = _io.loadJsonList(
      File('${dataDir.path}/stickers.json'),
    );
    final existingPins = _io.loadJsonList(File('${dataDir.path}/pins.json'));
    final existingMusicKits = _io.loadJsonList(
      File('${dataDir.path}/music_kits.json'),
    );
    final existingAgents = _io.loadJsonList(
      File('${dataDir.path}/agents.json'),
    );
    final existingGraffiti = _io.loadJsonList(
      File('${dataDir.path}/graffiti.json'),
    );
    final existingPatches = _io.loadJsonList(
      File('${dataDir.path}/patches.json'),
    );
    final existingCharms = _io.loadJsonList(
      File('${dataDir.path}/charms.json'),
    );
    final existingCases = allExistingCases.where((item) {
      final type = (item['type'] ?? '').toString().trim().toUpperCase();
      return !{
        'STICKER_CAPSULE',
        'STICKER_COLLECTION',
        'PIN_CAPSULE',
        'MUSIC_KIT_BOX',
      }.contains(type);
    }).toList();
    final existingRewardCollections = allExistingCases
        .where(
          (item) =>
              (item['type'] ?? '').toString().trim().toUpperCase() ==
              'REWARD_COLLECTION',
        )
        .map(
          (item) => <String, dynamic>{
            'id': item['id'],
            'name': item['name'],
            'image': item['containerImage'],
            'sourceType': (item['sourceType'] ?? '') == 'ARMORY_REWARD'
                ? 'ARMORY'
                : 'OPERATION',
            'sourceId': item['sourceId'],
            'currency': item['currency'],
            'cost': item['cost'],
            'releaseDate': item['releaseDate'],
          },
        )
        .toList();
    final existingOperationCollections = allExistingCases
        .where(
          (item) =>
              (item['type'] ?? '').toString().trim().toUpperCase() ==
              'OPERATION_COLLECTION',
        )
        .map(
          (item) => <String, dynamic>{
            'id': item['id'],
            'name': item['name'],
            'image': item['containerImage'],
            'operationId': item['sourceId'],
            'operationName': item['sourceName'],
            'releaseDate': item['releaseDate'],
          },
        )
        .toList();
    final existingAgentCollections = allExistingCases
        .where(
          (item) =>
              (item['type'] ?? '').toString().trim().toUpperCase() ==
              'AGENT_COLLECTION',
        )
        .map(
          (item) => <String, dynamic>{
            'id': item['id'],
            'name': item['name'],
            'image': item['containerImage'],
            'operationId': item['sourceId'],
            'operationName': item['sourceName'],
            'releaseDate': item['releaseDate'],
          },
        )
        .toList();

    final existingSkinByKey =
        <(String, String, String, String), Map<String, dynamic>>{
          for (final s in existingSkins)
            existingSkinKey(s): Map<String, dynamic>.from(s),
        };
    final existingStickerByKey =
        <(String, String, String, String), Map<String, dynamic>>{
          for (final s in existingStickers)
            existingStickerKey(s): Map<String, dynamic>.from(s),
        };
    final existingPinByKey = <(String, String), Map<String, dynamic>>{
      for (final p in existingPins)
        existingPinKey(p): Map<String, dynamic>.from(p),
    };
    final existingMusicKitByKey = <(String, String), Map<String, dynamic>>{
      for (final m in existingMusicKits)
        existingMusicKitKey(m): Map<String, dynamic>.from(m),
    };
    final existingAgentByKey = <(String, String, String), Map<String, dynamic>>{
      for (final a in existingAgents)
        existingAgentKey(a): Map<String, dynamic>.from(a),
    };
    final existingGraffitiByKey = <(String, String), Map<String, dynamic>>{
      for (final g in existingGraffiti)
        existingGraffitiKey(g): Map<String, dynamic>.from(g),
    };
    final existingPatchByKey = <(String, String), Map<String, dynamic>>{
      for (final p in existingPatches)
        existingPatchKey(p): Map<String, dynamic>.from(p),
    };
    final existingCharmByKey = <(String, String), Map<String, dynamic>>{
      for (final c in existingCharms)
        existingCharmKey(c): Map<String, dynamic>.from(c),
    };
    final existingCaseByName = <String, Map<String, dynamic>>{
      for (final c in allExistingCases)
        existingCaseKey(c): Map<String, dynamic>.from(c),
    };
    final existingRewardByKey = <String, Map<String, dynamic>>{
      for (final c in existingRewardCollections)
        rewardKeyFromItem(c): Map<String, dynamic>.from(c),
    };
    final existingOperationByKey = <String, Map<String, dynamic>>{
      for (final c in existingOperationCollections)
        operationKey(
          (c['name'] ?? '').toString(),
          (c['operationId'] ?? '').toString(),
        ): Map<String, dynamic>.from(
          c,
        ),
    };
    final existingAgentCollectionByKey = <String, Map<String, dynamic>>{
      for (final c in existingAgentCollections)
        operationKey(
          (c['name'] ?? '').toString(),
          (c['operationId'] ?? '').toString(),
        ): Map<String, dynamic>.from(
          c,
        ),
    };

    final usedSkinIds = _extractUsedIds(existingSkins);
    final usedStickerIds = _extractUsedIds(existingStickers);
    final usedPinIds = _extractUsedIds(existingPins);
    final usedMusicKitIds = _extractUsedIds(existingMusicKits);
    final usedAgentIds = _extractUsedIds(existingAgents);
    final usedGraffitiIds = _extractUsedIds(existingGraffiti);
    final usedPatchIds = _extractUsedIds(existingPatches);
    final usedCharmIds = _extractUsedIds(existingCharms);
    final usedCaseIds = _extractUsedIds(allExistingCases);
    final usedRewardIds = _extractUsedIds(existingRewardCollections);
    final usedOperationIds = _extractUsedIds(existingOperationCollections);
    final usedAgentCollectionIds = _extractUsedIds(existingAgentCollections);

    var nextSkinId = _nextId(usedSkinIds, 0);
    var nextStickerId = _nextId(usedStickerIds, 900000000);
    var nextPinId = _nextId(usedPinIds, 950000000);
    var nextMusicKitId = _nextId(usedMusicKitIds, 970000000);
    var nextAgentId = _nextId(usedAgentIds, 980000000);
    var nextGraffitiId = _nextId(usedGraffitiIds, 990000000);
    var nextPatchId = _nextId(usedPatchIds, 995000000);
    var nextCharmId = _nextId(usedCharmIds, 996000000);
    var nextCaseId = _nextId(usedCaseIds, 0);
    var nextRewardId = _nextId(usedRewardIds, 10000);
    var nextOperationId = _nextId(usedOperationIds, 20000);
    var nextAgentCollectionId = _nextId(usedAgentCollectionIds, 30000);

    _io.printInfo('Fetching crates.json ...');
    final crates = _asJsonList(await _io.fetchJson(cratesUrl));
    _io.printInfo('Fetching skins.json ...');
    final skinsData = _asJsonList(await _io.fetchJson(skinsUrl));
    _io.printInfo('Fetching collections.json ...');
    final collectionsData = _asJsonList(await _io.fetchJson(collectionsUrl));
    _io.printInfo('Fetching stickers.json ...');
    final stickersData = _asJsonList(await _io.fetchJson(stickersUrl));
    _io.printInfo('Fetching music_kits.json ...');
    final musicKitsData = _asJsonList(await _io.fetchJson(musicKitsUrl));
    _io.printInfo('Fetching agents.json ...');
    final agentsData = _asJsonList(await _io.fetchJson(agentsUrl));
    _io.printInfo('Fetching graffiti.json ...');
    final graffitiData = _asJsonList(await _io.fetchJson(graffitiUrl));
    _io.printInfo('Fetching patches.json ...');
    final patchesData = _asJsonList(await _io.fetchJson(patchesUrl));
    _io.printInfo('Fetching keychains.json ...');
    final keychainsData = _asJsonList(await _io.fetchJson(keychainsUrl));

    final collectionImageByName = buildCollectionImageMap(skinsData);
    buildCollectionMetaMap(collectionsData);
    final tournamentLogoByName = buildTournamentLogoMap(stickersData);

    _io.printInfo('Tournament logo candidates: ${tournamentLogoByName.length}');

    final newCases = <String, Map<String, dynamic>>{
      for (final c in existingCases)
        c['id'].toString(): Map<String, dynamic>.from(c),
    };
    final caseNameToId = <String, String>{
      for (final c in existingCases)
        (c['name'] ?? '').toString().trim(): (c['id'] ?? '').toString(),
    };
    final newRewardCollections = <String, Map<String, dynamic>>{
      for (final c in existingRewardCollections)
        c['id'].toString(): Map<String, dynamic>.from(c),
    };
    final rewardNameToId = <String, String>{
      for (final c in existingRewardCollections)
        rewardKeyFromItem(c): (c['id'] ?? '').toString(),
    };
    final newOperationCollections = <String, Map<String, dynamic>>{
      for (final c in existingOperationCollections)
        c['id'].toString(): Map<String, dynamic>.from(c),
    };
    final operationKeyToId = <String, String>{
      for (final c in existingOperationCollections)
        operationKey(
          (c['name'] ?? '').toString(),
          (c['operationId'] ?? '').toString(),
        ): (c['id'] ?? '')
            .toString(),
    };
    final newAgentCollections = <String, Map<String, dynamic>>{
      for (final c in existingAgentCollections)
        c['id'].toString(): Map<String, dynamic>.from(c),
    };
    final agentCollectionKeyToId = <String, String>{
      for (final c in existingAgentCollections)
        operationKey(
          (c['name'] ?? '').toString(),
          (c['operationId'] ?? '').toString(),
        ): (c['id'] ?? '')
            .toString(),
    };

    final supportedCrates = crates.where(isSupportedContainer).toList()
      ..sort(
        (a, b) => ((a['name'] ?? '').toString()).compareTo(
          (b['name'] ?? '').toString(),
        ),
      );

    final unresolvedReleaseDates = <String>[];
    for (final crate in supportedCrates) {
      final crateName = (crate['name'] ?? '').toString().trim();
      if (crateName.isEmpty) {
        continue;
      }

      final containerType = inferContainerType(
        crateName,
        crate['type']?.toString(),
      );
      final releaseDate = resolveContainerReleaseDate(
        crateName: crateName,
        containerType: containerType,
      );
      if (releaseDate == '2000-01-01') {
        unresolvedReleaseDates.add('$containerType: $crateName');
      }
    }

    if (unresolvedReleaseDates.isNotEmpty) {
      throw StateError(
        'Missing hardcoded release dates for supported containers:\n'
        '${unresolvedReleaseDates.take(20).join('\n')}',
      );
    }

    var tournamentLogosCreated = 0;
    for (final crate in supportedCrates) {
      final crateName = (crate['name'] ?? '').toString().trim();
      if (crateName.isEmpty) {
        continue;
      }

      final existingCase = existingCaseByName[crateName];
      final containerId = existingCase != null
          ? existingCase['id'].toString()
          : (nextCaseId++).toString();
      var releaseDate = existingCase?['releaseDate'];
      final containerType = inferContainerType(
        crateName,
        crate['type']?.toString(),
      );
      releaseDate = resolveContainerReleaseDate(
        crateName: crateName,
        containerType: containerType,
        crateMeta: crate,
        existingReleaseDate: releaseDate,
      );

      String? tournamentName;
      String? tournamentLogoRel;

      if (containerType == 'SOUVENIR_PACKAGE') {
        final resolved = resolveSouvenirLogoAndName(
          crateName,
          tournamentLogoByName,
        );
        tournamentName = resolved.$1;
        final tournamentLogoUrl = resolved.$2;

        if (tournamentName != null) {
          final logoSlug = makeSafeSlug(tournamentName);
          final existingLogoRel = findExistingLogoPathBySlug(logoSlug);
          if (existingLogoRel != null) {
            tournamentLogoRel = existingLogoRel;
          } else if (tournamentLogoUrl != null) {
            final ext = await _io.downloadFileWithRealExtension(
              tournamentLogoUrl,
              '${tournamentLogosDir.path}/$logoSlug',
            );
            if (ext != null) {
              tournamentLogoRel = 'assets/tournament_logos/$logoSlug$ext';
              tournamentLogosCreated += 1;
            }
          }
        }
      }

      final containerImagePath = await _syncAsset(
        imageUrl: crate['image']?.toString(),
        dirPath: containersDir.path,
        relativeDir: 'assets/containers',
        id: containerId,
        existingRelativePath: existingCase?['containerImage']?.toString(),
      );
      final patchCollectionSource = containerType == 'PATCH_COLLECTION'
          ? resolvePatchCollectionSource(crateName)
          : const <String, String?>{};

      final caseRecord = <String, dynamic>{
        'id': containerId,
        'name': crateName,
        'containerImage': containerImagePath,
        'releaseDate': releaseDate,
        'type': containerType,
        'tournamentName': tournamentName,
        'tournamentLogo': tournamentLogoRel,
        'sourceType': patchCollectionSource['sourceType'],
        'sourceId': patchCollectionSource['sourceId'],
        'sourceName': patchCollectionSource['sourceName'],
      };

      newCases[containerId] = caseRecord;
      caseNameToId[crateName] = containerId;
    }

    final charmCollections =
        collectionsData.where((collection) {
          final name = (collection['name'] ?? '').toString().trim();
          final contains = collection['contains'];
          return name.endsWith('Charm Collection') &&
              contains is List &&
              contains.isNotEmpty;
        }).toList()..sort(
          (a, b) => ((a['name'] ?? '').toString()).compareTo(
            (b['name'] ?? '').toString(),
          ),
        );

    for (final collection in charmCollections) {
      final collectionName = (collection['name'] ?? '').toString().trim();
      if (collectionName.isEmpty) {
        continue;
      }

      final existingCase = existingCaseByName[collectionName];
      final containerId = existingCase != null
          ? existingCase['id'].toString()
          : (nextCaseId++).toString();
      final sourceMeta = resolveCharmCollectionSource(collectionName);
      final releaseDate = sourceMeta['releaseDate'];
      if (releaseDate == null) {
        throw StateError(
          'Missing hardcoded release date for charm collection: $collectionName',
        );
      }

      final containerImagePath = await _syncAsset(
        imageUrl: collection['image']?.toString(),
        dirPath: containersDir.path,
        relativeDir: 'assets/containers',
        id: containerId,
        existingRelativePath: existingCase?['containerImage']?.toString(),
        compressionModeOverride: CompressionMode.maxCompress,
      );

      newCases[containerId] = {
        'id': containerId,
        'name': collectionName,
        'containerImage': containerImagePath,
        'releaseDate': releaseDate,
        'type': 'CHARM_COLLECTION',
        'tournamentName': null,
        'tournamentLogo': null,
        'sourceType': sourceMeta['sourceType'],
        'sourceId': sourceMeta['sourceId'],
        'sourceName': sourceMeta['sourceName'],
      };
      caseNameToId[collectionName] = containerId;
    }

    final newSkins = <String, Map<String, dynamic>>{};
    final newStickers = <String, Map<String, dynamic>>{};
    final newPins = <String, Map<String, dynamic>>{};
    final newMusicKits = <String, Map<String, dynamic>>{};
    final newAgents = <String, Map<String, dynamic>>{};
    final newGraffiti = <String, Map<String, dynamic>>{};
    final newPatches = <String, Map<String, dynamic>>{};
    final newCharms = <String, Map<String, dynamic>>{};
    final skinIdByFullName = <String, String>{};

    final containerContentsMap = <String, Set<String>>{
      for (final containerId in newCases.keys) containerId: <String>{},
    };
    final stickerContentsMap = <String, Set<String>>{};
    final pinContentsMap = <String, Set<String>>{};
    final musicKitContentsMap = <String, Map<String, Map<String, bool>>>{};
    final musicKitVariantPresence = <(String, String), Map<String, bool>>{};
    final musicKitCollectionBySourceId = <String, String?>{};
    final agentCollectionContentsMap = <String, Set<String>>{
      for (final collectionId in newAgentCollections.keys)
        collectionId: <String>{},
    };
    final graffitiContentsMap = <String, Set<String>>{};
    final patchContentsMap = <String, Set<String>>{};
    final charmContentsMap = <String, Set<String>>{};
    final rewardContentsMap = <String, Set<String>>{
      for (final collectionId in newRewardCollections.keys)
        collectionId: <String>{},
    };
    final operationContentsMap = <String, Set<String>>{
      for (final collectionId in newOperationCollections.keys)
        collectionId: <String>{},
    };

    var createdSkinCount = 0;
    var createdStickerCount = 0;
    var createdPinCount = 0;
    var createdMusicKitCount = 0;
    var createdAgentCount = 0;
    var createdGraffitiCount = 0;
    var createdPatchCount = 0;
    var createdCharmCount = 0;
    var reusedSkinCount = 0;
    var reusedStickerCount = 0;
    var reusedPinCount = 0;
    var reusedMusicKitCount = 0;
    var reusedAgentCount = 0;
    var reusedGraffitiCount = 0;
    var reusedPatchCount = 0;
    var reusedCharmCount = 0;
    var skippedUnknownItems = 0;
    var containerRefsCreatedFromSkinMeta = 0;
    var rewardCollectionsCreated = 0;
    var operationCollectionsCreated = 0;

    for (final meta in skinsData) {
      final fullName = (meta['name'] ?? '').toString().trim();
      if (fullName.isEmpty || !fullName.contains(' | ')) {
        continue;
      }

      final itemAndSkin = splitItemAndSkin(fullName);
      final baseItemName = itemAndSkin.$1;
      final fullSkinName = itemAndSkin.$2;

      String itemKind;
      String itemId;
      String fallbackWeaponType;
      try {
        final result = inferItemKindAndId(baseItemName);
        itemKind = result.$1;
        itemId = result.$2;
        fallbackWeaponType = result.$3;
      } catch (_) {
        skippedUnknownItems += 1;
        continue;
      }

      final patternObj = meta['pattern'] is Map
          ? Map<String, dynamic>.from(meta['pattern'] as Map)
          : const <String, dynamic>{};
      final patternName = (patternObj['name'] ?? '').toString().trim();
      final explicitPhase = getExplicitPhase(meta);
      final phaseAndVariant = extractPhaseAndVariant(
        fullSkinName: fullSkinName,
        patternName: patternName.isEmpty ? null : patternName,
        explicitPhase: explicitPhase,
      );
      final phase = phaseAndVariant.$1;
      final variantName = phaseAndVariant.$2;

      var floatTop = safeFloat(meta['min_float'], 0.0);
      var floatBottom = safeFloat(meta['max_float'], 1.0);
      if (floatBottom < floatTop) {
        floatBottom = 1.0;
      }

      final rarity =
          rarityMap[((meta['rarity'] as Map?)?['name'] ?? '').toString()] ??
          'MIL_SPEC';
      final weaponType =
          weaponTypeMap[((meta['category'] as Map?)?['name'] ?? '')
              .toString()] ??
          fallbackWeaponType;
      final collectionPair = chooseCollectionNameAndImage(meta);
      final collectionName = collectionPair.$1;
      final imageUrl = chooseImageUrl(meta);

      final key = (
        itemKind,
        itemId,
        canonicalName(fullSkinName),
        canonicalName(phase ?? variantName ?? ''),
      );

      final existingSkin = existingSkinByKey[key];
      late String skinId;
      if (existingSkin != null) {
        skinId = existingSkin['id'].toString();
        reusedSkinCount += 1;
      } else {
        final sourceSkinId = (meta['id'] ?? '').toString();
        final candidate = makeStableNumericId(sourceSkinId, 800000000);

        if (RegExp(r'^\d+$').hasMatch(candidate) &&
            !usedSkinIds.contains(int.parse(candidate)) &&
            !newSkins.containsKey(candidate)) {
          skinId = candidate;
          usedSkinIds.add(int.parse(candidate));
        } else {
          while (usedSkinIds.contains(nextSkinId)) {
            nextSkinId += 1;
          }
          skinId = nextSkinId.toString();
          usedSkinIds.add(nextSkinId);
          nextSkinId += 1;
        }
        createdSkinCount += 1;
      }

      final rewardMeta = collectionName == null
          ? null
          : rewardSourceOverrides[collectionName];
      final operationMetas = operationCollectionOverrides
          .where((item) => item['name'] == collectionName)
          .toList();
      final oldSkin =
          newSkins[skinId] ?? existingSkin ?? const <String, dynamic>{};

      final skinImagePath = await _syncAsset(
        imageUrl: imageUrl,
        dirPath: skinsDir.path,
        relativeDir: 'assets/skins',
        id: skinId,
        existingRelativePath: existingSkin?['skinImage']?.toString(),
      );

      final skinRecord = <String, dynamic>{
        'id': skinId,
        'name': fullSkinName,
        'skinImage': skinImagePath,
        'floatTop': double.parse(floatTop.toStringAsFixed(6)),
        'floatBottom': double.parse(floatBottom.toStringAsFixed(6)),
        'rarity': rarity,
        'weaponType': weaponType,
        'itemKind': itemKind,
        'itemId': itemId,
        'collection': collectionName ?? oldSkin['collection'],
        'finishCatalogName': patternName.isNotEmpty
            ? patternName
            : oldSkin['finishCatalogName'],
        'variantName': variantName ?? oldSkin['variantName'],
        'phase': phase ?? oldSkin['phase'],
        'apiPaintIndex': meta['paint_index'] != null
            ? meta['paint_index'].toString()
            : oldSkin['apiPaintIndex'],
        'collectionSourceType':
            rewardMeta?['sourceType'] ?? oldSkin['collectionSourceType'],
        'collectionSourceId':
            rewardMeta?['sourceId'] ?? oldSkin['collectionSourceId'],
        'isRewardCollection': rewardMeta != null
            ? true
            : (oldSkin['isRewardCollection'] ?? false),
        'operationCollectionIds': operationMetas.isNotEmpty
            ? operationMetas
                  .map((item) => item['operationId'])
                  .whereType<String>()
                  .toList()
            : (oldSkin['operationCollectionIds'] ?? <String>[]),
        'isOperationCollection': operationMetas.isNotEmpty
            ? true
            : (oldSkin['isOperationCollection'] ?? false),
      };

      newSkins[skinId] = skinRecord;
      existingSkinByKey[key] = skinRecord;
      skinIdByFullName[fullSkinNameKey('$baseItemName | $fullSkinName')] =
          skinId;

      if (rewardMeta != null && collectionName != null) {
        final rewardKey = collectionName;
        final existingReward = existingRewardByKey[rewardKey];
        late String rewardId;
        if (existingReward != null) {
          rewardId = existingReward['id'].toString();
        } else if (rewardNameToId.containsKey(rewardKey)) {
          rewardId = rewardNameToId[rewardKey]!;
        } else {
          rewardId = (nextRewardId++).toString();
        }
        rewardNameToId[rewardKey] = rewardId;

        final rewardImagePath = await _syncAsset(
          imageUrl: collectionImageByName[collectionName],
          dirPath: containersDir.path,
          relativeDir: 'assets/containers',
          id: rewardId,
          existingRelativePath:
              (newRewardCollections[rewardId] ?? existingReward)?['image']
                  ?.toString(),
        );

        final rewardRecord = <String, dynamic>{
          'id': rewardId,
          'name': collectionName,
          'image': rewardImagePath,
          'sourceType': rewardMeta['sourceType'],
          'sourceId': rewardMeta['sourceId'],
          'currency': rewardMeta['currency'] ?? 'STARS',
          'cost': rewardMeta['cost'] ?? 4,
          'releaseDate': rewardMeta['releaseDate'],
        };

        if (!newRewardCollections.containsKey(rewardId)) {
          rewardCollectionsCreated += 1;
        }
        newRewardCollections[rewardId] = rewardRecord;
        newCases[rewardId] = {
          'id': rewardId,
          'name': collectionName,
          'containerImage': rewardImagePath,
          'releaseDate': rewardMeta['releaseDate'],
          'type': 'REWARD_COLLECTION',
          'tournamentName': null,
          'tournamentLogo': null,
          'sourceType': rewardMeta['sourceType'] == 'ARMORY'
              ? 'ARMORY_REWARD'
              : 'OPERATION_REWARD',
          'sourceId': rewardMeta['sourceId'],
          'sourceName': rewardRecord['sourceType'] == 'ARMORY'
              ? 'The Armory'
              : resolveOperationNameFromId(rewardMeta['sourceId']?.toString()),
          'currency': rewardMeta['currency'] ?? 'STARS',
          'cost': rewardMeta['cost'] ?? 4,
        };
        caseNameToId[collectionName] = rewardId;
        rewardContentsMap.putIfAbsent(rewardId, () => <String>{}).add(skinId);
      }

      for (final operationMeta in operationMetas) {
        final opKey = operationKey(
          collectionName ?? '',
          operationMeta['operationId'] ?? '',
        );
        final existingOperation = existingOperationByKey[opKey];
        late String opId;
        if (existingOperation != null) {
          opId = existingOperation['id'].toString();
        } else if (operationKeyToId.containsKey(opKey)) {
          opId = operationKeyToId[opKey]!;
        } else {
          opId = (nextOperationId++).toString();
        }
        operationKeyToId[opKey] = opId;

        final operationImagePath = await _syncAsset(
          imageUrl: collectionImageByName[collectionName ?? ''],
          dirPath: containersDir.path,
          relativeDir: 'assets/containers',
          id: opId,
          existingRelativePath:
              (newOperationCollections[opId] ?? existingOperation)?['image']
                  ?.toString(),
        );

        final operationRecord = <String, dynamic>{
          'id': opId,
          'name': collectionName,
          'image': operationImagePath,
          'operationId': operationMeta['operationId'],
          'operationName': operationMeta['operationName'],
          'releaseDate': operationMeta['releaseDate'],
        };

        if (!newOperationCollections.containsKey(opId)) {
          operationCollectionsCreated += 1;
        }
        newOperationCollections[opId] = operationRecord;
        newCases[opId] = {
          'id': opId,
          'name': collectionName,
          'containerImage': operationImagePath,
          'releaseDate': operationMeta['releaseDate'],
          'type': 'OPERATION_COLLECTION',
          'tournamentName': null,
          'tournamentLogo': null,
          'sourceType': 'LEGACY_OPERATION',
          'sourceId': operationMeta['operationId'],
          'sourceName': operationMeta['operationName'],
          'currency': null,
          'cost': null,
        };
        caseNameToId[collectionName ?? ''] = opId;
        operationContentsMap.putIfAbsent(opId, () => <String>{}).add(skinId);
      }

      final cratesRefs = meta['crates'];
      if (cratesRefs is List) {
        for (final crateRefRaw in cratesRefs) {
          if (crateRefRaw is! Map) {
            continue;
          }
          final crateRef = crateRefRaw.map((k, v) => MapEntry(k.toString(), v));
          final crateName = (crateRef['name'] ?? '').toString().trim();
          if (crateName.isEmpty) {
            continue;
          }

          var containerId = caseNameToId[crateName];
          if (containerId == null) {
            final existingCaseMeta = existingCaseByName[crateName];
            final releaseDate = resolveContainerReleaseDate(
              crateName: crateName,
              containerType: 'STICKER_CAPSULE',
              crateMeta: Map<String, dynamic>.from(crateRef),
              existingReleaseDate: existingCaseMeta?['releaseDate'],
            );
            containerId = existingCaseMeta != null
                ? existingCaseMeta['id'].toString()
                : (nextCaseId++).toString();
            final containerImagePath = await _syncAsset(
              imageUrl: crateRef['image']?.toString(),
              dirPath: containersDir.path,
              relativeDir: 'assets/containers',
              id: containerId,
              existingRelativePath: existingCaseMeta?['containerImage']
                  ?.toString(),
            );
            newCases[containerId] = {
              'id': containerId,
              'name': crateName,
              'containerImage': containerImagePath,
              'releaseDate': releaseDate,
              'type': 'STICKER_CAPSULE',
              'tournamentName': null,
              'tournamentLogo': null,
              'sourceType': null,
              'sourceId': null,
              'sourceName': null,
            };
            caseNameToId[crateName] = containerId;
            containerContentsMap.putIfAbsent(containerId, () => <String>{});
            containerRefsCreatedFromSkinMeta += 1;
          }

          containerContentsMap
              .putIfAbsent(containerId, () => <String>{})
              .add(skinId);
        }
      }
    }

    final stickerCollectionNameToId = <String, String>{};
    for (final meta in stickersData) {
      final rawName = (meta['name'] ?? '').toString().trim();
      final stickerName = normalizeStickerName(rawName);
      if (stickerName.isEmpty) {
        continue;
      }

      final stickerType = inferStickerType(meta);
      final effect = (meta['effect'] ?? 'Other')
          .toString()
          .trim()
          .toUpperCase();
      final rarity =
          stickerRarityMap[((meta['rarity'] as Map?)?['name'] ?? '')
              .toString()] ??
          'HIGH_GRADE';
      final collectionPair = chooseCollectionNameAndImage(meta);
      final collectionName = collectionPair.$1;
      final tournament = meta['tournament'] is Map
          ? Map<String, dynamic>.from(meta['tournament'] as Map)
          : const <String, dynamic>{};
      final tournamentNameRaw = (tournament['name'] ?? '').toString().trim();
      final tournamentName = tournamentNameRaw.isEmpty
          ? null
          : tournamentNameRaw;
      final imageUrl = chooseImageUrl(meta);

      final key = (
        canonicalName(stickerName),
        stickerType,
        effect.isEmpty ? 'OTHER' : effect,
        canonicalName(collectionName ?? tournamentName ?? ''),
      );
      final existingSticker = existingStickerByKey[key];
      late String stickerId;
      if (existingSticker != null) {
        stickerId = existingSticker['id'].toString();
        reusedStickerCount += 1;
      } else {
        final sourceStickerId = (meta['id'] ?? '').toString();
        final candidate = makeStableNumericId(sourceStickerId, 900000000);

        if (RegExp(r'^\d+$').hasMatch(candidate) &&
            !usedStickerIds.contains(int.parse(candidate)) &&
            !newStickers.containsKey(candidate)) {
          stickerId = candidate;
          usedStickerIds.add(int.parse(candidate));
        } else {
          while (usedStickerIds.contains(nextStickerId)) {
            nextStickerId += 1;
          }
          stickerId = nextStickerId.toString();
          usedStickerIds.add(nextStickerId);
          nextStickerId += 1;
        }
        createdStickerCount += 1;
      }

      final stickerImagePath = await _syncAsset(
        imageUrl: imageUrl,
        dirPath: stickersDir.path,
        relativeDir: 'assets/stickers',
        id: stickerId,
        existingRelativePath: existingSticker?['stickerImage']?.toString(),
      );

      final stickerRecord = <String, dynamic>{
        'id': stickerId,
        'name': stickerName,
        'stickerImage': stickerImagePath,
        'rarity': rarity,
        'stickerType': stickerType,
        'effect': effect.isEmpty ? 'OTHER' : effect,
        'collection': collectionName,
        'tournament': tournamentName,
      };

      newStickers[stickerId] = stickerRecord;
      existingStickerByKey[key] = stickerRecord;

      final cratesRefs = meta['crates'];
      if (cratesRefs is List) {
        for (final crateRefRaw in cratesRefs) {
          if (crateRefRaw is! Map) {
            continue;
          }
          final crateRef = crateRefRaw.map((k, v) => MapEntry(k.toString(), v));
          final crateName = (crateRef['name'] ?? '').toString().trim();
          if (crateName.isEmpty) {
            continue;
          }

          var containerId = caseNameToId[crateName];
          final containerType = inferStickerContainerType(crateName);

          if (containerId == null) {
            final existingCaseMeta = existingCaseByName[crateName];
            var releaseDate = resolveContainerReleaseDate(
              crateName: crateName,
              containerType: containerType,
              crateMeta: Map<String, dynamic>.from(crateRef),
              existingReleaseDate: existingCaseMeta?['releaseDate'],
            );
            final sourceMeta = containerType == 'STICKER_COLLECTION'
                ? resolveStickerCollectionSource(crateName)
                : const {
                    'sourceType': null,
                    'sourceId': null,
                    'sourceName': null,
                    'releaseDate': null,
                  };
            if (sourceMeta['releaseDate'] != null) {
              releaseDate = sourceMeta['releaseDate']!;
            }

            containerId = existingCaseMeta != null
                ? existingCaseMeta['id'].toString()
                : (nextCaseId++).toString();
            final containerImagePath = await _syncAsset(
              imageUrl: crateRef['image']?.toString(),
              dirPath: containersDir.path,
              relativeDir: 'assets/containers',
              id: containerId,
              existingRelativePath: existingCaseMeta?['containerImage']
                  ?.toString(),
            );
            newCases[containerId] = {
              'id': containerId,
              'name': crateName,
              'containerImage': containerImagePath,
              'releaseDate': releaseDate,
              'type': containerType,
              'tournamentName': null,
              'tournamentLogo': null,
              'sourceType': sourceMeta['sourceType'],
              'sourceId': sourceMeta['sourceId'],
              'sourceName': sourceMeta['sourceName'],
            };
            caseNameToId[crateName] = containerId;
            containerRefsCreatedFromSkinMeta += 1;
          } else {
            final existingCaseRecord = newCases[containerId];
            if (existingCaseRecord != null) {
              var releaseDate = resolveContainerReleaseDate(
                crateName: crateName,
                containerType: containerType,
                crateMeta: Map<String, dynamic>.from(crateRef),
                existingReleaseDate: existingCaseRecord['releaseDate'],
              );
              final sourceMeta = containerType == 'STICKER_COLLECTION'
                  ? resolveStickerCollectionSource(crateName)
                  : const {
                      'sourceType': null,
                      'sourceId': null,
                      'sourceName': null,
                      'releaseDate': null,
                    };
              if (sourceMeta['releaseDate'] != null) {
                releaseDate = sourceMeta['releaseDate']!;
              }

              existingCaseRecord['releaseDate'] = releaseDate;
              existingCaseRecord['type'] = containerType;
              existingCaseRecord['sourceType'] = sourceMeta['sourceType'];
              existingCaseRecord['sourceId'] = sourceMeta['sourceId'];
              existingCaseRecord['sourceName'] = sourceMeta['sourceName'];
            }
          }

          stickerContentsMap
              .putIfAbsent(containerId, () => <String>{})
              .add(stickerId);
        }
      }

      final collectionsRefs = meta['collections'];
      if (collectionsRefs is List) {
        for (final collectionRefRaw in collectionsRefs) {
          if (collectionRefRaw is! Map) {
            continue;
          }
          final collectionRef = collectionRefRaw.map(
            (k, v) => MapEntry(k.toString(), v),
          );
          final stickerCollectionName = normalizeCollectionName(
            (collectionRef['name'] ?? '').toString().trim(),
          );
          if (stickerCollectionName == null || stickerCollectionName.isEmpty) {
            continue;
          }

          var containerId = stickerCollectionNameToId[stickerCollectionName];
          if (containerId == null) {
            final existingCaseMeta = existingCaseByName[stickerCollectionName];
            String releaseDate;
            if (existingCaseMeta != null) {
              containerId = existingCaseMeta['id'].toString();
              releaseDate = (existingCaseMeta['releaseDate'] ?? '').toString();
            } else if (caseNameToId.containsKey(stickerCollectionName)) {
              containerId = caseNameToId[stickerCollectionName]!;
              releaseDate = (newCases[containerId]?['releaseDate'] ?? '')
                  .toString();
            } else {
              containerId = (nextCaseId++).toString();
              releaseDate = '2000-01-01';
            }

            final sourceMeta = resolveStickerCollectionSource(
              stickerCollectionName,
            );
            if (sourceMeta['releaseDate'] != null) {
              releaseDate = sourceMeta['releaseDate']!;
            }

            newCases[containerId] = {
              'id': containerId,
              'name': stickerCollectionName,
              'containerImage': await _syncAsset(
                imageUrl: collectionRef['image']?.toString(),
                dirPath: containersDir.path,
                relativeDir: 'assets/containers',
                id: containerId,
                existingRelativePath:
                    existingCaseMeta?['containerImage']?.toString() ??
                    newCases[containerId]?['containerImage']?.toString(),
              ),
              'releaseDate': releaseDate,
              'type': 'STICKER_COLLECTION',
              'tournamentName': null,
              'tournamentLogo': null,
              'sourceType': sourceMeta['sourceType'],
              'sourceId': sourceMeta['sourceId'],
              'sourceName': sourceMeta['sourceName'],
            };
            caseNameToId[stickerCollectionName] = containerId;
            stickerCollectionNameToId[stickerCollectionName] = containerId;
          }

          stickerContentsMap
              .putIfAbsent(containerId, () => <String>{})
              .add(stickerId);
          final existingCaseRecord = newCases[containerId];
          if (existingCaseRecord != null) {
            final sourceMeta = resolveStickerCollectionSource(
              stickerCollectionName,
            );
            existingCaseRecord['type'] = 'STICKER_COLLECTION';
            existingCaseRecord['sourceType'] = sourceMeta['sourceType'];
            existingCaseRecord['sourceId'] = sourceMeta['sourceId'];
            existingCaseRecord['sourceName'] = sourceMeta['sourceName'];
            if (sourceMeta['releaseDate'] != null) {
              existingCaseRecord['releaseDate'] = sourceMeta['releaseDate'];
            }
          }
        }
      }
    }

    for (final crate in supportedCrates) {
      final crateName = (crate['name'] ?? '').toString().trim();
      if (crateName.isEmpty) {
        continue;
      }
      if (inferContainerType(crateName, crate['type']?.toString()) !=
          'PIN_CAPSULE') {
        continue;
      }

      final containerId = caseNameToId[crateName];
      if (containerId == null) {
        continue;
      }

      final pinCollection = inferPinCollection(crateName);
      final contains = crate['contains'];
      if (contains is! List) {
        continue;
      }

      for (final collectibleRaw in contains) {
        if (collectibleRaw is! Map) {
          continue;
        }
        final collectible = collectibleRaw.map(
          (k, v) => MapEntry(k.toString(), v),
        );
        final pinName = (collectible['name'] ?? '').toString().trim();
        if (pinName.isEmpty) {
          continue;
        }

        final rarity =
            pinRarityMap[((collectible['rarity'] as Map?)?['name'] ?? '')
                .toString()] ??
            'HIGH_GRADE';
        final imageUrl = (collectible['image'] ?? '').toString().trim();

        final key = (
          canonicalName(pinName),
          canonicalName(pinCollection ?? ''),
        );
        final existingPin = existingPinByKey[key];
        late String pinId;
        if (existingPin != null) {
          pinId = existingPin['id'].toString();
          reusedPinCount += 1;
        } else {
          final sourcePinId = (collectible['id'] ?? '').toString();
          final candidate = makeStableNumericId(sourcePinId, 950000000);

          if (RegExp(r'^\d+$').hasMatch(candidate) &&
              !usedPinIds.contains(int.parse(candidate)) &&
              !newPins.containsKey(candidate)) {
            pinId = candidate;
            usedPinIds.add(int.parse(candidate));
          } else {
            while (usedPinIds.contains(nextPinId)) {
              nextPinId += 1;
            }
            pinId = nextPinId.toString();
            usedPinIds.add(nextPinId);
            nextPinId += 1;
          }
          createdPinCount += 1;
        }

        final pinImagePath = await _syncAsset(
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          dirPath: pinsDir.path,
          relativeDir: 'assets/pins',
          id: pinId,
          existingRelativePath: existingPin?['pinImage']?.toString(),
        );

        final pinRecord = <String, dynamic>{
          'id': pinId,
          'name': pinName,
          'pinImage': pinImagePath,
          'rarity': rarity,
          'collection': pinCollection,
        };
        newPins[pinId] = pinRecord;
        existingPinByKey[key] = pinRecord;
        pinContentsMap.putIfAbsent(containerId, () => <String>{}).add(pinId);

        if (!shouldCreateGenuinePin(
          pinName: pinName,
          pinCollection: pinCollection,
        )) {
          continue;
        }

        final genuineKey = (
          canonicalName('Genuine $pinName'),
          canonicalName(pinCollection ?? ''),
        );
        final existingGenuinePin = existingPinByKey[genuineKey];
        late String genuinePinId;
        if (existingGenuinePin != null) {
          genuinePinId = existingGenuinePin['id'].toString();
          reusedPinCount += 1;
        } else {
          while (usedPinIds.contains(nextPinId)) {
            nextPinId += 1;
          }
          genuinePinId = nextPinId.toString();
          usedPinIds.add(nextPinId);
          nextPinId += 1;
          createdPinCount += 1;
        }

        final genuinePinRecord = <String, dynamic>{
          'id': genuinePinId,
          'name': 'Genuine $pinName',
          'pinImage': pinImagePath,
          'rarity': 'GENUINE',
          'collection': pinCollection,
        };
        newPins[genuinePinId] = genuinePinRecord;
        existingPinByKey[genuineKey] = genuinePinRecord;
      }
    }

    final musicKitMetaById = <String, Map<String, dynamic>>{
      for (final item in musicKitsData)
        if ((item['id'] ?? '').toString().trim().isNotEmpty)
          (item['id'] ?? '').toString().trim(): item,
    };
    final patchMetaById = <String, Map<String, dynamic>>{
      for (final item in patchesData)
        if ((item['id'] ?? '').toString().trim().isNotEmpty)
          (item['id'] ?? '').toString().trim(): item,
    };

    for (final crate in supportedCrates) {
      final crateName = (crate['name'] ?? '').toString().trim();
      if (crateName.isEmpty) {
        continue;
      }
      if (inferContainerType(crateName, crate['type']?.toString()) !=
          'MUSIC_KIT_BOX') {
        continue;
      }

      final containerId = caseNameToId[crateName];
      if (containerId == null) {
        continue;
      }

      final musicKitCollection = inferMusicKitCollection(crateName);
      final contains = crate['contains'];
      if (contains is! List) {
        continue;
      }

      for (final collectibleRaw in contains) {
        if (collectibleRaw is! Map) {
          continue;
        }
        final collectible = collectibleRaw.map(
          (k, v) => MapEntry(k.toString(), v),
        );
        final normalizedMusicKitName = normalizeMusicKitName(
          (collectible['name'] ?? '').toString().trim(),
        );
        final musicKitName = normalizedMusicKitName.$1;
        final isStatTrak = normalizedMusicKitName.$2;
        if (musicKitName.isEmpty) {
          continue;
        }

        final sourceMusicKitId = (collectible['id'] ?? '').toString().trim();
        if (sourceMusicKitId.isEmpty) {
          continue;
        }

        final musicKitMeta =
            musicKitMetaById[sourceMusicKitId] ?? const <String, dynamic>{};
        final rarity =
            musicKitRarityMap[((collectible['rarity'] as Map?)?['name'] ??
                    (musicKitMeta['rarity'] as Map?)?['name'] ??
                    '')
                .toString()] ??
            'HIGH_GRADE';
        final collectibleImage = (collectible['image'] ?? '').toString().trim();
        final metaImage = (musicKitMeta['image'] ?? '').toString().trim();
        final imageUrl = collectibleImage.isNotEmpty
            ? collectibleImage
            : (metaImage.isNotEmpty ? metaImage : null);

        final key = (
          canonicalName(musicKitName),
          canonicalName(musicKitCollection ?? ''),
        );
        final variantPresence = musicKitVariantPresence.putIfAbsent(
          key,
          () => <String, bool>{'hasRegular': false, 'hasStatTrak': false},
        );
        variantPresence['hasRegular'] =
            (variantPresence['hasRegular'] ?? false) || !isStatTrak;
        variantPresence['hasStatTrak'] =
            (variantPresence['hasStatTrak'] ?? false) || isStatTrak;
        final existingMusicKit = existingMusicKitByKey[key];
        late String musicKitId;
        if (existingMusicKit != null) {
          musicKitId = existingMusicKit['id'].toString();
          reusedMusicKitCount += 1;
        } else {
          final candidate = makeHashedNumericId(sourceMusicKitId, 970000000);

          if (RegExp(r'^\d+$').hasMatch(candidate) &&
              !usedMusicKitIds.contains(int.parse(candidate)) &&
              !newMusicKits.containsKey(candidate)) {
            musicKitId = candidate;
            usedMusicKitIds.add(int.parse(candidate));
          } else {
            while (usedMusicKitIds.contains(nextMusicKitId)) {
              nextMusicKitId += 1;
            }
            musicKitId = nextMusicKitId.toString();
            usedMusicKitIds.add(nextMusicKitId);
            nextMusicKitId += 1;
          }
          createdMusicKitCount += 1;
        }

        final musicKitImagePath = await _syncAsset(
          imageUrl: imageUrl,
          dirPath: musicKitsDir.path,
          relativeDir: 'assets/music_kits',
          id: musicKitId,
          existingRelativePath: existingMusicKit?['musicKitImage']?.toString(),
          compressionModeOverride: CompressionMode.maxCompress,
        );

        final musicKitRecord = <String, dynamic>{
          'id': musicKitId,
          'name': musicKitName,
          'musicKitImage': musicKitImagePath,
          'rarity': rarity,
          'collection': musicKitCollection,
          'hasRegular': variantPresence['hasRegular'] ?? false,
          'hasStatTrak': variantPresence['hasStatTrak'] ?? false,
        };
        newMusicKits[musicKitId] = musicKitRecord;
        existingMusicKitByKey[key] = musicKitRecord;
        musicKitCollectionBySourceId[sourceMusicKitId] = musicKitCollection;
        final containerMusicKits = musicKitContentsMap.putIfAbsent(
          containerId,
          () => <String, Map<String, bool>>{},
        );
        final existingEntry =
            containerMusicKits[musicKitId] ??
            <String, bool>{'hasRegular': false, 'hasStatTrak': false};
        existingEntry['hasRegular'] =
            (existingEntry['hasRegular'] ?? false) || !isStatTrak;
        existingEntry['hasStatTrak'] =
            (existingEntry['hasStatTrak'] ?? false) || isStatTrak;
        containerMusicKits[musicKitId] = existingEntry;
      }
    }

    for (final meta in musicKitsData) {
      final sourceMusicKitId = (meta['id'] ?? '').toString().trim();
      if (sourceMusicKitId.isEmpty) {
        continue;
      }

      final normalizedMusicKitName = normalizeMusicKitName(
        (meta['name'] ?? '').toString().trim(),
      );
      final musicKitName = normalizedMusicKitName.$1;
      final isStatTrak = normalizedMusicKitName.$2;
      if (musicKitName.isEmpty) {
        continue;
      }

      final rawCollection = meta['collection'];
      final explicitCollection = rawCollection is String
          ? rawCollection.trim()
          : '';
      final musicKitCollection =
          musicKitCollectionBySourceId[sourceMusicKitId] ??
          (explicitCollection.isEmpty ? null : explicitCollection);
      final key = (
        canonicalName(musicKitName),
        canonicalName(musicKitCollection ?? ''),
      );
      final variantPresence = musicKitVariantPresence.putIfAbsent(
        key,
        () => <String, bool>{'hasRegular': false, 'hasStatTrak': false},
      );
      variantPresence['hasRegular'] =
          (variantPresence['hasRegular'] ?? false) || !isStatTrak;
      variantPresence['hasStatTrak'] =
          (variantPresence['hasStatTrak'] ?? false) || isStatTrak;

      if (existingMusicKitByKey.containsKey(key)) {
        final existingRecord = existingMusicKitByKey[key];
        if (existingRecord != null) {
          final existingId = existingRecord['id']?.toString();
          if (existingId != null && newMusicKits.containsKey(existingId)) {
            newMusicKits[existingId]!['hasRegular'] =
                variantPresence['hasRegular'] ?? false;
            newMusicKits[existingId]!['hasStatTrak'] =
                variantPresence['hasStatTrak'] ?? false;
          }
        }
        continue;
      }

      final rarity =
          musicKitRarityMap[((meta['rarity'] as Map?)?['name'] ?? '')
              .toString()] ??
          'HIGH_GRADE';
      final imageUrl = chooseImageUrl(meta);

      late String musicKitId;
      final candidate = makeHashedNumericId(sourceMusicKitId, 970000000);
      if (RegExp(r'^\d+$').hasMatch(candidate) &&
          !usedMusicKitIds.contains(int.parse(candidate)) &&
          !newMusicKits.containsKey(candidate)) {
        musicKitId = candidate;
        usedMusicKitIds.add(int.parse(candidate));
      } else {
        while (usedMusicKitIds.contains(nextMusicKitId)) {
          nextMusicKitId += 1;
        }
        musicKitId = nextMusicKitId.toString();
        usedMusicKitIds.add(nextMusicKitId);
        nextMusicKitId += 1;
      }
      createdMusicKitCount += 1;

      final musicKitImagePath = await _syncAsset(
        imageUrl: imageUrl,
        dirPath: musicKitsDir.path,
        relativeDir: 'assets/music_kits',
        id: musicKitId,
        compressionModeOverride: CompressionMode.maxCompress,
      );

      final musicKitRecord = <String, dynamic>{
        'id': musicKitId,
        'name': musicKitName,
        'musicKitImage': musicKitImagePath,
        'rarity': rarity,
        'collection': musicKitCollection,
        'hasRegular': variantPresence['hasRegular'] ?? false,
        'hasStatTrak': variantPresence['hasStatTrak'] ?? false,
      };
      newMusicKits[musicKitId] = musicKitRecord;
      existingMusicKitByKey[key] = musicKitRecord;
      musicKitCollectionBySourceId[sourceMusicKitId] = musicKitCollection;
    }

    for (final meta in agentsData) {
      final agentName = (meta['name'] ?? '').toString().trim();
      if (agentName.isEmpty) {
        continue;
      }

      final collectionsRefs = meta['collections'];
      if (collectionsRefs is! List || collectionsRefs.isEmpty) {
        continue;
      }

      final collectionRefRaw = collectionsRefs.first;
      if (collectionRefRaw is! Map) {
        continue;
      }
      final collectionRef = collectionRefRaw.map(
        (k, v) => MapEntry(k.toString(), v),
      );
      final collectionName = (collectionRef['name'] ?? '').toString().trim();
      if (collectionName.isEmpty) {
        continue;
      }

      final rarity =
          agentRarityMap[((meta['rarity'] as Map?)?['name'] ?? '')
              .toString()] ??
          'DISTINGUISHED';
      final team = ((meta['team'] as Map?)?['name'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final imageUrl = chooseImageUrl(meta);

      final key = (
        canonicalName(agentName),
        canonicalName(collectionName),
        team,
      );
      final existingAgent = existingAgentByKey[key];
      late String agentId;
      if (existingAgent != null) {
        agentId = existingAgent['id'].toString();
        reusedAgentCount += 1;
      } else {
        final sourceAgentId = (meta['id'] ?? '').toString();
        final candidate = makeStableNumericId(sourceAgentId, 980000000);
        if (RegExp(r'^\d+$').hasMatch(candidate) &&
            !usedAgentIds.contains(int.parse(candidate)) &&
            !newAgents.containsKey(candidate)) {
          agentId = candidate;
          usedAgentIds.add(int.parse(candidate));
        } else {
          while (usedAgentIds.contains(nextAgentId)) {
            nextAgentId += 1;
          }
          agentId = nextAgentId.toString();
          usedAgentIds.add(nextAgentId);
          nextAgentId += 1;
        }
        createdAgentCount += 1;
      }

      final agentImagePath = await _syncAsset(
        imageUrl: imageUrl,
        dirPath: agentsDir.path,
        relativeDir: 'assets/agents',
        id: agentId,
        existingRelativePath: existingAgent?['agentImage']?.toString(),
      );

      final agentRecord = <String, dynamic>{
        'id': agentId,
        'name': agentName,
        'agentImage': agentImagePath,
        'rarity': rarity,
        'collection': collectionName,
        'team': team,
      };
      newAgents[agentId] = agentRecord;
      existingAgentByKey[key] = agentRecord;

      final sourceMeta = resolveAgentCollectionSource(collectionName);
      final opId = sourceMeta['operationId'];
      final opName = sourceMeta['operationName'];
      final releaseDate = sourceMeta['releaseDate'];
      if (opId == null || opName == null || releaseDate == null) {
        continue;
      }

      final collectionKey = operationKey(collectionName, opId);
      var agentCollectionId = agentCollectionKeyToId[collectionKey];
      final existingAgentCollection =
          existingAgentCollectionByKey[collectionKey];
      if (agentCollectionId == null) {
        if (existingAgentCollection != null) {
          agentCollectionId = existingAgentCollection['id'].toString();
        } else {
          agentCollectionId = (nextAgentCollectionId++).toString();
        }
        agentCollectionKeyToId[collectionKey] = agentCollectionId;
      }

      final agentCollectionImagePath = await _syncAsset(
        imageUrl: collectionRef['image']?.toString(),
        dirPath: containersDir.path,
        relativeDir: 'assets/containers',
        id: agentCollectionId,
        existingRelativePath:
            (newAgentCollections[agentCollectionId] ??
                    existingAgentCollection)?['image']
                ?.toString(),
      );

      newAgentCollections[agentCollectionId] = {
        'id': agentCollectionId,
        'name': collectionName,
        'image': agentCollectionImagePath,
        'operationId': opId,
        'operationName': opName,
        'releaseDate': releaseDate,
      };
      newCases[agentCollectionId] = {
        'id': agentCollectionId,
        'name': collectionName,
        'containerImage': agentCollectionImagePath,
        'releaseDate': releaseDate,
        'type': 'AGENT_COLLECTION',
        'tournamentName': null,
        'tournamentLogo': null,
        'sourceType': 'LEGACY_OPERATION',
        'sourceId': opId,
        'sourceName': opName,
        'currency': null,
        'cost': null,
      };
      caseNameToId[collectionName] = agentCollectionId;
      agentCollectionContentsMap
          .putIfAbsent(agentCollectionId, () => <String>{})
          .add(agentId);
    }

    for (final meta in keychainsData) {
      final charmName = normalizeCharmName(
        (meta['name'] ?? '').toString().trim(),
      );
      if (charmName.isEmpty) {
        continue;
      }

      final collectionInfo = chooseCollectionNameAndImage(meta);
      final charmCollection = collectionInfo.$1;
      final rarity =
          charmRarityMap[((meta['rarity'] as Map?)?['name'] ?? '')
              .toString()] ??
          'HIGH_GRADE';
      final imageUrl = chooseImageUrl(meta);

      final key = (
        canonicalName(charmName),
        canonicalName(charmCollection ?? ''),
      );
      final existingCharm = existingCharmByKey[key];
      late String charmId;
      if (existingCharm != null) {
        charmId = existingCharm['id'].toString();
        reusedCharmCount += 1;
      } else {
        final sourceCharmId = (meta['id'] ?? '').toString().trim();
        final candidate = makeStableNumericId(sourceCharmId, 996000000);
        if (RegExp(r'^\d+$').hasMatch(candidate) &&
            !usedCharmIds.contains(int.parse(candidate)) &&
            !newCharms.containsKey(candidate)) {
          charmId = candidate;
          usedCharmIds.add(int.parse(candidate));
        } else {
          while (usedCharmIds.contains(nextCharmId)) {
            nextCharmId += 1;
          }
          charmId = nextCharmId.toString();
          usedCharmIds.add(nextCharmId);
          nextCharmId += 1;
        }
        createdCharmCount += 1;
      }

      final charmImagePath = await _syncAsset(
        imageUrl: imageUrl,
        dirPath: charmsDir.path,
        relativeDir: 'assets/charms',
        id: charmId,
        existingRelativePath: existingCharm?['charmImage']?.toString(),
        compressionModeOverride: CompressionMode.maxCompress,
      );

      final charmRecord = <String, dynamic>{
        'id': charmId,
        'name': charmName,
        'charmImage': charmImagePath,
        'rarity': rarity,
        'collection': charmCollection,
      };
      newCharms[charmId] = charmRecord;
      existingCharmByKey[key] = charmRecord;
    }

    for (final meta in graffitiData) {
      final graffitiName = normalizeGraffitiName(
        (meta['name'] ?? '').toString().trim(),
      );
      if (graffitiName.isEmpty) {
        continue;
      }

      final rarity =
          graffitiRarityMap[((meta['rarity'] as Map?)?['name'] ?? '')
              .toString()] ??
          'BASE_GRADE';
      final imageUrl = chooseImageUrl(meta);
      final cratesRefs = meta['crates'];
      final collectionName =
          cratesRefs is List && cratesRefs.isNotEmpty && cratesRefs.first is Map
          ? inferGraffitiCollection(
              ((cratesRefs.first as Map)['name'] ?? '').toString(),
            )
          : null;

      final key = (
        canonicalName(graffitiName),
        canonicalName(collectionName ?? ''),
      );
      final existingGraffiti = existingGraffitiByKey[key];
      late String graffitiId;
      if (existingGraffiti != null) {
        graffitiId = existingGraffiti['id'].toString();
        reusedGraffitiCount += 1;
      } else {
        final sourceGraffitiId = (meta['id'] ?? '').toString();
        final candidate = makeStableNumericId(sourceGraffitiId, 990000000);
        if (RegExp(r'^\d+$').hasMatch(candidate) &&
            !usedGraffitiIds.contains(int.parse(candidate)) &&
            !newGraffiti.containsKey(candidate)) {
          graffitiId = candidate;
          usedGraffitiIds.add(int.parse(candidate));
        } else {
          while (usedGraffitiIds.contains(nextGraffitiId)) {
            nextGraffitiId += 1;
          }
          graffitiId = nextGraffitiId.toString();
          usedGraffitiIds.add(nextGraffitiId);
          nextGraffitiId += 1;
        }
        createdGraffitiCount += 1;
      }

      final graffitiImagePath = await _syncAsset(
        imageUrl: imageUrl,
        dirPath: graffitiDir.path,
        relativeDir: 'assets/graffiti',
        id: graffitiId,
        existingRelativePath: existingGraffiti?['graffitiImage']?.toString(),
      );

      final graffitiRecord = <String, dynamic>{
        'id': graffitiId,
        'name': graffitiName,
        'graffitiImage': graffitiImagePath,
        'rarity': rarity,
        'collection': collectionName,
      };
      newGraffiti[graffitiId] = graffitiRecord;
      existingGraffitiByKey[key] = graffitiRecord;

      if (cratesRefs is List) {
        for (final crateRefRaw in cratesRefs) {
          if (crateRefRaw is! Map) {
            continue;
          }
          final crateRef = crateRefRaw.map((k, v) => MapEntry(k.toString(), v));
          final crateName = (crateRef['name'] ?? '').toString().trim();
          final containerId = caseNameToId[crateName];
          if (containerId == null) {
            continue;
          }
          graffitiContentsMap
              .putIfAbsent(containerId, () => <String>{})
              .add(graffitiId);
        }
      }
    }

    for (final crate in supportedCrates) {
      final crateName = (crate['name'] ?? '').toString().trim();
      if (crateName.isEmpty) {
        continue;
      }
      final patchContainerType = inferContainerType(
        crateName,
        crate['type']?.toString(),
      );
      if (patchContainerType != 'PATCH_PACK' &&
          patchContainerType != 'PATCH_COLLECTION') {
        continue;
      }

      final containerId = caseNameToId[crateName];
      if (containerId == null) {
        continue;
      }

      final patchCollection = inferPatchCollection(crateName);
      final contains = crate['contains'];
      if (contains is! List) {
        continue;
      }

      for (final collectibleRaw in contains) {
        if (collectibleRaw is! Map) {
          continue;
        }
        final collectible = collectibleRaw.map(
          (k, v) => MapEntry(k.toString(), v),
        );
        final patchName = normalizePatchName(
          (collectible['name'] ?? '').toString().trim(),
        );
        if (patchName.isEmpty) {
          continue;
        }

        final rarity =
            patchRarityMap[((collectible['rarity'] as Map?)?['name'] ?? '')
                .toString()] ??
            'HIGH_GRADE';
        final sourcePatchId = (collectible['id'] ?? '').toString();
        final patchMeta =
            patchMetaById[sourcePatchId] ?? const <String, dynamic>{};
        final collectibleImage = (collectible['image'] ?? '').toString().trim();
        final metaImage = (patchMeta['image'] ?? '').toString().trim();
        final imageUrl = collectibleImage.isNotEmpty
            ? collectibleImage
            : metaImage;

        final key = (
          canonicalName(patchName),
          canonicalName(patchCollection ?? ''),
        );
        final existingPatch = existingPatchByKey[key];
        late String patchId;
        if (existingPatch != null) {
          patchId = existingPatch['id'].toString();
          reusedPatchCount += 1;
        } else {
          final candidate = makeStableNumericId(sourcePatchId, 995000000);
          if (RegExp(r'^\d+$').hasMatch(candidate) &&
              !usedPatchIds.contains(int.parse(candidate)) &&
              !newPatches.containsKey(candidate)) {
            patchId = candidate;
            usedPatchIds.add(int.parse(candidate));
          } else {
            while (usedPatchIds.contains(nextPatchId)) {
              nextPatchId += 1;
            }
            patchId = nextPatchId.toString();
            usedPatchIds.add(nextPatchId);
            nextPatchId += 1;
          }
          createdPatchCount += 1;
        }

        final patchImagePath = await _syncAsset(
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          dirPath: patchesDir.path,
          relativeDir: 'assets/patches',
          id: patchId,
          existingRelativePath: existingPatch?['patchImage']?.toString(),
        );

        final patchRecord = <String, dynamic>{
          'id': patchId,
          'name': patchName,
          'patchImage': patchImagePath,
          'rarity': rarity,
          'collection': patchCollection,
        };
        newPatches[patchId] = patchRecord;
        existingPatchByKey[key] = patchRecord;
        patchContentsMap
            .putIfAbsent(containerId, () => <String>{})
            .add(patchId);
      }

      if (patchContainerType == 'PATCH_COLLECTION') {
        final existingCaseRecord = newCases[containerId];
        if (existingCaseRecord != null) {
          final sourceMeta = resolvePatchCollectionSource(crateName);
          existingCaseRecord['sourceType'] = sourceMeta['sourceType'];
          existingCaseRecord['sourceId'] = sourceMeta['sourceId'];
          existingCaseRecord['sourceName'] = sourceMeta['sourceName'];
          if (sourceMeta['releaseDate'] != null) {
            existingCaseRecord['releaseDate'] = sourceMeta['releaseDate'];
          }
        }
      }
    }

    for (final collection in charmCollections) {
      final collectionName = (collection['name'] ?? '').toString().trim();
      final containerId = caseNameToId[collectionName];
      if (containerId == null) {
        continue;
      }

      final contains = collection['contains'];
      if (contains is! List) {
        continue;
      }

      for (final collectibleRaw in contains) {
        if (collectibleRaw is! Map) {
          continue;
        }
        final collectible = collectibleRaw.map(
          (k, v) => MapEntry(k.toString(), v),
        );
        final charmName = normalizeCharmName(
          (collectible['name'] ?? '').toString().trim(),
        );
        if (charmName.isEmpty) {
          continue;
        }

        final key = (canonicalName(charmName), canonicalName(collectionName));

        var charmRecord = existingCharmByKey[key];
        if (charmRecord == null) {
          final rarity =
              charmRarityMap[((collectible['rarity'] as Map?)?['name'] ?? '')
                  .toString()] ??
              'HIGH_GRADE';
          final sourceCharmId = (collectible['id'] ?? '').toString().trim();
          late String charmId;
          final candidate = makeStableNumericId(sourceCharmId, 996000000);
          if (RegExp(r'^\d+$').hasMatch(candidate) &&
              !usedCharmIds.contains(int.parse(candidate)) &&
              !newCharms.containsKey(candidate)) {
            charmId = candidate;
            usedCharmIds.add(int.parse(candidate));
          } else {
            while (usedCharmIds.contains(nextCharmId)) {
              nextCharmId += 1;
            }
            charmId = nextCharmId.toString();
            usedCharmIds.add(nextCharmId);
            nextCharmId += 1;
          }
          createdCharmCount += 1;

          final charmImagePath = await _syncAsset(
            imageUrl: collectible['image']?.toString(),
            dirPath: charmsDir.path,
            relativeDir: 'assets/charms',
            id: charmId,
            compressionModeOverride: CompressionMode.maxCompress,
          );

          charmRecord = <String, dynamic>{
            'id': charmId,
            'name': charmName,
            'charmImage': charmImagePath,
            'rarity': rarity,
            'collection': collectionName,
          };
          newCharms[charmId] = charmRecord;
          existingCharmByKey[key] = charmRecord;
        }

        charmContentsMap
            .putIfAbsent(containerId, () => <String>{})
            .add(charmRecord['id'].toString());
      }
    }

    for (final legacyCase in legacyCaseOverrides) {
      final legacyName = (legacyCase['name'] ?? '').toString().trim();
      if (legacyName.isEmpty) {
        continue;
      }

      final existingCase = existingCaseByName[legacyName];
      final legacyCaseId = existingCase != null
          ? existingCase['id'].toString()
          : (caseNameToId[legacyName] ?? (nextCaseId++).toString());
      final baseCaseName = (legacyCase['baseCaseName'] ?? '').toString().trim();
      final baseCaseId = caseNameToId[baseCaseName];
      final baseCase = baseCaseId == null ? null : newCases[baseCaseId];

      newCases[legacyCaseId] = {
        'id': legacyCaseId,
        'name': legacyName,
        'containerImage':
            existingCase?['containerImage']?.toString() ??
            (baseCase?['containerImage']?.toString()) ??
            'assets/containers/$legacyCaseId.png',
        'releaseDate': (legacyCase['releaseDate'] ?? '2000-01-01').toString(),
        'type': (legacyCase['type'] ?? 'CASE').toString(),
        'tournamentName': null,
        'tournamentLogo': null,
        'sourceType': null,
        'sourceId': null,
        'sourceName': null,
      };
      caseNameToId[legacyName] = legacyCaseId;
      containerContentsMap.putIfAbsent(legacyCaseId, () => <String>{});

      if (legacyCase['copyImageFromBase'] == true && baseCase != null) {
        final baseImageName = basename(
          (baseCase['containerImage'] ?? '').toString(),
        );
        final baseImageFile = File('${containersDir.path}/$baseImageName');
        final baseExt = suffixFromPath(baseImageName);
        final legacyImageFile = File(
          '${containersDir.path}/$legacyCaseId$baseExt',
        );
        if (baseImageFile.existsSync() && !legacyImageFile.existsSync()) {
          await legacyImageFile.writeAsBytes(await baseImageFile.readAsBytes());
          newCases[legacyCaseId]!['containerImage'] =
              'assets/containers/$legacyCaseId$baseExt';
        }
      }

      final contents = legacyCase['contents'];
      if (contents is List) {
        for (final fullSkinName in contents) {
          if (fullSkinName is! String) {
            continue;
          }
          final skinId = skinIdByFullName[fullSkinNameKey(fullSkinName)];
          if (skinId == null) {
            _io.printInfo(
              "[WARN] legacy case '$legacyName' references missing skin: $fullSkinName",
            );
            continue;
          }
          containerContentsMap
              .putIfAbsent(legacyCaseId, () => <String>{})
              .add(skinId);
        }
      }

      if (legacyCase['copySpecialItemsFromBase'] == true &&
          baseCaseId != null) {
        for (final skinId
            in containerContentsMap[baseCaseId] ?? const <String>{}) {
          final skin = newSkins[skinId];
          if (skin == null) {
            continue;
          }
          final weaponType = (skin['weaponType'] ?? '').toString();
          final itemKind = (skin['itemKind'] ?? '').toString();
          if (weaponType == 'KNIFE' ||
              weaponType == 'GLOVES' ||
              itemKind == 'KNIFE' ||
              itemKind == 'GLOVES') {
            containerContentsMap
                .putIfAbsent(legacyCaseId, () => <String>{})
                .add(skinId);
          }
        }
      }
    }

    for (final caseRecord in newCases.values) {
      final caseName = (caseRecord['name'] ?? '').toString().trim();
      final forcedType = containerTypeOverrides[caseName];
      if (forcedType != null) {
        caseRecord['type'] = forcedType;
      }
    }

    final casesOut = newCases.values.toList()
      ..sort((a, b) {
        final dateCompare = (a['releaseDate'] ?? '9999-99-99')
            .toString()
            .compareTo((b['releaseDate'] ?? '9999-99-99').toString());
        if (dateCompare != 0) {
          return dateCompare;
        }
        return (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        );
      });
    final skinsOut = newSkins.values.toList()
      ..sort(
        (a, b) => int.parse(
          a['id'].toString(),
        ).compareTo(int.parse(b['id'].toString())),
      );
    final stickersOut = newStickers.values.toList()
      ..sort(
        (a, b) => int.parse(
          a['id'].toString(),
        ).compareTo(int.parse(b['id'].toString())),
      );
    final pinsOut = newPins.values.toList()
      ..sort(
        (a, b) => int.parse(
          a['id'].toString(),
        ).compareTo(int.parse(b['id'].toString())),
      );
    final musicKitsOut = newMusicKits.values.toList()
      ..sort(
        (a, b) => int.parse(
          a['id'].toString(),
        ).compareTo(int.parse(b['id'].toString())),
      );
    final agentsOut = newAgents.values.toList()
      ..sort(
        (a, b) => int.parse(
          a['id'].toString(),
        ).compareTo(int.parse(b['id'].toString())),
      );
    final graffitiOut = newGraffiti.values.toList()
      ..sort(
        (a, b) => int.parse(
          a['id'].toString(),
        ).compareTo(int.parse(b['id'].toString())),
      );
    final patchesOut = newPatches.values.toList()
      ..sort(
        (a, b) => int.parse(
          a['id'].toString(),
        ).compareTo(int.parse(b['id'].toString())),
      );
    final charmsOut = newCharms.values.toList()
      ..sort(
        (a, b) => int.parse(
          a['id'].toString(),
        ).compareTo(int.parse(b['id'].toString())),
      );

    final containerContentsOut = buildContents(
      containerContentsMap,
      'containerId',
      'skinIds',
    );
    final stickerContentsOut = buildContents(
      stickerContentsMap,
      'containerId',
      'stickerIds',
    );
    final pinContentsOut = buildContents(
      pinContentsMap,
      'containerId',
      'pinIds',
    );
    final musicKitContentsOut = buildMusicKitContents(musicKitContentsMap);
    final agentCollectionsOut = newAgentCollections.values.toList()
      ..sort((a, b) {
        final dateCompare = (a['releaseDate'] ?? '9999-99-99')
            .toString()
            .compareTo((b['releaseDate'] ?? '9999-99-99').toString());
        if (dateCompare != 0) {
          return dateCompare;
        }
        return (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        );
      });
    final agentCollectionContentsOut = buildContents(
      agentCollectionContentsMap,
      'agentCollectionId',
      'agentIds',
    );
    final graffitiContentsOut = buildContents(
      graffitiContentsMap,
      'containerId',
      'graffitiIds',
    );
    final patchContentsOut = buildContents(
      patchContentsMap,
      'containerId',
      'patchIds',
    );
    final charmContentsOut = buildContents(
      charmContentsMap,
      'containerId',
      'charmIds',
    );
    final rewardCollectionsOut = newRewardCollections.values.toList()
      ..sort((a, b) {
        final sourceCompare = (a['sourceType'] ?? '').toString().compareTo(
          (b['sourceType'] ?? '').toString(),
        );
        if (sourceCompare != 0) {
          return sourceCompare;
        }
        final dateCompare = (a['releaseDate'] ?? '9999-99-99')
            .toString()
            .compareTo((b['releaseDate'] ?? '9999-99-99').toString());
        if (dateCompare != 0) {
          return dateCompare;
        }
        return (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        );
      });
    final rewardCollectionContentsOut = buildContents(
      rewardContentsMap,
      'rewardCollectionId',
      'skinIds',
    );
    final operationCollectionsOut = newOperationCollections.values.toList()
      ..sort((a, b) {
        final opCompare = (a['operationName'] ?? '').toString().compareTo(
          (b['operationName'] ?? '').toString(),
        );
        if (opCompare != 0) {
          return opCompare;
        }
        final dateCompare = (a['releaseDate'] ?? '9999-99-99')
            .toString()
            .compareTo((b['releaseDate'] ?? '9999-99-99').toString());
        if (dateCompare != 0) {
          return dateCompare;
        }
        return (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        );
      });
    final operationCollectionContentsOut = buildContents(
      operationContentsMap,
      'operationCollectionId',
      'skinIds',
    );

    await _io.writeJson(File('${dataDir.path}/containers.json'), casesOut);
    await _io.writeJson(File('${dataDir.path}/skins.json'), skinsOut);
    await _io.writeJson(File('${dataDir.path}/stickers.json'), stickersOut);
    await _io.writeJson(File('${dataDir.path}/pins.json'), pinsOut);
    await _io.writeJson(File('${dataDir.path}/music_kits.json'), musicKitsOut);
    await _io.writeJson(File('${dataDir.path}/agents.json'), agentsOut);
    await _io.writeJson(File('${dataDir.path}/graffiti.json'), graffitiOut);
    await _io.writeJson(File('${dataDir.path}/patches.json'), patchesOut);
    await _io.writeJson(File('${dataDir.path}/charms.json'), charmsOut);
    await _io.writeJson(
      File('${dataDir.path}/container_contents.json'),
      containerContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/sticker_contents.json'),
      stickerContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/pin_contents.json'),
      pinContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/music_kit_contents.json'),
      musicKitContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/agent_collection_contents.json'),
      agentCollectionContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/graffiti_contents.json'),
      graffitiContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/patch_contents.json'),
      patchContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/charm_contents.json'),
      charmContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/reward_collection_contents.json'),
      rewardCollectionContentsOut,
    );
    await _io.writeJson(
      File('${dataDir.path}/operation_collection_contents.json'),
      operationCollectionContentsOut,
    );

    _io.printInfo('Done.');
    _io.printInfo('Containers: ${casesOut.length}');
    _io.printInfo('Reward collections: ${rewardCollectionsOut.length}');
    _io.printInfo('Operation collections: ${operationCollectionsOut.length}');
    _io.printInfo('Agent collections: ${agentCollectionsOut.length}');
    _io.printInfo('Skins: ${skinsOut.length}');
    _io.printInfo('Stickers: ${stickersOut.length}');
    _io.printInfo('Pins: ${pinsOut.length}');
    _io.printInfo('Music kits: ${musicKitsOut.length}');
    _io.printInfo('Agents: ${agentsOut.length}');
    _io.printInfo('Graffiti: ${graffitiOut.length}');
    _io.printInfo('Patches: ${patchesOut.length}');
    _io.printInfo('Charms: ${charmsOut.length}');
    _io.printInfo('Container contents: ${containerContentsOut.length}');
    _io.printInfo('Sticker contents: ${stickerContentsOut.length}');
    _io.printInfo('Pin contents: ${pinContentsOut.length}');
    _io.printInfo('Music kit contents: ${musicKitContentsOut.length}');
    _io.printInfo(
      'Agent collection contents: ${agentCollectionContentsOut.length}',
    );
    _io.printInfo('Graffiti contents: ${graffitiContentsOut.length}');
    _io.printInfo('Patch contents: ${patchContentsOut.length}');
    _io.printInfo('Charm contents: ${charmContentsOut.length}');
    _io.printInfo(
      'Reward collection contents: ${rewardCollectionContentsOut.length}',
    );
    _io.printInfo(
      'Operation collection contents: ${operationCollectionContentsOut.length}',
    );
    _io.printInfo('Created skins: $createdSkinCount');
    _io.printInfo('Created stickers: $createdStickerCount');
    _io.printInfo('Created pins: $createdPinCount');
    _io.printInfo('Created music kits: $createdMusicKitCount');
    _io.printInfo('Created agents: $createdAgentCount');
    _io.printInfo('Created graffiti: $createdGraffitiCount');
    _io.printInfo('Created patches: $createdPatchCount');
    _io.printInfo('Created charms: $createdCharmCount');
    _io.printInfo('Reused skins: $reusedSkinCount');
    _io.printInfo('Reused stickers: $reusedStickerCount');
    _io.printInfo('Reused pins: $reusedPinCount');
    _io.printInfo('Reused music kits: $reusedMusicKitCount');
    _io.printInfo('Reused agents: $reusedAgentCount');
    _io.printInfo('Reused graffiti: $reusedGraffitiCount');
    _io.printInfo('Reused patches: $reusedPatchCount');
    _io.printInfo('Reused charms: $reusedCharmCount');
    _io.printInfo('Unknown items skipped: $skippedUnknownItems');
    _io.printInfo(
      'Containers created from skin.crates fallback: $containerRefsCreatedFromSkinMeta',
    );
    _io.printInfo('Reward collections created: $rewardCollectionsCreated');
    _io.printInfo(
      'Operation collections created: $operationCollectionsCreated',
    );
    _io.printInfo('Tournament logos downloaded: $tournamentLogosCreated');
  }

  Map<String, dynamic> _normalizeExistingContainerMeta(
    Map<String, dynamic> item,
  ) {
    final normalized = Map<String, dynamic>.from(item);
    final imagePath = (normalized['containerImage'] ?? normalized['caseImage'])
        ?.toString()
        .trim();

    if (imagePath != null && imagePath.isNotEmpty) {
      normalized['containerImage'] = imagePath.replaceAll(
        'assets/cases/',
        'assets/containers/',
      );
    }

    normalized.remove('caseImage');
    return normalized;
  }

  Map<String, Map<String, dynamic>> _loadRewardOverrides() {
    final overrides = <String, Map<String, dynamic>>{
      for (final entry in defaultRewardSourceOverrides.entries)
        normalizeCollectionName(entry.key) ?? entry.key:
            Map<String, dynamic>.from(entry.value),
    };

    if (rewardOverridesPath.existsSync()) {
      try {
        final userData = _io.loadJsonAny(rewardOverridesPath);
        if (userData is Map) {
          for (final entry in userData.entries) {
            if (entry.value is Map) {
              final name =
                  normalizeCollectionName(entry.key.toString().trim()) ??
                  entry.key.toString().trim();
              overrides[name] = Map<String, dynamic>.from(
                (entry.value as Map).map((k, v) => MapEntry(k.toString(), v)),
              );
            }
          }
        }
      } catch (exc) {
        _io.printInfo(
          '[WARN] failed to load ${rewardOverridesPath.path}: $exc',
        );
      }
    }

    return overrides;
  }

  List<Map<String, String>> _loadOperationOverrides() {
    final entries = defaultOperationCollectionOverrides
        .map((item) => Map<String, String>.from(item))
        .toList();

    if (operationOverridesPath.existsSync()) {
      try {
        final userData = _io.loadJsonAny(operationOverridesPath);
        if (userData is List) {
          for (final item in userData) {
            if (item is Map) {
              entries.add(
                item.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
              );
            }
          }
        }
      } catch (exc) {
        _io.printInfo(
          '[WARN] failed to load ${operationOverridesPath.path}: $exc',
        );
      }
    }

    final normalizedEntries = <Map<String, String>>[];
    for (final item in entries) {
      final name = normalizeCollectionName(item['name']?.trim()) ?? '';
      final operationId = item['operationId']?.trim() ?? '';
      final operationName = item['operationName']?.trim() ?? '';
      if (name.isEmpty || operationId.isEmpty || operationName.isEmpty) {
        continue;
      }
      normalizedEntries.add({
        'name': name,
        'operationId': operationId,
        'operationName': operationName,
        'releaseDate': item['releaseDate'] ?? '',
      });
    }

    return normalizedEntries;
  }

  List<Map<String, dynamic>> _asJsonList(dynamic decoded) {
    if (decoded is! List) {
      throw StateError('Expected JSON array');
    }
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  Future<String> _syncAsset({
    required String? imageUrl,
    required String dirPath,
    required String relativeDir,
    required String id,
    String? existingRelativePath,
    CompressionMode? compressionModeOverride,
  }) async {
    final existing = (existingRelativePath ?? '').trim();
    if (existing.isNotEmpty && File(existing).existsSync()) {
      return existing;
    }

    for (final ext in ['.webp', '.png', '.jpg', '.svg']) {
      final file = File('$dirPath/$id$ext');
      if (file.existsSync()) {
        return '$relativeDir/$id$ext';
      }
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final ext = await _io.downloadOptimizedAsset(
        imageUrl,
        '$dirPath/$id',
        compressionModeOverride: compressionModeOverride,
      );
      if (ext != null) {
        return '$relativeDir/$id$ext';
      }
    }

    if (existing.isNotEmpty) {
      return existing;
    }

    return '$relativeDir/$id.png';
  }

  Set<int> _extractUsedIds(List<Map<String, dynamic>> items) {
    final result = <int>{};
    for (final item in items) {
      final id = (item['id'] ?? '').toString();
      if (RegExp(r'^\d+$').hasMatch(id)) {
        result.add(int.parse(id));
      }
    }
    return result;
  }

  int _nextId(Set<int> used, int fallbackBase) {
    return (used.isEmpty
            ? fallbackBase
            : used.reduce((a, b) => a > b ? a : b)) +
        1;
  }
}
