import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/tournament_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../widgets/adaptive_logo_image.dart';
import '../widgets/async_collection_loader.dart';
import 'team_details_screen.dart';

class TeamListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const TeamListScreen({super.key, required this.repository});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  late Future<List<TournamentTeamSummaryDto>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadTournamentTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Major Teams')),
      body: AsyncCollectionLoader<TournamentTeamSummaryDto>(
        future: _future,
        builder: (context, items) {
          final filtered = items.where((item) {
            final query = _query.trim().toLowerCase();
            if (query.isEmpty) return true;
            return item.teamName.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search teams',
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No teams found.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final team = filtered[index];
                          return _TeamSummaryCard(
                            team: team,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeamDetailsScreen(
                                    teamName: team.teamName,
                                    repository: widget.repository,
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

class _TeamSummaryCard extends StatelessWidget {
  final TournamentTeamSummaryDto team;
  final VoidCallback onTap;

  const _TeamSummaryCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latestDate = DateFormatHelper.formatReleaseDate(team.latestStartDate);

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
              _TeamLogoBadge(logoUrl: team.teamLogo, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.teamName,
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
                        _StatChip(
                          label: '${team.tournamentCount} Majors',
                          color: Colors.blueAccent,
                        ),
                        if ((team.bestPlace ?? '').isNotEmpty)
                          _StatChip(
                            label: 'Best: ${team.bestPlace}',
                            color: Colors.amber,
                          ),
                        if (team.titleCount > 0)
                          _StatChip(
                            label: '${team.titleCount} titles',
                            color: Colors.greenAccent,
                          ),
                      ],
                    ),
                    if ((team.latestTournamentName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Latest Major: ${team.latestTournamentName}',
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

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

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
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(4),
          child: _buildLogo(),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final value = logoUrl ?? '';
    if (value.isEmpty) {
      return const Icon(Icons.groups_2_outlined, size: 28);
    }
    if (value.startsWith('assets/')) {
      return AdaptiveLogoImage(
        logoPath: value,
        fit: BoxFit.contain,
        fallback: const Icon(Icons.groups_2_outlined, size: 28),
      );
    }
    return Image.network(
      value,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.groups_2_outlined, size: 28),
    );
  }
}
