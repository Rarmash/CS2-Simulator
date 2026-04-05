import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/charm_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/charm_collection_simulator_service.dart';
import '../../domain/dropped_charm.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/charm_drop_card.dart';
import '../widgets/charm_grid_tile.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/opening_loading_card.dart';

class CharmCollectionOpenScreen extends StatefulWidget {
  final ContainerDto collection;
  final LocalDataRepository repository;

  const CharmCollectionOpenScreen({
    super.key,
    required this.collection,
    required this.repository,
  });

  @override
  State<CharmCollectionOpenScreen> createState() =>
      _CharmCollectionOpenScreenState();
}

class _CharmCollectionOpenScreenState extends State<CharmCollectionOpenScreen> {
  late Future<List<CharmDto>> _charmsFuture;
  final CharmCollectionSimulatorService _simulator =
      CharmCollectionSimulatorService();
  final Random _random = Random();

  DroppedCharm? _dropped;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _charmsFuture = widget.repository.loadCharmsForContainer(
      widget.collection.id,
    );
  }

  Future<void> _openCollection(List<CharmDto> charms) async {
    await CollectibleOpenFlowHelper.runReveal<DroppedCharm>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: charms.isNotEmpty,
      random: _random,
      onStart: () {
        _isOpening = true;
        _dropped = null;
      },
      resolveDrop: () => _simulator.openCollection(charms: charms),
      onComplete: (drop) {
        _dropped = drop;
        _isOpening = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.collection.releaseDate,
    );
    final typeColor = SourceColorHelper.containerTypeColor(
      widget.collection.type,
    );
    final sourceColor = SourceColorHelper.collectibleSourceColor(
      widget.collection.sourceType,
      widget.collection.sourceId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: CollectibleOpenBody<CharmDto>(
        future: _charmsFuture,
        sliverBuilder: (context, constraints, charms, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.collection.containerImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  ChipBadge(
                    label: widget.collection.typeLabel,
                    color: typeColor,
                  ),
                  if (widget.collection.sourceTypeLabel != null)
                    ChipBadge(
                      label: widget.collection.sourceTypeLabel!,
                      color: sourceColor,
                    ),
                ],
                metadata: [
                  if ((widget.collection.sourceName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.collection.sourceName!,
                      style: TextStyle(
                        color: sourceColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
                releaseDateText: formattedReleaseDate,
                description:
                    'Charm collections open like Armory rewards: no roulette, just the final reveal.',
                buttonLabel: _isOpening
                    ? 'OPENING...'
                    : 'OPEN CHARM COLLECTION',
                onPressed: (_isOpening || charms.isEmpty)
                    ? null
                    : () => _openCollection(charms),
              ),
            ),
            if (_isOpening)
              const SliverToBoxAdapter(
                child: OpeningLoadingCard(title: 'Opening charm collection...'),
              ),
            if (_dropped != null)
              SliverToBoxAdapter(child: CharmDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Collection contents'),
            ),
            CollectibleGridSliver<CharmDto>(
              items: charms,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (charm) {
                final isDropped = _dropped?.charm.id == charm.id;
                return CharmGridTile(
                  charm: charm,
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
