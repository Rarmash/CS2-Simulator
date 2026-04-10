import 'package:flutter/material.dart';

import '../../core/utils/team_name_helper.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/tournament_dto.dart';
import '../../data/models/tournament_metadata_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_source_section.dart';
import '../widgets/detail_source_tile.dart';
import '../widgets/detail_tag.dart';
import '../widgets/adaptive_logo_image.dart';
import '../widgets/major_summary_card.dart';
import 'player_details_screen.dart';
import 'team_details_screen.dart';

class TournamentDetailsScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final TournamentDto tournament;

  const TournamentDetailsScreen({
    super.key,
    required this.repository,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tournament.name)),
      body: FutureBuilder<_TournamentDetailsData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load tournament details.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ?? const _TournamentDetailsData();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              MajorSummaryCard(
                leading: AdaptiveLogoImage(
                  logoPath: tournament.imagePath,
                  height: 170,
                  fit: BoxFit.contain,
                  fallback: const Icon(Icons.emoji_events, size: 72),
                ),
                title: tournament.name,
                subtitle: tournament.organizer,
                tags: [
                  DetailTag(text: 'Major', color: Colors.amber.shade400),
                  DetailTag(text: tournament.eraLabel),
                ],
                infoRows: [
                  DetailInfoRow(
                    title: 'Organizer',
                    value: tournament.organizer,
                  ),
                  if (data.metadata != null)
                    DetailInfoRow(
                      title: 'Winner',
                      value: data.metadata!.winner,
                    ),
                  DetailInfoRow(title: 'Era', value: tournament.eraLabel),
                  if (data.metadata?.startDate != null ||
                      data.metadata?.endDate != null)
                    DetailInfoRow(
                      title: 'Tournament Dates',
                      value:
                          DateFormatHelper.formatDateRange(
                            data.metadata?.startDate,
                            data.metadata?.endDate,
                          ) ??
                          '-',
                    ),
                  DetailInfoRow(
                    title: 'Souvenir Packages',
                    value: data.souvenirPackages.length.toString(),
                  ),
                  DetailInfoRow(
                    title: 'Sticker Sources',
                    value: data.stickerSources.length.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_hasMeaningfulPlayoffBracket(data.metadata)) ...[
                DetailSourceSection<TournamentPlayoffMatchDto>(
                  title: 'Playoff Bracket',
                  items: data.metadata!.playoffMatches,
                  emptyText: 'No playoff bracket data available.',
                  itemBuilder: (_) => const SizedBox.shrink(),
                  contentBuilder: (items) =>
                      _buildPlayoffBracket(context, items, data.metadata),
                ),
                const SizedBox(height: 12),
              ],
              DetailSourceSection<TournamentPlacementDto>(
                title: 'Placements',
                items:
                    data.metadata?.placements ??
                    const <TournamentPlacementDto>[],
                emptyText: 'No placement data added for this tournament yet.',
                itemBuilder: (_) => const SizedBox.shrink(),
                contentBuilder: (items) =>
                    _buildPlacementsByPhase(context, items, data.metadata),
              ),
              const SizedBox(height: 12),
              DetailSourceSection<ContainerDto>(
                title: 'Souvenir Packages',
                items: data.souvenirPackages,
                emptyText: 'No souvenir packages found for this tournament.',
                itemBuilder: (item) => _buildContainerTile(context, item),
              ),
              const SizedBox(height: 12),
              DetailSourceSection<ContainerDto>(
                title: 'Sticker and Autograph Capsules',
                items: data.stickerSources,
                emptyText: 'No sticker sources found for this tournament.',
                itemBuilder: (item) => _buildContainerTile(context, item),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_TournamentDetailsData> _loadData() async {
    final souvenirPackages = await repository.loadSouvenirPackagesForTournament(
      tournament.name,
    );
    final stickerSources = await repository.loadStickerContainersForTournament(
      tournament.name,
    );
    final metadata = await repository.loadTournamentMetadataByName(
      tournament.name,
    );
    return _TournamentDetailsData(
      metadata: metadata,
      souvenirPackages: souvenirPackages,
      stickerSources: stickerSources,
    );
  }

  Widget _buildPlacementsByPhase(
    BuildContext context,
    List<TournamentPlacementDto> items,
    TournamentMetadataDto? metadata,
  ) {
    final scheme = _placementScheme(tournament);
    if (scheme == _PlacementScheme.none) {
      return _buildPlacementRows(context, items, metadata);
    }

    final groupedByPhase = <String, List<TournamentPlacementDto>>{};
    for (final item in items) {
      final phase = _placementPhaseLabel(tournament, item.place);
      groupedByPhase
          .putIfAbsent(phase, () => <TournamentPlacementDto>[])
          .add(item);
    }

    final orderedPhases = groupedByPhase.keys.toList()
      ..sort(
        (a, b) => _placementPhaseOrder(
          tournament,
          a,
        ).compareTo(_placementPhaseOrder(tournament, b)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MajorSectionHeader(
          icon: Icons.format_list_numbered,
          title: 'Final Placements',
          subtitle: 'Grouped by the tournament stage where teams finished.',
        ),
        for (final phase in orderedPhases) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  _placementPhaseIcon(phase),
                  size: 18,
                  color: Colors.amber.shade300,
                ),
                const SizedBox(width: 8),
                Text(
                  phase,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_stageDateText(metadata, phase) case final dateText?)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      dateText,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildPlacementRows(context, groupedByPhase[phase]!, metadata),
          if (phase != orderedPhases.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildPlacementRows(
    BuildContext context,
    List<TournamentPlacementDto> items,
    TournamentMetadataDto? metadata,
  ) {
    final grouped = <String, List<String>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.place, () => <String>[]).add(item.team);
    }

    return Column(
      children: [
        for (final entry in grouped.entries)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 68,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final team in entry.value)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            _showTournamentTeamSheet(
                              context,
                              team: team,
                              logoPath: items
                                  .firstWhere((item) => item.team == team)
                                  .teamLogo,
                              metadata: metadata,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TeamLogo(
                                  logoPath: items
                                      .firstWhere((item) => item.team == team)
                                      .teamLogo,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    team,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContainerTile(BuildContext context, ContainerDto item) {
    final date =
        DateFormatHelper.formatReleaseDate(item.releaseDate) ??
        item.releaseDate ??
        '-';

    return DetailSourceTile(
      imagePath: item.containerImage,
      title: item.name,
      subtitle: item.typeLabel,
      trailing: date,
      onTap: () {
        AppNavigationHelper.pushScreen(
          context,
          AppNavigationHelper.buildContainerOpenScreen(
            containerDto: item,
            repository: repository,
          ),
        );
      },
    );
  }

  String? _stageDateText(TournamentMetadataDto? metadata, String phase) {
    if (metadata == null) {
      return null;
    }

    for (final stage in metadata.stageDates) {
      if (stage.phase == phase) {
        return DateFormatHelper.formatDateRange(stage.startDate, stage.endDate);
      }
    }

    return null;
  }

  Widget _buildPlayoffBracket(
    BuildContext context,
    List<TournamentPlayoffMatchDto> items,
    TournamentMetadataDto? metadata,
  ) {
    final grouped = <String, List<TournamentPlayoffMatchDto>>{};
    for (final item in items) {
      grouped
          .putIfAbsent(item.round, () => <TournamentPlayoffMatchDto>[])
          .add(item);
    }

    final rounds = grouped.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MajorSectionHeader(
          icon: Icons.account_tree_outlined,
          title: 'Playoff Bracket',
          subtitle: 'Quarterfinals, semifinals, and final results.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final round in rounds)
                Container(
                  width: 260,
                  margin: EdgeInsets.only(right: round == rounds.last ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        round,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...grouped[round]!.map(
                        (match) =>
                            _buildPlayoffMatchCard(context, match, metadata),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayoffMatchCard(
    BuildContext context,
    TournamentPlayoffMatchDto match,
    TournamentMetadataDto? metadata,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayoffTeamRow(
            context,
            match.team1,
            match.team1Logo,
            match.score1,
            metadata,
          ),
          const SizedBox(height: 6),
          _buildPlayoffTeamRow(
            context,
            match.team2,
            match.team2Logo,
            match.score2,
            metadata,
          ),
          if ((match.date ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              match.date!,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayoffTeamRow(
    BuildContext context,
    String team,
    String? logoPath,
    String? score,
    TournamentMetadataDto? metadata,
  ) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _showTournamentTeamSheet(
                context,
                team: team,
                logoPath: logoPath,
                metadata: metadata,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  _TeamLogo(logoPath: logoPath, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      team,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if ((score ?? '').isNotEmpty)
          Text(
            score!,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  void _showTournamentTeamSheet(
    BuildContext context, {
    required String team,
    required String? logoPath,
    required TournamentMetadataDto? metadata,
  }) {
    final canonical = TeamNameHelper.canonicalize(team);
    TournamentTeamRosterDto? roster;

    if (metadata != null) {
      for (final entry in metadata.teamRosters) {
        if (TeamNameHelper.canonicalize(entry.team) == canonical) {
          roster = entry;
          break;
        }
      }
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TeamLogo(
                        logoPath: roster?.teamLogo ?? logoPath,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          team,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const MajorSectionHeader(
                    icon: Icons.groups_2_outlined,
                    title: 'Tournament Roster',
                    subtitle:
                        'Open a player page or jump to the full team history.',
                  ),
                  if (roster != null && roster.players.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final player in roster.players)
                          ActionChip(
                            label: Text(player),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              AppNavigationHelper.pushScreen(
                                context,
                                PlayerDetailsScreen(
                                  playerName: player,
                                  repository: repository,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const Text(
                      'No roster data available for this tournament team.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            AppNavigationHelper.pushScreen(
                              context,
                              TeamDetailsScreen(
                                teamName: team,
                                repository: repository,
                              ),
                            );
                          },
                          child: const Text('Open team page'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _placementPhaseLabel(TournamentDto tournament, String place) {
  final start = _placementStart(place);
  if (start == null) {
    return 'Placements';
  }

  switch (_placementScheme(tournament)) {
    case _PlacementScheme.none:
      return 'Placements';
    case _PlacementScheme.classic:
      if (start <= 8) return 'Champions Stage';
      if (start <= 16) return 'Legends Stage';
      return 'Challengers Stage';
    case _PlacementScheme.cs2Transitional:
      if (start <= 8) return 'Playoff Stage';
      if (start <= 16) return 'Elimination Stage';
      return 'Opening Stage';
    case _PlacementScheme.modern:
      if (start <= 8) return 'Playoffs';
      if (start <= 16) return 'Stage 3';
      if (start <= 24) return 'Stage 2';
      return 'Stage 1';
  }
}

int _placementPhaseOrder(TournamentDto tournament, String phase) {
  switch (_placementScheme(tournament)) {
    case _PlacementScheme.none:
      return 0;
    case _PlacementScheme.classic:
      switch (phase) {
        case 'Champions Stage':
          return 0;
        case 'Legends Stage':
          return 1;
        case 'Challengers Stage':
          return 2;
        default:
          return 3;
      }
    case _PlacementScheme.cs2Transitional:
      switch (phase) {
        case 'Playoff Stage':
          return 0;
        case 'Elimination Stage':
          return 1;
        case 'Opening Stage':
          return 2;
        default:
          return 3;
      }
    case _PlacementScheme.modern:
      switch (phase) {
        case 'Playoffs':
          return 0;
        case 'Stage 3':
          return 1;
        case 'Stage 2':
          return 2;
        case 'Stage 1':
          return 3;
        default:
          return 4;
      }
  }
}

IconData _placementPhaseIcon(String phase) {
  switch (phase) {
    case 'Champions Stage':
    case 'Playoff Stage':
    case 'Playoffs':
      return Icons.emoji_events_outlined;
    case 'Elimination Stage':
    case 'Legends Stage':
    case 'Stage 3':
      return Icons.workspace_premium_outlined;
    case 'Opening Stage':
    case 'Challengers Stage':
    case 'Stage 1':
    case 'Stage 2':
      return Icons.groups_2_outlined;
    default:
      return Icons.style_outlined;
  }
}

_PlacementScheme _placementScheme(TournamentDto tournament) {
  final name = tournament.name;

  if (_preBostonMajors.contains(name)) {
    return _PlacementScheme.none;
  }

  if (_classicStageMajors.contains(name)) {
    return _PlacementScheme.classic;
  }

  if (name == 'PGL Copenhagen 2024' || name == 'Perfect World Shanghai 2024') {
    return _PlacementScheme.cs2Transitional;
  }

  return _PlacementScheme.modern;
}

int? _placementStart(String place) {
  final match = RegExp(
    r'^(\d+)(?:st|nd|rd|th)?(?:-(\d+)(?:st|nd|rd|th)?)?$',
  ).firstMatch(place);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

const _preBostonMajors = <String>{
  'DreamHack Winter 2013',
  'EMS One Katowice 2014',
  'ESL One Cologne 2014',
  'DreamHack Winter 2014',
  'ESL One Katowice 2015',
  'ESL One Cologne 2015',
  'DreamHack Cluj-Napoca 2015',
  'MLG Columbus 2016',
  'ESL One Cologne 2016',
  'ELEAGUE Atlanta 2017',
  'PGL Kraków 2017',
};

const _classicStageMajors = <String>{
  'ELEAGUE Boston 2018',
  'ELEAGUE Major Boston 2018',
  'FACEIT London 2018',
  'IEM Katowice 2019',
  'StarLadder Berlin 2019',
  'PGL Stockholm 2021',
  'PGL Antwerp 2022',
  'IEM Rio 2022',
  'BLAST.tv Paris 2023',
};

enum _PlacementScheme { none, classic, cs2Transitional, modern }

class _TeamLogo extends StatelessWidget {
  final String? logoPath;
  final double size;

  const _TeamLogo({required this.logoPath, required this.size});

  @override
  Widget build(BuildContext context) {
    final value = logoPath ?? '';
    if (value.isEmpty) {
      return Icon(Icons.shield_outlined, size: size, color: Colors.white60);
    }

    if (value.startsWith('assets/')) {
      return AdaptiveLogoImage(
        logoPath: value,
        width: size,
        height: size,
        fit: BoxFit.contain,
        fallback: Icon(
          Icons.shield_outlined,
          size: size,
          color: Colors.white60,
        ),
      );
    }

    return Image.network(
      value,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Icon(Icons.shield_outlined, size: size, color: Colors.white60),
    );
  }
}

class _TournamentDetailsData {
  final TournamentMetadataDto? metadata;
  final List<ContainerDto> souvenirPackages;
  final List<ContainerDto> stickerSources;

  const _TournamentDetailsData({
    this.metadata,
    this.souvenirPackages = const [],
    this.stickerSources = const [],
  });
}

bool _hasMeaningfulPlayoffBracket(TournamentMetadataDto? metadata) {
  final matches =
      metadata?.playoffMatches ?? const <TournamentPlayoffMatchDto>[];
  if (matches.isEmpty) {
    return false;
  }

  final validRounds = {
    'Quarterfinals',
    'Semifinals',
    'Grand Final',
    'Playoff Stage',
    'Playoffs',
  };

  return matches.any((match) => validRounds.contains(match.round));
}
