import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/tournament_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/responsive_collection_grid.dart';
import 'player_list_screen.dart';
import 'team_list_screen.dart';
import 'tournament_details_screen.dart';

class TournamentListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const TournamentListScreen({super.key, required this.repository});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  late Future<List<TournamentDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadTournaments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Majors'),
        actions: [
          IconButton(
            tooltip: 'Players',
            onPressed: () {
              AppNavigationHelper.pushScreen(
                context,
                PlayerListScreen(repository: widget.repository),
              );
            },
            icon: const Icon(Icons.person_search_outlined),
          ),
          IconButton(
            tooltip: 'Teams',
            onPressed: () {
              AppNavigationHelper.pushScreen(
                context,
                TeamListScreen(repository: widget.repository),
              );
            },
            icon: const Icon(Icons.groups_2_outlined),
          ),
        ],
      ),
      body: AsyncCollectionLoader<TournamentDto>(
        future: _future,
        builder: (context, items) {
          return ResponsiveCollectionGrid<TournamentDto>(
            items: items,
            header: _MajorListHeader(
              tournamentCount: items.length,
              onOpenPlayers: () {
                AppNavigationHelper.pushScreen(
                  context,
                  PlayerListScreen(repository: widget.repository),
                );
              },
              onOpenTeams: () {
                AppNavigationHelper.pushScreen(
                  context,
                  TeamListScreen(repository: widget.repository),
                );
              },
            ),
            emptyMessage: 'No tournaments found.',
            itemBuilder: (context, tournament) {
              final eraColor = tournament.isCs2Era
                  ? Colors.tealAccent.shade400
                  : SourceColorHelper.containerTypeColor('SOUVENIR_PACKAGE');

              return CollectionListCard(
                imagePath: tournament.imagePath,
                title: tournament.name,
                dateLabel: 'Dates',
                releaseDate:
                    DateFormatHelper.formatDateRange(
                      tournament.startDate,
                      tournament.endDate,
                    ) ??
                    tournament.releaseDate,
                chips: [
                  ChipBadge(label: 'Major', color: Colors.amber.shade400),
                  ChipBadge(label: tournament.eraLabel, color: eraColor),
                ],
                metadata: [
                  const SizedBox(height: 8),
                  Text(
                    tournament.organizer,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tournament.souvenirPackageCount} souvenir packages • ${tournament.stickerContainerCount} sticker sources',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                onTap: () {
                  AppNavigationHelper.pushScreen(
                    context,
                    TournamentDetailsScreen(
                      repository: widget.repository,
                      tournament: tournament,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MajorListHeader extends StatelessWidget {
  final int tournamentCount;
  final VoidCallback onOpenPlayers;
  final VoidCallback onOpenTeams;

  const _MajorListHeader({
    required this.tournamentCount,
    required this.onOpenPlayers,
    required this.onOpenTeams,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Major Tournament Archive',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '$tournamentCount events across CS:GO and CS2, with linked teams, players, stickers, autograph capsules, and souvenir sources.',
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenTeams,
                  icon: const Icon(Icons.groups_2_outlined),
                  label: const Text('Major Teams'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenPlayers,
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('Major Players'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
