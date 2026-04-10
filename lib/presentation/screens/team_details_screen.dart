import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../core/utils/team_name_helper.dart';
import '../../data/models/tournament_dto.dart';
import '../../data/models/tournament_metadata_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../widgets/adaptive_logo_image.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_tag.dart';
import '../widgets/major_summary_card.dart';
import 'player_details_screen.dart';
import 'tournament_details_screen.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamName;
  final LocalDataRepository repository;

  const TeamDetailsScreen({
    super.key,
    required this.teamName,
    required this.repository,
  });

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  late Future<_TeamDetailsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_TeamDetailsData> _loadData() async {
    final results = await widget.repository.loadTeamTournamentResults(
      widget.teamName,
    );
    final metadata = await widget.repository.loadTournamentMetadata();
    final metadataByName = {for (final entry in metadata) entry.name: entry};

    return _TeamDetailsData(results: results, metadataByName: metadataByName);
  }

  @override
  Widget build(BuildContext context) {
    final canonicalTeamName = TeamNameHelper.canonicalize(widget.teamName);

    return Scaffold(
      appBar: AppBar(title: Text(canonicalTeamName)),
      body: FutureBuilder<_TeamDetailsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load team details.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null || data.results.isEmpty) {
            return const Center(
              child: Text(
                'No Major results found for this team.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final sorted = List<TournamentTeamResultDto>.from(data.results)
            ..sort((a, b) {
              final byDate = (b.startDate ?? '').compareTo(a.startDate ?? '');
              if (byDate != 0) return byDate;
              return _comparePlaces(a.place, b.place);
            });

          final titles = sorted.where((item) => item.place == '1st').length;
          final bestPlace = sorted.isEmpty
              ? null
              : (sorted.map((item) => item.place).toList()
                      ..sort(_comparePlaces))
                    .first;
          final latest = sorted.isNotEmpty ? sorted.first : null;
          final recurringPlayers = _buildRecurringPlayers(
            data,
            canonicalTeamName,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: MajorSummaryCard(
                  leading: _TeamLogoBadge(logoUrl: latest?.teamLogo, size: 92),
                  title: canonicalTeamName,
                  subtitle: 'Major team history and roster continuity',
                  tags: [
                    DetailTag(text: '${sorted.length} Major appearances'),
                    if (bestPlace != null)
                      DetailTag(
                        text: 'Best: $bestPlace',
                        color: Colors.amber.shade400,
                      ),
                    if (titles > 0)
                      DetailTag(
                        text: '$titles Major titles',
                        color: Colors.greenAccent.shade400,
                      ),
                  ],
                  infoRows: [
                    DetailInfoRow(
                      title: 'Latest Major',
                      value: latest?.tournamentName ?? '-',
                    ),
                    DetailInfoRow(
                      title: 'Latest Dates',
                      value:
                          DateFormatHelper.formatDateRange(
                            latest?.startDate,
                            latest?.endDate,
                          ) ??
                          '-',
                    ),
                  ],
                ),
              ),
              if (recurringPlayers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MajorSectionHeader(
                            icon: Icons.people_alt_outlined,
                            title: 'Recurring Players',
                            subtitle:
                                'Most common Major players for this organization.',
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final entry in recurringPlayers)
                                ActionChip(
                                  label: Text(
                                    '${entry.name} (${entry.appearances})',
                                  ),
                                  onPressed: () {
                                    AppNavigationHelper.pushScreen(
                                      context,
                                      PlayerDetailsScreen(
                                        playerName: entry.name,
                                        repository: widget.repository,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final result = sorted[index];
                    final roster = _findRoster(
                      data.metadataByName[result.tournamentName],
                      canonicalTeamName,
                    );

                    return _TeamTournamentCard(
                      result: result,
                      roster: roster,
                      onOpenTournament: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TournamentDetailsScreen(
                              repository: widget.repository,
                              tournament: TournamentDto(
                                name: result.tournamentName,
                                imagePath: result.tournamentImagePath,
                                releaseDate: result.startDate,
                                startDate: result.startDate,
                                endDate: result.endDate,
                                organizer: result.organizer,
                                souvenirPackageCount: 0,
                                stickerContainerCount: 0,
                              ),
                            ),
                          ),
                        );
                      },
                      onOpenPlayer: (playerName) {
                        AppNavigationHelper.pushScreen(
                          context,
                          PlayerDetailsScreen(
                            playerName: playerName,
                            repository: widget.repository,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TournamentTeamRosterDto? _findRoster(
    TournamentMetadataDto? metadata,
    String canonicalTeamName,
  ) {
    if (metadata == null) {
      return null;
    }

    for (final roster in metadata.teamRosters) {
      if (TeamNameHelper.canonicalize(roster.team) == canonicalTeamName) {
        return roster;
      }
    }

    return null;
  }

  List<_RecurringPlayer> _buildRecurringPlayers(
    _TeamDetailsData data,
    String canonicalTeamName,
  ) {
    final appearances = <String, int>{};
    final displayNames = <String, String>{};

    for (final metadata in data.metadataByName.values) {
      final roster = _findRoster(metadata, canonicalTeamName);
      if (roster == null) {
        continue;
      }
      for (final player in roster.players) {
        final key = player.toLowerCase();
        appearances.update(key, (value) => value + 1, ifAbsent: () => 1);
        displayNames.putIfAbsent(key, () => player);
      }
    }

    final result =
        appearances.entries
            .map(
              (entry) => _RecurringPlayer(
                name: displayNames[entry.key] ?? entry.key,
                appearances: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) {
            final byAppearances = b.appearances.compareTo(a.appearances);
            if (byAppearances != 0) return byAppearances;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

    return result.take(12).toList();
  }
}

class _TeamTournamentCard extends StatelessWidget {
  final TournamentTeamResultDto result;
  final TournamentTeamRosterDto? roster;
  final VoidCallback onOpenTournament;
  final ValueChanged<String> onOpenPlayer;

  const _TeamTournamentCard({
    required this.result,
    required this.roster,
    required this.onOpenTournament,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpenTournament,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AdaptiveLogoImage(
                  logoPath: result.tournamentImagePath,
                  width: 96,
                  height: 60,
                  fit: BoxFit.contain,
                  fallback: const Icon(Icons.emoji_events_outlined, size: 40),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.tournamentName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatHelper.formatDateRange(
                            result.startDate,
                            result.endDate,
                          ) ??
                          '-',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TeamPlaceChip(place: result.place),
                        DetailTag(text: result.organizer),
                      ],
                    ),
                    if (roster != null && roster!.players.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Roster',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final player in roster!.players)
                            ActionChip(
                              label: Text(player),
                              onPressed: () => onOpenPlayer(player),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamPlaceChip extends StatelessWidget {
  final String place;

  const _TeamPlaceChip({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Text(
        place,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TeamLogoBadge extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const _TeamLogoBadge({required this.logoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: _buildLogo(),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final value = logoUrl ?? '';
    if (value.isEmpty) {
      return const Icon(Icons.groups_2, size: 34);
    }
    if (value.startsWith('assets/')) {
      return AdaptiveLogoImage(
        logoPath: value,
        fit: BoxFit.contain,
        fallback: const Icon(Icons.groups_2, size: 34),
      );
    }
    return Image.network(
      value,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.groups_2, size: 34),
    );
  }
}

class _RecurringPlayer {
  final String name;
  final int appearances;

  const _RecurringPlayer({required this.name, required this.appearances});
}

class _TeamDetailsData {
  final List<TournamentTeamResultDto> results;
  final Map<String, TournamentMetadataDto> metadataByName;

  const _TeamDetailsData({required this.results, required this.metadataByName});
}

int _comparePlaces(String a, String b) {
  final rankA = _placeRank(a);
  final rankB = _placeRank(b);
  if (rankA != rankB) {
    return rankA.compareTo(rankB);
  }
  return a.compareTo(b);
}

int _placeRank(String place) {
  final match = RegExp(
    r'^(\d+)(?:st|nd|rd|th)?(?:-(\d+)(?:st|nd|rd|th)?)?$',
  ).firstMatch(place);
  if (match == null) {
    return 1 << 20;
  }
  return int.tryParse(match.group(1) ?? '') ?? (1 << 20);
}
