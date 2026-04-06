import 'package:flutter/material.dart';

import '../../core/utils/team_name_helper.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/tournament_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_tag.dart';
import '../widgets/responsive_collection_grid.dart';
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
  late Future<List<TournamentTeamResultDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadTeamTournamentResults(widget.teamName);
  }

  @override
  Widget build(BuildContext context) {
    final canonicalTeamName = TeamNameHelper.canonicalize(widget.teamName);

    return Scaffold(
      appBar: AppBar(title: Text(canonicalTeamName)),
      body: AsyncCollectionLoader<TournamentTeamResultDto>(
        future: _future,
        builder: (context, items) {
          final sorted = List<TournamentTeamResultDto>.from(items)
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TeamLogoBadge(logoUrl: latest?.teamLogo, size: 72),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                canonicalTeamName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  DetailTag(
                                    text: '${sorted.length} Major appearances',
                                  ),
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
                              ),
                              const SizedBox(height: 14),
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
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ResponsiveCollectionGrid<TournamentTeamResultDto>(
                  items: sorted,
                  emptyMessage: 'No Major results found for this team.',
                  itemBuilder: (context, result) {
                    return CollectionListCard(
                      imagePath: result.tournamentImagePath,
                      title: result.tournamentName,
                      dateLabel: 'Dates',
                      releaseDate:
                          DateFormatHelper.formatDateRange(
                            result.startDate,
                            result.endDate,
                          ) ??
                          result.startDate,
                      chips: [
                        _TeamPlaceChip(place: result.place),
                        DetailTag(text: result.organizer),
                      ],
                      metadata: const [],
                      onTap: () {
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
      child: Padding(padding: const EdgeInsets.all(10), child: _buildLogo()),
    );
  }

  Widget _buildLogo() {
    final value = logoUrl ?? '';
    if (value.isEmpty) {
      return const Icon(Icons.groups_2, size: 34);
    }
    if (value.startsWith('assets/')) {
      return Image.asset(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.groups_2, size: 34),
      );
    }
    return Image.network(
      value,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.groups_2, size: 34),
    );
  }
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
