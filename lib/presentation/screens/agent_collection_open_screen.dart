import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/agent_collection_dto.dart';
import '../../data/models/agent_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/agent_collection_simulator_service.dart';
import '../../domain/dropped_agent.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/agent_drop_card.dart';
import '../widgets/agent_grid_tile.dart';
import '../widgets/asset_collection_image.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/source_badge.dart';

class AgentCollectionOpenScreen extends StatefulWidget {
  final AgentCollectionDto collection;
  final LocalDataRepository repository;

  const AgentCollectionOpenScreen({
    super.key,
    required this.collection,
    required this.repository,
  });

  @override
  State<AgentCollectionOpenScreen> createState() =>
      _AgentCollectionOpenScreenState();
}

class _AgentCollectionOpenScreenState extends State<AgentCollectionOpenScreen> {
  late Future<List<AgentDto>> _agentsFuture;
  final AgentCollectionSimulatorService _simulator =
      AgentCollectionSimulatorService();
  final Random _random = Random();

  DroppedAgent? _dropped;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _agentsFuture = widget.repository.loadAgentsForCollection(
      widget.collection.id,
    );
  }

  Future<void> _openCollection(List<AgentDto> agents) async {
    if (_isOpening || agents.isEmpty) return;

    setState(() {
      _isOpening = true;
      _dropped = null;
    });

    await Future.delayed(Duration(milliseconds: 1200 + _random.nextInt(800)));
    final drop = _simulator.openCollection(
      agents: agents,
      collection: widget.collection,
    );

    if (!mounted) return;
    setState(() {
      _dropped = drop;
      _isOpening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.collection.releaseDate,
    );
    final color = SourceColorHelper.operationColor(widget.collection.operationId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: FutureBuilder<List<AgentDto>>(
        future: _agentsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final agents = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final gridCount = ResponsiveGridHelper.skinGridCrossAxisCount(
                constraints.maxWidth,
              );
              final aspectRatio = ResponsiveGridHelper.skinGridChildAspectRatio(
                constraints.maxWidth,
              );

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          AssetCollectionImage(
                            assetPath: widget.collection.image,
                            height: constraints.maxWidth < 700 ? 90 : 120,
                          ),
                          const SizedBox(height: 10),
                          SourceBadge(
                            label: widget.collection.operationName,
                            color: color,
                          ),
                          if (formattedReleaseDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Released: $formattedReleaseDate',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'Agent collections open like operation rewards: no roulette, just the final reveal.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isOpening || agents.isEmpty)
                                  ? null
                                  : () => _openCollection(agents),
                              child: Text(_isOpening ? 'OPENING...' : 'OPEN AGENT COLLECTION'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isOpening)
                    const SliverToBoxAdapter(
                      child: OpeningLoadingCard(title: 'Opening agent collection...'),
                    ),
                  if (_dropped != null)
                    SliverToBoxAdapter(child: AgentDropCard(drop: _dropped!)),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Collection contents',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((_, index) {
                        final agent = agents[index];
                        final isDropped = _dropped?.agent.id == agent.id;
                        return AgentGridTile(
                          agent: agent,
                          highlighted: isDropped,
                          crossAxisCount: gridCount,
                        );
                      }, childCount: agents.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: aspectRatio,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
