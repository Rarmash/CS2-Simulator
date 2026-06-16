import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/tournament_player_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../widgets/async_collection_loader.dart';
import 'player_details_screen.dart';
import 'team_list_screen.dart';
import 'tournament_list_screen.dart';

class PlayerListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const PlayerListScreen({super.key, required this.repository});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  late Future<List<TournamentPlayerSummaryDto>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadTournamentPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Major Players'),
        actions: [
          IconButton(
            tooltip: 'Majors',
            onPressed: () {
              AppNavigationHelper.pushScreen(
                context,
                TournamentListScreen(repository: widget.repository),
              );
            },
            icon: const Icon(Icons.emoji_events_outlined),
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
      body: AsyncCollectionLoader<TournamentPlayerSummaryDto>(
        future: _future,
        builder: (context, items) {
          final filtered = items.where((item) {
            final query = _query.trim().toLowerCase();
            if (query.isEmpty) return true;
            return item.playerName.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              _PlayerListHeader(
                playerCount: items.length,
                onOpenMajors: () {
                  AppNavigationHelper.pushScreen(
                    context,
                    TournamentListScreen(repository: widget.repository),
                  );
                },
                onOpenTeams: () {
                  AppNavigationHelper.pushScreen(
                    context,
                    TeamListScreen(repository: widget.repository),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search players',
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No players found.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final player = filtered[index];
                          return _PlayerSummaryCard(
                            player: player,
                            onTap: () {
                              AppNavigationHelper.pushScreen(
                                context,
                                PlayerDetailsScreen(
                                  playerName: player.playerName,
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
}

class _PlayerListHeader extends StatelessWidget {
  final int playerCount;
  final VoidCallback onOpenMajors;
  final VoidCallback onOpenTeams;

  const _PlayerListHeader({
    required this.playerCount,
    required this.onOpenMajors,
    required this.onOpenTeams,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Major Player History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '$playerCount players with Major appearances, autograph coverage, and tournament timelines.',
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpenMajors,
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: const Text('Majors'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenTeams,
                    icon: const Icon(Icons.groups_2_outlined),
                    label: const Text('Teams'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerSummaryCard extends StatelessWidget {
  final TournamentPlayerSummaryDto player;
  final VoidCallback onTap;

  const _PlayerSummaryCard({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latestDate = DateFormatHelper.formatReleaseDate(
      player.latestStartDate,
    );

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
            children: [
              _PlayerStickerBadge(
                imagePath: player.sampleStickerImage,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.playerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PlayerStatChip(
                          label: '${player.tournamentCount} Majors',
                          color: Colors.blueAccent,
                        ),
                        _PlayerStatChip(
                          label: '${player.autographCount} autographs',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    if ((player.latestTournamentName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Latest Major: ${player.latestTournamentName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (latestDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Latest appearance: $latestDate',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
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
      child: Padding(padding: const EdgeInsets.all(8), child: _buildImage()),
    );
  }

  Widget _buildImage() {
    final value = imagePath ?? '';
    if (value.isEmpty) {
      return const Icon(Icons.draw_outlined, size: 28);
    }
    return Image.asset(
      value,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.draw_outlined, size: 28),
    );
  }
}
