import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/collection/collection_tracking_service.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/pin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_pin.dart';
import '../../domain/pin_simulator_service.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/pin_ui_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/collectible_roller_sliver.dart';
import '../widgets/opening_roll_item_card.dart';
import '../widgets/pin_drop_card.dart';
import '../widgets/pin_grid_tile.dart';

class PinContainerOpenScreen extends StatefulWidget {
  final ContainerDto containerDto;
  final LocalDataRepository repository;

  const PinContainerOpenScreen({
    super.key,
    required this.containerDto,
    required this.repository,
  });

  @override
  State<PinContainerOpenScreen> createState() => _PinContainerOpenScreenState();
}

class _PinContainerOpenScreenState extends State<PinContainerOpenScreen> {
  late Future<List<PinDto>> _pinsFuture;
  final PinSimulatorService _simulator = PinSimulatorService();
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();
  final Random _random = Random();
  final ScrollController _rollController = ScrollController();

  DroppedPin? _dropped;
  bool _isOpening = false;
  List<PinDto> _rollSequence = const [];
  int _winningIndex = 0;

  @override
  void initState() {
    super.initState();
    _pinsFuture = widget.repository.loadPinsForContainer(
      widget.containerDto.id,
    );
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _openContainer(List<PinDto> pins) async {
    final drop = _simulator.openContainer(pins: pins);
    final rollData = _buildRollSequence(pins, drop);
    await CollectibleOpenFlowHelper.runRoulette<PinDto, DroppedPin>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: pins.isNotEmpty,
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
        _collectionTracking.recordPinDrop(
          drop: drop,
          sourceName: widget.containerDto.name,
          sourceType: widget.containerDto.typeLabel,
        );
      },
    );
  }

  OpeningRollSequenceData<PinDto> _buildRollSequence(
    List<PinDto> allPins,
    DroppedPin drop,
  ) {
    final highGrade = allPins.where((p) => p.rarity == 'HIGH_GRADE').toList();
    final remarkable = allPins.where((p) => p.rarity == 'REMARKABLE').toList();
    final exotic = allPins.where((p) => p.rarity == 'EXOTIC').toList();
    final extraordinary = allPins
        .where((p) => p.rarity == 'EXTRAORDINARY')
        .toList();

    return OpeningRollSequenceBuilder.build<PinDto>(
      random: _random,
      winner: drop.pin,
      realOddsBuckets: [
        if (highGrade.isNotEmpty)
          WeightedRollBucket(items: highGrade, weight: 0.7992327),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.1598465),
        if (exotic.isNotEmpty)
          WeightedRollBucket(items: exotic, weight: 0.0319693),
        if (extraordinary.isNotEmpty)
          WeightedRollBucket(items: extraordinary, weight: 0.0089515),
      ],
      nearWinnerBuckets: [
        if (highGrade.isNotEmpty)
          WeightedRollBucket(items: highGrade, weight: 0.55),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.28),
        if (exotic.isNotEmpty) WeightedRollBucket(items: exotic, weight: 0.12),
        if (extraordinary.isNotEmpty)
          WeightedRollBucket(items: extraordinary, weight: 0.05),
      ],
    );
  }

  Widget _buildRollItem(
    PinDto pin, {
    required bool isWinner,
    required double itemWidth,
  }) {
    final rarityColor = PinUiHelper.rarityColor(pin);

    return OpeningRollItemCard(
      itemWidth: itemWidth,
      isWinner: isWinner,
      accentColor: rarityColor,
      imagePath: pin.pinImage,
      title: pin.name,
      subtitle: PinUiHelper.secondaryText(pin),
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
      body: CollectibleOpenBody<PinDto>(
        future: _pinsFuture,
        sliverBuilder: (context, constraints, pins, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.containerDto.containerImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  ChipBadge(label: widget.containerDto.typeLabel, color: color),
                ],
                releaseDateText: formattedReleaseDate,
                description: 'Pin capsules roll collectible pins only.',
                buttonLabel: _isOpening ? 'OPENING...' : 'OPEN PIN CAPSULE',
                onPressed: (_isOpening || pins.isEmpty)
                    ? null
                    : () => _openContainer(pins),
              ),
            ),
            CollectibleRollerSliver<PinDto>(
              controller: _rollController,
              items: _rollSequence,
              winningIndex: _winningIndex,
              isRolling: _isOpening,
              itemBuilder: (pin, isWinner, itemWidth) =>
                  _buildRollItem(pin, isWinner: isWinner, itemWidth: itemWidth),
            ),
            if (_dropped != null)
              SliverToBoxAdapter(child: PinDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Pin contents'),
            ),
            CollectibleGridSliver<PinDto>(
              items: pins,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (pin) {
                final isDropped = _dropped?.pin.id == pin.id;
                return PinGridTile(
                  pin: pin,
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
