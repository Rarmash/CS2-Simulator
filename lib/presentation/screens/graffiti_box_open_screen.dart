import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/collection/collection_tracking_service.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/graffiti_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_graffiti.dart';
import '../../domain/graffiti_simulator_service.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/graffiti_ui_helper.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/collectible_roller_sliver.dart';
import '../widgets/graffiti_drop_card.dart';
import '../widgets/graffiti_grid_tile.dart';
import '../widgets/opening_roll_item_card.dart';

class GraffitiBoxOpenScreen extends StatefulWidget {
  final ContainerDto containerDto;
  final LocalDataRepository repository;

  const GraffitiBoxOpenScreen({
    super.key,
    required this.containerDto,
    required this.repository,
  });

  @override
  State<GraffitiBoxOpenScreen> createState() => _GraffitiBoxOpenScreenState();
}

class _GraffitiBoxOpenScreenState extends State<GraffitiBoxOpenScreen> {
  late Future<List<GraffitiDto>> _graffitiFuture;
  final GraffitiSimulatorService _simulator = GraffitiSimulatorService();
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();
  final Random _random = Random();
  final ScrollController _rollController = ScrollController();

  DroppedGraffiti? _dropped;
  bool _isOpening = false;
  List<GraffitiDto> _rollSequence = const [];
  int _winningIndex = 0;

  @override
  void initState() {
    super.initState();
    _graffitiFuture = widget.repository.loadGraffitiForContainer(
      widget.containerDto.id,
    );
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _openContainer(List<GraffitiDto> graffiti) async {
    final drop = _simulator.openContainer(graffiti: graffiti);
    final rollData = _buildRollSequence(graffiti, drop);
    await CollectibleOpenFlowHelper.runRoulette<GraffitiDto, DroppedGraffiti>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: graffiti.isNotEmpty,
      controller: _rollController,
      rollData: rollData,
      drop: drop,
      onStart: (rollData) {
        _isOpening = true;
        _dropped = null;
        _rollSequence = rollData.items;
        _winningIndex = rollData.winnerIndex;
      },
      onComplete: (drop) {
        _dropped = drop;
        _isOpening = false;
        _collectionTracking.recordGraffitiDrop(
          drop: drop,
          sourceName: widget.containerDto.name,
          sourceType: widget.containerDto.typeLabel,
        );
      },
    );
  }

  OpeningRollSequenceData<GraffitiDto> _buildRollSequence(
    List<GraffitiDto> allGraffiti,
    DroppedGraffiti drop,
  ) {
    final base = allGraffiti.where((g) => g.rarity == 'BASE_GRADE').toList();
    final high = allGraffiti.where((g) => g.rarity == 'HIGH_GRADE').toList();
    final remarkable = allGraffiti
        .where((g) => g.rarity == 'REMARKABLE')
        .toList();
    final exotic = allGraffiti.where((g) => g.rarity == 'EXOTIC').toList();

    return OpeningRollSequenceBuilder.build<GraffitiDto>(
      random: _random,
      winner: drop.graffiti,
      realOddsBuckets: [
        if (base.isNotEmpty) WeightedRollBucket(items: base, weight: 0.7992327),
        if (high.isNotEmpty) WeightedRollBucket(items: high, weight: 0.1598465),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.0319693),
        if (exotic.isNotEmpty)
          WeightedRollBucket(items: exotic, weight: 0.0089515),
      ],
      nearWinnerBuckets: [
        if (base.isNotEmpty) WeightedRollBucket(items: base, weight: 0.55),
        if (high.isNotEmpty) WeightedRollBucket(items: high, weight: 0.28),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.12),
        if (exotic.isNotEmpty) WeightedRollBucket(items: exotic, weight: 0.05),
      ],
    );
  }

  Widget _buildRollItem(
    GraffitiDto graffiti, {
    required bool isWinner,
    required double itemWidth,
  }) {
    final rarityColor = GraffitiUiHelper.rarityColor(graffiti);
    return OpeningRollItemCard(
      itemWidth: itemWidth,
      isWinner: isWinner,
      accentColor: rarityColor,
      imagePath: graffiti.graffitiImage,
      title: graffiti.name,
      subtitle: GraffitiUiHelper.secondaryText(graffiti),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.containerDto.releaseDate,
    );
    final color = SourceColorHelper.containerTypeColor(
      widget.containerDto.type,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.containerDto.name)),
      body: CollectibleOpenBody<GraffitiDto>(
        future: _graffitiFuture,
        sliverBuilder: (context, constraints, graffiti, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.containerDto.containerImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  ChipBadge(label: widget.containerDto.typeLabel, color: color),
                ],
                releaseDateText: formattedReleaseDate,
                description:
                    'Graffiti boxes use roulette opening and are not affected by X-Ray mode.',
                buttonLabel: _isOpening ? 'OPENING...' : 'OPEN GRAFFITI BOX',
                onPressed: (_isOpening || graffiti.isEmpty)
                    ? null
                    : () => _openContainer(graffiti),
              ),
            ),
            CollectibleRollerSliver<GraffitiDto>(
              controller: _rollController,
              items: _rollSequence,
              winningIndex: _winningIndex,
              isRolling: _isOpening,
              itemBuilder: (item, isWinner, itemWidth) => _buildRollItem(
                item,
                isWinner: isWinner,
                itemWidth: itemWidth,
              ),
            ),
            if (_dropped != null)
              SliverToBoxAdapter(child: GraffitiDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Graffiti contents'),
            ),
            CollectibleGridSliver<GraffitiDto>(
              items: graffiti,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (item) {
                final isDropped = _dropped?.graffiti.id == item.id;
                return GraffitiGridTile(
                  graffiti: item,
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
