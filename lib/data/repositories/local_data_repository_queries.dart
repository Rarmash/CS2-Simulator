part of 'local_data_repository.dart';

mixin _LocalDataRepositoryQueries on _LocalDataRepositoryLoaders {
  Future<List<TournamentDto>> loadTournaments() async {
    final containers = await loadContainers();
    final stickers = await loadStickers();
    final stickerContents = await loadStickerContents();
    final metadata = await loadTournamentMetadata();
    final metadataByName = {
      for (final entry in metadata) _canonicalTournamentName(entry.name): entry,
    };

    final containerById = {
      for (final container in containers) container.id: container,
    };
    final stickerById = {for (final sticker in stickers) sticker.id: sticker};
    final tournamentBuilders = <String, _TournamentBuilder>{};

    _TournamentBuilder ensureBuilder(String tournamentName) {
      final canonicalName = _canonicalTournamentName(tournamentName);
      if (_isIgnoredTournamentName(canonicalName)) {
        return _TournamentBuilder(name: '');
      }
      return tournamentBuilders.putIfAbsent(
        canonicalName,
        () => _TournamentBuilder(name: canonicalName),
      );
    }

    for (final container in containers) {
      final tournamentName = (container.tournamentName ?? '').trim();
      if (tournamentName.isEmpty) continue;

      final builder = ensureBuilder(tournamentName);
      if (builder.name.isEmpty) continue;
      builder.imagePath ??=
          metadataByName[builder.name]?.tournamentLogo ??
          _preferredTournamentImage(container);
      builder.releaseDate = _earlierDate(
        builder.releaseDate,
        container.releaseDate,
      );

      if (container.isSouvenirPackage) {
        builder.souvenirContainerIds.add(container.id);
      }
      if (container.isStickerCapsule || container.isStickerCollection) {
        builder.stickerContainerIds.add(container.id);
      }
    }

    for (final content in stickerContents) {
      final container = containerById[content.containerId];
      if (container == null) continue;

      final tournamentNames = <String>{};
      for (final stickerId in content.stickerIds) {
        final tournamentName = (stickerById[stickerId]?.tournament ?? '')
            .trim();
        if (tournamentName.isNotEmpty) {
          tournamentNames.add(tournamentName);
        }
      }

      for (final tournamentName in tournamentNames) {
        final builder = ensureBuilder(tournamentName);
        if (builder.name.isEmpty) continue;
        builder.imagePath ??=
            metadataByName[builder.name]?.tournamentLogo ??
            _preferredTournamentImage(container);
        builder.releaseDate = _earlierDate(
          builder.releaseDate,
          container.releaseDate,
        );

        if (container.isStickerCapsule || container.isStickerCollection) {
          builder.stickerContainerIds.add(container.id);
        }
      }
    }

    final tournaments = tournamentBuilders.values
        .where((builder) => builder.imagePath != null)
        .map((builder) {
          final metadata = metadataByName[builder.name];
          return TournamentDto(
            name: builder.name,
            imagePath: ((metadata?.tournamentLogo ?? '').trim().isNotEmpty
                ? metadata!.tournamentLogo!
                : builder.imagePath!),
            releaseDate: builder.releaseDate,
            startDate: metadata?.startDate,
            endDate: metadata?.endDate,
            organizer: _inferTournamentOrganizer(builder.name),
            souvenirPackageCount: builder.souvenirContainerIds.length,
            stickerContainerCount: builder.stickerContainerIds.length,
          );
        })
        .toList();

    tournaments.sort((a, b) {
      final byDate = (b.startDate ?? b.releaseDate ?? '').compareTo(
        a.startDate ?? a.releaseDate ?? '',
      );
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return tournaments;
  }

  Future<List<TournamentTeamResultDto>> loadTeamTournamentResults(
    String teamName,
  ) async {
    final canonicalTeamName = TeamNameHelper.canonicalize(teamName);
    final tournaments = await loadTournaments();
    final metadata = await loadTournamentMetadata();
    final tournamentByName = {
      for (final tournament in tournaments)
        _canonicalTournamentName(tournament.name): tournament,
    };

    final results = <TournamentTeamResultDto>[];
    for (final entry in metadata) {
      final tournament = tournamentByName[_canonicalTournamentName(entry.name)];
      if (tournament == null) {
        continue;
      }

      for (final placement in entry.placements) {
        if (TeamNameHelper.canonicalize(placement.team) != canonicalTeamName) {
          continue;
        }
        results.add(
          TournamentTeamResultDto(
            teamName: canonicalTeamName,
            teamLogo: placement.teamLogo,
            tournamentName: tournament.name,
            tournamentImagePath: tournament.imagePath,
            organizer: tournament.organizer,
            place: placement.place,
            startDate: entry.startDate ?? tournament.startDate,
            endDate: entry.endDate ?? tournament.endDate,
          ),
        );
      }
    }

    results.sort((a, b) {
      final byDate = (b.startDate ?? '').compareTo(a.startDate ?? '');
      if (byDate != 0) return byDate;
      return a.tournamentName.compareTo(b.tournamentName);
    });
    return results;
  }

  Future<List<TournamentTeamSummaryDto>> loadTournamentTeams() async {
    final results = <String, List<TournamentTeamResultDto>>{};
    final allResults = await _loadAllTeamTournamentResults();

    for (final result in allResults) {
      results
          .putIfAbsent(result.teamName, () => <TournamentTeamResultDto>[])
          .add(result);
    }

    final summaries = results.entries.map((entry) {
      final items = List<TournamentTeamResultDto>.from(entry.value)
        ..sort((a, b) {
          final byDate = (b.startDate ?? '').compareTo(a.startDate ?? '');
          if (byDate != 0) return byDate;
          return _comparePlace(a.place, b.place);
        });

      String? bestPlace;
      for (final item in items) {
        if (bestPlace == null || _comparePlace(item.place, bestPlace) < 0) {
          bestPlace = item.place;
        }
      }

      final latest = items.isNotEmpty ? items.first : null;
      final titleCount = items.where((item) => item.place == '1st').length;

      return TournamentTeamSummaryDto(
        teamName: entry.key,
        teamLogo: items
            .map((item) => item.teamLogo)
            .firstWhere((logo) => (logo ?? '').isNotEmpty, orElse: () => null),
        tournamentCount: items.length,
        titleCount: titleCount,
        bestPlace: bestPlace,
        latestTournamentName: latest?.tournamentName,
        latestTournamentImagePath: latest?.tournamentImagePath,
        latestStartDate: latest?.startDate,
      );
    }).toList();

    summaries.sort((a, b) {
      final byTitles = b.titleCount.compareTo(a.titleCount);
      if (byTitles != 0) return byTitles;
      final byBestPlace = _comparePlace(a.bestPlace, b.bestPlace);
      if (byBestPlace != 0) return byBestPlace;
      final byAppearances = b.tournamentCount.compareTo(a.tournamentCount);
      if (byAppearances != 0) return byAppearances;
      return a.teamName.compareTo(b.teamName);
    });

    return summaries;
  }

  Future<List<TournamentPlayerSummaryDto>> loadTournamentPlayers() async {
    final appearances = await _loadAllPlayerAppearances();
    final grouped = <String, List<TournamentPlayerAppearanceDto>>{};

    for (final appearance in appearances) {
      grouped
          .putIfAbsent(
            _playerLookupKey(appearance.playerName),
            () => <TournamentPlayerAppearanceDto>[],
          )
          .add(appearance);
    }

    final summaries = grouped.entries.map((entry) {
      final items = List<TournamentPlayerAppearanceDto>.from(entry.value)
        ..sort((a, b) {
          final byDate = (b.startDate ?? '').compareTo(a.startDate ?? '');
          if (byDate != 0) return byDate;
          return a.playerName.compareTo(b.playerName);
        });

      final latest = items.isNotEmpty ? items.first : null;
      final autographCount = items.fold<int>(
        0,
        (sum, item) => sum + item.autographCount,
      );
      String? bestPlace;
      for (final item in items) {
        if ((item.place ?? '').isEmpty) {
          continue;
        }
        if (bestPlace == null || _comparePlace(item.place, bestPlace) < 0) {
          bestPlace = item.place;
        }
      }
      final titleCount = items.where((item) => item.place == '1st').length;

      return TournamentPlayerSummaryDto(
        playerName: latest?.playerName ?? entry.value.first.playerName,
        tournamentCount: items.length,
        autographCount: autographCount,
        titleCount: titleCount,
        bestPlace: bestPlace,
        latestTournamentName: latest?.tournamentName,
        latestTournamentImagePath: latest?.tournamentImagePath,
        latestStartDate: latest?.startDate,
        latestTeamName: latest?.teamName,
        latestTeamLogo: latest?.teamLogo,
        sampleStickerImage: latest?.sampleStickerImage,
      );
    }).toList();

    summaries.sort((a, b) {
      final byTournaments = b.tournamentCount.compareTo(a.tournamentCount);
      if (byTournaments != 0) return byTournaments;
      final byAutographs = b.autographCount.compareTo(a.autographCount);
      if (byAutographs != 0) return byAutographs;
      return a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase());
    });

    return summaries;
  }

  Future<List<TournamentPlayerAppearanceDto>> loadPlayerTournamentAppearances(
    String playerName,
  ) async {
    final canonical = _playerLookupKey(playerName);
    final appearances = await _loadAllPlayerAppearances();
    final result =
        appearances
            .where(
              (appearance) =>
                  _playerLookupKey(appearance.playerName) == canonical,
            )
            .toList()
          ..sort((a, b) {
            final byDate = (b.startDate ?? '').compareTo(a.startDate ?? '');
            if (byDate != 0) return byDate;
            return a.tournamentName.compareTo(b.tournamentName);
          });
    return result;
  }

  Future<List<TournamentPlayerSummaryDto>> loadPlayersForTournament(
    String tournamentName,
  ) async {
    final normalizedTournamentName = _canonicalTournamentName(tournamentName);
    final appearances = await _loadAllPlayerAppearances();
    final grouped = <String, List<TournamentPlayerAppearanceDto>>{};

    for (final appearance in appearances) {
      if (_canonicalTournamentName(appearance.tournamentName) !=
          normalizedTournamentName) {
        continue;
      }
      grouped
          .putIfAbsent(
            _playerLookupKey(appearance.playerName),
            () => <TournamentPlayerAppearanceDto>[],
          )
          .add(appearance);
    }

    final result =
        grouped.entries.map((entry) {
          final items = entry.value;
          final first = items.first;
          return TournamentPlayerSummaryDto(
            playerName: first.playerName,
            tournamentCount: items.length,
            autographCount: items.fold<int>(
              0,
              (sum, item) => sum + item.autographCount,
            ),
            titleCount: items.where((item) => item.place == '1st').length,
            bestPlace: (() {
              String? bestPlace;
              for (final item in items) {
                if ((item.place ?? '').isEmpty) {
                  continue;
                }
                if (bestPlace == null ||
                    _comparePlace(item.place, bestPlace) < 0) {
                  bestPlace = item.place;
                }
              }
              return bestPlace;
            })(),
            latestTournamentName: first.tournamentName,
            latestTournamentImagePath: first.tournamentImagePath,
            latestStartDate: first.startDate,
            latestTeamName: first.teamName,
            latestTeamLogo: first.teamLogo,
            sampleStickerImage: first.sampleStickerImage,
          );
        }).toList()..sort(
          (a, b) =>
              a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase()),
        );

    return result;
  }

  Future<TournamentMetadataDto?> loadTournamentMetadataByName(
    String tournamentName,
  ) async {
    final metadata = await loadTournamentMetadata();
    final normalizedName = _canonicalTournamentName(tournamentName);

    for (final entry in metadata) {
      if (_canonicalTournamentName(entry.name) == normalizedName) {
        return entry;
      }
    }

    return null;
  }

  Future<List<ContainerDto>> loadSouvenirPackagesForTournament(
    String tournamentName,
  ) async {
    final containers = await loadContainers();
    final normalizedTournamentName = _canonicalTournamentName(tournamentName);
    final result = containers
        .where(
          (container) =>
              container.isSouvenirPackage &&
              _canonicalTournamentName(
                    (container.tournamentName ?? '').trim(),
                  ) ==
                  normalizedTournamentName,
        )
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<ContainerDto>> loadStickerContainersForTournament(
    String tournamentName,
  ) async {
    final containers = await loadContainers();
    final stickerContents = await loadStickerContents();
    final stickers = await loadStickers();
    final normalizedTournamentName = _canonicalTournamentName(tournamentName);

    final stickerById = {for (final sticker in stickers) sticker.id: sticker};
    final relevantContainerIds = <String>{};

    for (final content in stickerContents) {
      final hasTournamentSticker = content.stickerIds.any(
        (stickerId) =>
            _canonicalTournamentName(
              (stickerById[stickerId]?.tournament ?? '').trim(),
            ) ==
            normalizedTournamentName,
      );
      if (hasTournamentSticker) {
        relevantContainerIds.add(content.containerId);
      }
    }

    final result = containers
        .where(
          (container) =>
              relevantContainerIds.contains(container.id) &&
              (container.isStickerCapsule || container.isStickerCollection),
        )
        .toList();
    result.sort(_compareContainerByReleaseDateAsc);
    return result;
  }

  Future<List<TournamentTeamResultDto>> _loadAllTeamTournamentResults() async {
    final tournaments = await loadTournaments();
    final metadata = await loadTournamentMetadata();
    final tournamentByName = {
      for (final tournament in tournaments)
        _canonicalTournamentName(tournament.name): tournament,
    };

    final results = <TournamentTeamResultDto>[];
    for (final entry in metadata) {
      final tournament = tournamentByName[_canonicalTournamentName(entry.name)];
      if (tournament == null) {
        continue;
      }

      for (final placement in entry.placements) {
        final canonicalTeamName = TeamNameHelper.canonicalize(placement.team);
        results.add(
          TournamentTeamResultDto(
            teamName: canonicalTeamName,
            teamLogo: placement.teamLogo,
            tournamentName: tournament.name,
            tournamentImagePath: tournament.imagePath,
            organizer: tournament.organizer,
            place: placement.place,
            startDate: entry.startDate ?? tournament.startDate,
            endDate: entry.endDate ?? tournament.endDate,
          ),
        );
      }
    }

    return results;
  }

  Future<List<TournamentPlayerAppearanceDto>>
  _loadAllPlayerAppearances() async {
    final tournaments = await loadTournaments();
    final metadata = await loadTournamentMetadata();
    final tournamentByName = {
      for (final tournament in tournaments)
        _canonicalTournamentName(tournament.name): tournament,
    };
    final metadataByName = {
      for (final entry in metadata) _canonicalTournamentName(entry.name): entry,
    };
    final teamInfoByPlayerTournament =
        <
          String,
          ({
            String playerName,
            String? teamName,
            String? teamLogo,
            String? place,
          })
        >{};

    for (final entry in metadata) {
      final canonicalTournamentName = _canonicalTournamentName(entry.name);
      final placeByTeam = {
        for (final placement in entry.placements)
          TeamNameHelper.canonicalize(placement.team): placement,
      };

      for (final roster in entry.teamRosters) {
        final canonicalTeamName = TeamNameHelper.canonicalize(roster.team);
        final placement = placeByTeam[canonicalTeamName];
        for (final player in roster.players) {
          final playerKey = _playerLookupKey(player);
          teamInfoByPlayerTournament['$playerKey|$canonicalTournamentName'] = (
            playerName: _preferredPlayerDisplayName(player),
            teamName: roster.team,
            teamLogo: roster.teamLogo ?? placement?.teamLogo,
            place: placement?.place,
          );
        }
      }
    }

    final grouped = <String, _PlayerAppearanceBuilder>{};

    for (final entry in metadata) {
      final canonicalTournamentName = _canonicalTournamentName(entry.name);
      final tournament = tournamentByName[canonicalTournamentName];
      if (tournament == null) {
        continue;
      }

      for (final roster in entry.teamRosters) {
        final canonicalTeamName = TeamNameHelper.canonicalize(roster.team);
        final placement = entry.placements
            .where(
              (item) =>
                  TeamNameHelper.canonicalize(item.team) == canonicalTeamName,
            )
            .cast<TournamentPlacementDto?>()
            .firstOrNull;

        for (final rawPlayerName in roster.players) {
          final playerName = _preferredPlayerDisplayName(rawPlayerName);
          final key =
              '${_playerLookupKey(playerName)}|$canonicalTournamentName';
          grouped.putIfAbsent(
            key,
            () => _PlayerAppearanceBuilder(
              playerName: playerName,
              teamName: roster.team,
              teamLogo: roster.teamLogo ?? placement?.teamLogo,
              place: placement?.place,
              tournamentName: tournament.name,
              tournamentImagePath: tournament.imagePath,
              startDate: entry.startDate ?? tournament.startDate,
              endDate: entry.endDate ?? tournament.endDate,
            ),
          );
        }
      }
    }

    final stickers = await loadStickers();
    for (final sticker in stickers) {
      if (sticker.stickerType != 'AUTOGRAPH') {
        continue;
      }

      final tournamentName = (sticker.tournament ?? '').trim();
      if (tournamentName.isEmpty) {
        continue;
      }

      final canonicalTournamentName = _canonicalTournamentName(tournamentName);
      final tournament = tournamentByName[canonicalTournamentName];
      if (tournament == null) {
        continue;
      }

      final playerName = _extractAutographPlayerName(sticker.name);
      if (playerName.isEmpty) {
        continue;
      }

      final key = '${_playerLookupKey(playerName)}|$canonicalTournamentName';
      final builder = grouped.putIfAbsent(key, () {
        final teamInfo = teamInfoByPlayerTournament[key];
        final tournamentMetadata = metadataByName[canonicalTournamentName];
        return _PlayerAppearanceBuilder(
          playerName: teamInfo?.playerName ?? playerName,
          teamName: teamInfo?.teamName,
          teamLogo: teamInfo?.teamLogo,
          place: teamInfo?.place,
          tournamentName: tournament.name,
          tournamentImagePath: tournament.imagePath,
          startDate: tournamentMetadata?.startDate ?? tournament.startDate,
          endDate: tournamentMetadata?.endDate ?? tournament.endDate,
        );
      });
      builder.autographCount += 1;
      builder.sampleStickerImage ??= sticker.stickerImage;
      builder.effects.add(_autographEffectLabel(sticker.effect));
    }

    return grouped.values
        .map(
          (item) => TournamentPlayerAppearanceDto(
            playerName: item.playerName,
            teamName: item.teamName,
            teamLogo: item.teamLogo,
            place: item.place,
            tournamentName: item.tournamentName,
            tournamentImagePath: item.tournamentImagePath,
            startDate: item.startDate,
            endDate: item.endDate,
            autographCount: item.autographCount,
            effects: item.effects.toList()..sort(),
            sampleStickerImage: item.sampleStickerImage,
          ),
        )
        .toList();
  }

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

class _TournamentBuilder {
  final String name;
  String? imagePath;
  String? releaseDate;
  final Set<String> souvenirContainerIds = <String>{};
  final Set<String> stickerContainerIds = <String>{};

  _TournamentBuilder({required this.name});
}

class _PlayerAppearanceBuilder {
  final String playerName;
  final String? teamName;
  final String? teamLogo;
  final String? place;
  final String tournamentName;
  final String tournamentImagePath;
  final String? startDate;
  final String? endDate;
  int autographCount = 0;
  String? sampleStickerImage;
  final Set<String> effects = <String>{};

  _PlayerAppearanceBuilder({
    required this.playerName,
    required this.teamName,
    required this.teamLogo,
    required this.place,
    required this.tournamentName,
    required this.tournamentImagePath,
    required this.startDate,
    required this.endDate,
  });
}

String? _earlierDate(String? a, String? b) {
  if (a == null || a.isEmpty) return b;
  if (b == null || b.isEmpty) return a;
  return a.compareTo(b) <= 0 ? a : b;
}

String _preferredTournamentImage(ContainerDto container) {
  final tournamentLogo = (container.tournamentLogo ?? '').trim();
  if (tournamentLogo.isNotEmpty) {
    return tournamentLogo;
  }
  return container.containerImage;
}

String _extractAutographPlayerName(String stickerName) {
  final left = stickerName.split(' | ').first.trim();
  return _preferredPlayerDisplayName(
    _cleanPlayerName(left.replaceFirst(RegExp(r'\s+\([^)]*\)$'), '')),
  );
}

String _cleanPlayerName(String playerName) {
  return playerName
      .trim()
      .replaceAll(RegExp(r'\s*\|[A-Za-z0-9_]+\s*=.*$'), '')
      .replaceFirst(RegExp(r'\s+\([^)]*\)$'), '')
      .trim();
}

String _playerLookupKey(String playerName) {
  return _cleanPlayerName(playerName).toLowerCase();
}

String _preferredPlayerDisplayName(String playerName) {
  return _preferredPlayerNames[_playerLookupKey(playerName)] ??
      _cleanPlayerName(playerName);
}

const _preferredPlayerNames = <String, String>{
  'adren': 'AdreN',
  'amanek': 'AmaNEk',
  'dycha': 'dycha',
  'electronic': 'electroNic',
  'hobbit': 'Hobbit',
  'ins': 'INS',
  'jackz': 'JACKZ',
  'niko': 'NiKo',
  'qikert': 'Qikert',
  'sico': 'sico',
  'tenzki': 'TENZKI',
};

String _autographEffectLabel(String effect) {
  switch (effect) {
    case 'FOIL':
      return 'Foil';
    case 'GOLD':
      return 'Gold';
    case 'GLITTER':
      return 'Glitter';
    case 'HOLO':
      return 'Holo';
    default:
      return 'Paper';
  }
}

String _inferTournamentOrganizer(String tournamentName) {
  const prefixes = <String, String>{
    'DreamHack ': 'DreamHack',
    'EMS One ': 'EMS One',
    'ESL One ': 'ESL One',
    'MLG ': 'MLG',
    'ELEAGUE ': 'ELEAGUE',
    'PGL ': 'PGL',
    'FACEIT ': 'FACEIT',
    'StarLadder ': 'StarLadder',
    'IEM ': 'Intel Extreme Masters',
    'BLAST.tv ': 'BLAST.tv',
    'Perfect World ': 'Perfect World',
  };

  for (final entry in prefixes.entries) {
    if (tournamentName.startsWith(entry.key)) {
      return entry.value;
    }
  }

  return tournamentName.split(' ').first;
}

String _canonicalTournamentName(String rawTournamentName) {
  final trimmed = rawTournamentName
      .trim()
      .replaceAll('ELEAGUE Major Boston 2018', 'ELEAGUE Boston 2018')
      .replaceAll('KrakГіw', 'Kraków')
      .replaceAll('Krakow', 'Kraków')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final yearPrefix = RegExp(r'^(20\d{2}) (.+)$').firstMatch(trimmed);
  if (yearPrefix != null) {
    final year = yearPrefix.group(1)!;
    final rest = yearPrefix.group(2)!;
    return '$rest $year';
  }

  return trimmed;
}

bool _isIgnoredTournamentName(String tournamentName) {
  return tournamentName == '2020 RMR' ||
      tournamentName.contains('2020 RMR') ||
      tournamentName.contains('RMR 2020');
}

int _comparePlace(String? a, String? b) {
  final rankA = _placeRank(a);
  final rankB = _placeRank(b);
  if (rankA != rankB) {
    return rankA.compareTo(rankB);
  }
  return (a ?? '').compareTo(b ?? '');
}

int _placeRank(String? place) {
  if (place == null || place.isEmpty) {
    return 1 << 20;
  }

  final match = RegExp(
    r'^(\d+)(?:st|nd|rd|th)?(?:-(\d+)(?:st|nd|rd|th)?)?$',
  ).firstMatch(place);
  if (match == null) {
    return 1 << 20;
  }

  final start = int.tryParse(match.group(1) ?? '');
  return start ?? (1 << 20);
}
