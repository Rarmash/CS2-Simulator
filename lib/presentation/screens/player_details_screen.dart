import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/tournament_dto.dart';
import '../../data/models/tournament_player_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../widgets/adaptive_logo_image.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/major_summary_card.dart';
import 'team_details_screen.dart';
import 'tournament_details_screen.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final String playerName;
  final LocalDataRepository repository;

  const PlayerDetailsScreen({
    super.key,
    required this.playerName,
    required this.repository,
  });

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  late Future<List<TournamentPlayerAppearanceDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadPlayerTournamentAppearances(
      widget.playerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playerName)),
      body: AsyncCollectionLoader<TournamentPlayerAppearanceDto>(
        future: _future,
        builder: (context, items) {
          final latest = items.isNotEmpty ? items.first : null;
          final autographCount = items.fold<int>(
            0,
            (sum, item) => sum + item.autographCount,
          );
          final titleCount = items.where((item) => item.place == '1st').length;
          final teams = items
              .map((item) => item.teamName)
              .where((entry) => (entry ?? '').isNotEmpty)
              .cast<String>()
              .toSet();
          String? bestPlace;
          for (final item in items) {
            if ((item.place ?? '').isEmpty) {
              continue;
            }
            if (bestPlace == null ||
                _comparePlaces(item.place!, bestPlace) < 0) {
              bestPlace = item.place;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              MajorSummaryCard(
                leading: _PlayerStickerBadge(
                  imagePath: latest?.sampleStickerImage,
                  size: 92,
                ),
                title: widget.playerName,
                subtitle: teams.isEmpty ? null : 'Teams: ${teams.join(', ')}',
                tags: [
                  _PlayerStatChip(
                    label: '${items.length} Major appearances',
                    color: Colors.blueAccent,
                  ),
                  _PlayerStatChip(
                    label: '$autographCount autographs',
                    color: Colors.amber,
                  ),
                  if (bestPlace != null)
                    _PlayerStatChip(
                      label: 'Best: $bestPlace',
                      color: Colors.greenAccent,
                    ),
                  if (titleCount > 0)
                    _PlayerStatChip(
                      label: '$titleCount titles',
                      color: Colors.pinkAccent,
                    ),
                ],
                infoRows: [
                  if ((latest?.tournamentName ?? '').isNotEmpty)
                    DetailInfoRow(
                      title: 'Latest Major',
                      value: latest!.tournamentName,
                    ),
                  if ((latest?.latestDateText ?? '').isNotEmpty)
                    DetailInfoRow(
                      title: 'Latest Dates',
                      value: latest!.latestDateText!,
                    ),
                  if ((latest?.teamName ?? '').isNotEmpty)
                    DetailInfoRow(
                      title: 'Latest Team',
                      value:
                          '${latest!.teamName}${(latest.place ?? '').isNotEmpty ? ' - ${latest.place}' : ''}',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const MajorSectionHeader(
                icon: Icons.timeline_outlined,
                title: 'Major Timeline',
                subtitle:
                    'Tournament results, teams, autograph variants, and career context.',
              ),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlayerTournamentCard(
                    item: item,
                    onOpenTeam: (item.teamName ?? '').isEmpty
                        ? null
                        : () {
                            AppNavigationHelper.pushScreen(
                              context,
                              TeamDetailsScreen(
                                teamName: item.teamName!,
                                repository: widget.repository,
                              ),
                            );
                          },
                    onTap: () async {
                      final tournaments = await widget.repository
                          .loadTournaments();
                      TournamentDto? tournament;
                      for (final entry in tournaments) {
                        if (entry.name == item.tournamentName) {
                          tournament = entry;
                          break;
                        }
                      }
                      if (tournament == null || !context.mounted) return;
                      AppNavigationHelper.pushScreen(
                        context,
                        TournamentDetailsScreen(
                          repository: widget.repository,
                          tournament: tournament,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerTournamentCard extends StatelessWidget {
  final TournamentPlayerAppearanceDto item;
  final VoidCallback onTap;
  final VoidCallback? onOpenTeam;

  const _PlayerTournamentCard({
    required this.item,
    required this.onTap,
    required this.onOpenTeam,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
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
                  logoPath: item.tournamentImagePath,
                  width: 92,
                  height: 56,
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
                      item.tournamentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((item.latestDateText ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.latestDateText!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((item.place ?? '').isNotEmpty)
                          _PlayerStatChip(
                            label: item.place!,
                            color: Colors.greenAccent,
                          ),
                        if ((item.teamName ?? '').isNotEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: onOpenTeam,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PlayerTeamLogo(
                                    logoPath: item.teamLogo,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.teamName!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _PlayerStatChip(
                          label: '${item.autographCount} variants',
                          color: Colors.orangeAccent,
                        ),
                        for (final effect in item.effects)
                          _PlayerStatChip(label: effect, color: Colors.white70),
                      ],
                    ),
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

class _PlayerTeamLogo extends StatelessWidget {
  final String? logoPath;
  final double size;

  const _PlayerTeamLogo({required this.logoPath, required this.size});

  @override
  Widget build(BuildContext context) {
    final value = logoPath ?? '';
    if (value.isEmpty) {
      return Icon(Icons.groups_2_outlined, size: size, color: Colors.white60);
    }
    if (value.startsWith('assets/')) {
      return AdaptiveLogoImage(
        logoPath: value,
        width: size,
        height: size,
        fallback: Icon(
          Icons.groups_2_outlined,
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
          Icon(Icons.groups_2_outlined, size: size, color: Colors.white60),
    );
  }
}

class _PlayerStatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PlayerStatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlayerStickerBadge extends StatelessWidget {
  final String? imagePath;
  final double size;

  const _PlayerStickerBadge({required this.imagePath, required this.size});

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
        child: Image.asset(
          imagePath ?? '',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.draw_outlined, size: 36),
        ),
      ),
    );
  }
}

extension on TournamentPlayerAppearanceDto {
  String? get latestDateText =>
      DateFormatHelper.formatDateRange(startDate, endDate) ??
      DateFormatHelper.formatReleaseDate(startDate);
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
