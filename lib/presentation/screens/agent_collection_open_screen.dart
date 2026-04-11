import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/collection/collection_tracking_service.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/agent_dto.dart';
import '../../data/models/container_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/agent_collection_simulator_service.dart';
import '../../domain/dropped_agent.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/agent_drop_card.dart';
import '../widgets/agent_grid_tile.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/source_badge.dart';

class AgentCollectionOpenScreen extends StatefulWidget {
  final ContainerDto collection;
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
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();
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
    await CollectibleOpenFlowHelper.runReveal<DroppedAgent>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: agents.isNotEmpty,
      random: _random,
      onStart: () {
        _isOpening = true;
        _dropped = null;
      },
      resolveDrop: () => _simulator.openCollection(
        agents: agents,
        collection: widget.collection,
      ),
      onComplete: (drop) {
        _dropped = drop;
        _isOpening = false;
        _collectionTracking.recordAgentDrop(
          drop: drop,
          sourceName: widget.collection.name,
          sourceType: widget.collection.typeLabel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.collection.releaseDate,
    );
    final color = SourceColorHelper.operationColor(
      widget.collection.sourceId ?? '',
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: CollectibleOpenBody<AgentDto>(
        future: _agentsFuture,
        sliverBuilder: (context, constraints, agents, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.collection.containerImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  SourceBadge(
                    label: widget.collection.sourceLabel,
                    color: color,
                  ),
                ],
                releaseDateText: formattedReleaseDate,
                description:
                    'Agent collections open like operation rewards: no roulette, just the final reveal.',
                buttonLabel: _isOpening
                    ? 'OPENING...'
                    : 'OPEN AGENT COLLECTION',
                onPressed: (_isOpening || agents.isEmpty)
                    ? null
                    : () => _openCollection(agents),
              ),
            ),
            if (_isOpening)
              const SliverToBoxAdapter(
                child: OpeningLoadingCard(title: 'Opening agent collection...'),
              ),
            if (_dropped != null)
              SliverToBoxAdapter(child: AgentDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Collection contents'),
            ),
            CollectibleGridSliver<AgentDto>(
              items: agents,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (agent) {
                final isDropped = _dropped?.agent.id == agent.id;
                return AgentGridTile(
                  agent: agent,
                  highlighted: isDropped,
                  crossAxisCount: gridCount,
                );
              },
            ),
          ];
        },
      ),
    );
  }
}
