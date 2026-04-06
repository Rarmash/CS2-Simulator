import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/tournament_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/responsive_collection_grid.dart';
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
            tooltip: 'Teams',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamListScreen(repository: widget.repository),
                ),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TournamentDetailsScreen(
                        repository: widget.repository,
                        tournament: tournament,
                      ),
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
