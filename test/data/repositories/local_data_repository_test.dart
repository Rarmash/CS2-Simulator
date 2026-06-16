import 'package:cs2_simulator/data/repositories/local_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDataRepository repository;

  setUp(() {
    repository = LocalDataRepository();
  });

  test('loads containers sorted by release date', () async {
    final containers = await repository.loadContainers();

    expect(containers, isNotEmpty);
    expect(
      (containers.first.releaseDate ?? '').compareTo(
            containers.last.releaseDate ?? '',
          ) <=
          0,
      isTrue,
    );

    for (var i = 1; i < containers.length; i++) {
      expect(
        (containers[i - 1].releaseDate ?? '').compareTo(
              containers[i].releaseDate ?? '',
            ) <=
            0,
        isTrue,
      );
    }
  });

  test('groups phased skins into a shared skin family', () async {
    final groups = await repository.loadSkinGroups();
    final gammaDopplerGroup = groups.firstWhere(
      (group) =>
          group.primary.itemId == 'GLOCK_18' && group.name == 'Gamma Doppler',
    );

    expect(gammaDopplerGroup.hasMultipleVariants, isTrue);
    expect(gammaDopplerGroup.variantLabels, contains('Emerald'));
    expect(gammaDopplerGroup.variantLabels, contains('Phase 3'));
  });

  test('loads all variants for a selected grouped skin', () async {
    final groups = await repository.loadSkinGroups();
    final gammaDopplerGroup = groups.firstWhere(
      (group) =>
          group.primary.itemId == 'GLOCK_18' && group.name == 'Gamma Doppler',
    );

    final variants = await repository.loadSkinVariantsForSkin(
      gammaDopplerGroup.primary.id,
    );

    expect(variants.length, gammaDopplerGroup.variants.length);
    expect(
      variants.map((variant) => variant.id),
      containsAll([
        for (final variant in gammaDopplerGroup.variants) variant.id,
      ]),
    );
  });

  test('groups music kit variants by shared identity', () async {
    final groups = await repository.loadGroupedMusicKits();
    final group = groups.firstWhere(
      (item) =>
          item.name == 'Austin Wintory, The Devil Went Clubbing In Georgia' &&
          item.collection == 'Masterminds 2',
    );

    expect(group.hasRegular, isTrue);
    expect(group.hasStatTrak, isTrue);
    expect(group.variants, isNotEmpty);
  });

  test('resolves grouped music kit sources back to their container', () async {
    final containers = await repository.loadContainersForMusicKitGroup(
      'Austin Wintory, The Devil Went Clubbing In Georgia',
      'Masterminds 2',
    );

    expect(containers, isNotEmpty);
    expect(
      containers.any(
        (container) => container.name == 'Masterminds 2 Music Kit Box',
      ),
      isTrue,
    );
  });

  test(
    'loads tournaments with canonical names and ignored RMR removed',
    () async {
      final tournaments = await repository.loadTournaments();

      expect(tournaments, isNotEmpty);
      expect(
        tournaments.any((tournament) => tournament.name.contains('2020 RMR')),
        isFalse,
      );
      expect(
        tournaments
            .where((tournament) => tournament.name.contains('Krak'))
            .length,
        1,
      );
      expect(
        tournaments.any(
          (tournament) => tournament.name == 'BLAST.tv Austin 2025',
        ),
        isTrue,
      );
      final cologne = tournaments.firstWhere(
        (tournament) => tournament.name == 'IEM Cologne 2026',
      );
      expect(cologne.startDate, '2026-06-02');
      expect(cologne.endDate, '2026-06-21');
      expect(cologne.souvenirPackageCount, 0);
      expect(cologne.stickerContainerCount, 0);
    },
  );

  test('loads tournament metadata with stage dates and winner', () async {
    final metadata = await repository.loadTournamentMetadataByName(
      'BLAST.tv Austin 2025',
    );

    expect(metadata, isNotNull);
    expect(metadata!.winner, 'Team Vitality');
    expect(metadata.startDate, '2025-06-03');
    expect(metadata.endDate, '2025-06-22');
    expect(metadata.stageDates.map((item) => item.phase), contains('Stage 3'));
  });

  test('loads souvenir packages for a tournament', () async {
    final packages = await repository.loadSouvenirPackagesForTournament(
      'DreamHack Winter 2013',
    );

    expect(packages, isNotEmpty);
    expect(
      packages.every(
        (container) =>
            container.isSouvenirPackage &&
            container.tournamentName == 'DreamHack Winter 2013',
      ),
      isTrue,
    );
  });

  test('loads sticker containers linked to a tournament', () async {
    final containers = await repository.loadStickerContainersForTournament(
      'BLAST.tv Paris 2023',
    );

    expect(containers, isNotEmpty);
    expect(
      containers.every(
        (container) =>
            container.isStickerCapsule || container.isStickerCollection,
      ),
      isTrue,
    );
  });

  test(
    'canonicalizes team summaries across legacy organization names',
    () async {
      final teams = await repository.loadTournamentTeams();

      expect(teams.any((team) => team.teamName == 'MOUZ'), isTrue);
      expect(teams.any((team) => team.teamName == 'mousesports'), isFalse);
      expect(teams.any((team) => team.teamName == 'Gambit Esports'), isTrue);
      expect(teams.any((team) => team.teamName == 'Gambit Gaming'), isFalse);
    },
  );

  test('canonicalizes team tournament results for legacy aliases', () async {
    final results = await repository.loadTeamTournamentResults('mousesports');

    expect(results, isNotEmpty);
    expect(results.every((result) => result.teamName == 'MOUZ'), isTrue);
  });

  test('loads player summaries with canonical player display names', () async {
    final players = await repository.loadTournamentPlayers();

    expect(players.any((player) => player.playerName == 'electroNic'), isTrue);
    expect(players.any((player) => player.playerName == 'electronic'), isFalse);
  });

  test('loads player appearances from tournament rosters', () async {
    final appearances = await repository.loadPlayerTournamentAppearances(
      'ropz',
    );

    expect(appearances, isNotEmpty);
    expect(
      appearances.any(
        (appearance) =>
            appearance.tournamentName == 'PGL Stockholm 2021' &&
            appearance.teamName == 'MOUZ',
      ),
      isTrue,
    );
  });

  test('loads tournament players from roster context', () async {
    final players = await repository.loadPlayersForTournament(
      'PGL Stockholm 2021',
    );

    expect(players.any((player) => player.playerName == 'ropz'), isTrue);
  });

  test('resolves item source lookups back to their owning sources', () async {
    final containerContents = await repository.loadContainerContents();
    final stickerContents = await repository.loadStickerContents();
    final pinContents = await repository.loadPinContents();
    final rewardContents = await repository.loadRewardCollectionContents();
    final agentContents = await repository.loadAgentCollectionContents();

    final skinSources = await repository.loadContainersForSkin(
      containerContents.first.skinIds.first,
    );
    final stickerSources = await repository.loadContainersForSticker(
      stickerContents.first.stickerIds.first,
    );
    final pinSources = await repository.loadContainersForPin(
      pinContents.first.pinIds.first,
    );
    final rewardSources = await repository.loadRewardCollectionsForSkin(
      rewardContents.first.skinIds.first,
    );
    final agentSources = await repository.loadAgentCollectionsForAgent(
      agentContents.first.agentIds.first,
    );

    expect(
      skinSources.any(
        (container) => container.id == containerContents.first.containerId,
      ),
      isTrue,
    );
    expect(
      stickerSources.any(
        (container) => container.id == stickerContents.first.containerId,
      ),
      isTrue,
    );
    expect(
      pinSources.any(
        (container) => container.id == pinContents.first.containerId,
      ),
      isTrue,
    );
    expect(
      rewardSources.any(
        (container) => container.id == rewardContents.first.rewardCollectionId,
      ),
      isTrue,
    );
    expect(
      agentSources.any(
        (container) => container.id == agentContents.first.agentCollectionId,
      ),
      isTrue,
    );
  });
}
