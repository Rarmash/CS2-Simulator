import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/collection/collection_tracking_service.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/sticker_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_sticker.dart';
import '../../domain/sticker_simulator_service.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/source_color_helper.dart';
import '../helpers/sticker_ui_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/collectible_roller_sliver.dart';
import '../widgets/opening_roll_item_card.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/sticker_drop_card.dart';
import '../widgets/sticker_grid_tile.dart';

class StickerContainerOpenScreen extends StatefulWidget {
  final ContainerDto containerDto;
  final LocalDataRepository repository;

  const StickerContainerOpenScreen({
    super.key,
    required this.containerDto,
    required this.repository,
  });

  @override
  State<StickerContainerOpenScreen> createState() =>
      _StickerContainerOpenScreenState();
}

class _StickerContainerOpenScreenState
    extends State<StickerContainerOpenScreen> {
  late Future<List<StickerDto>> _stickersFuture;
  final StickerSimulatorService _simulator = StickerSimulatorService();
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();
  final Random _random = Random();
  final ScrollController _rollController = ScrollController();

  DroppedSticker? _dropped;
  bool _isOpening = false;
  List<StickerDto> _rollSequence = const [];
  int _winningIndex = 0;

  @override
  void initState() {
    super.initState();
    _stickersFuture = widget.repository.loadStickersForContainer(
      widget.containerDto.id,
    );
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _openContainer(List<StickerDto> stickers) async {
    final drop = _simulator.openContainer(stickers: stickers);

    if (widget.containerDto.isStickerCapsule) {
      final rollData = _buildRollSequence(stickers, drop);
      await CollectibleOpenFlowHelper.runRoulette<StickerDto, DroppedSticker>(
        setState: setState,
        isMounted: () => mounted,
        isOpening: _isOpening,
        hasItems: stickers.isNotEmpty,
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
          _collectionTracking.recordStickerDrop(
            drop: drop,
            sourceName: widget.containerDto.name,
            sourceType: widget.containerDto.typeLabel,
          );
        },
      );
      return;
    }

    await CollectibleOpenFlowHelper.runReveal<DroppedSticker>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: stickers.isNotEmpty,
      random: _random,
      baseDelayMs: 1100,
      randomDelayMs: 700,
      onStart: () {
        _isOpening = true;
        _dropped = null;
        _rollSequence = const [];
      },
      resolveDrop: () => drop,
      onComplete: (drop) {
        _dropped = drop;
        _isOpening = false;
        _collectionTracking.recordStickerDrop(
          drop: drop,
          sourceName: widget.containerDto.name,
          sourceType: widget.containerDto.typeLabel,
        );
      },
    );
  }

  String _openButtonLabel() {
    if (_isOpening) {
      return 'OPENING...';
    }
    if (widget.containerDto.isStickerCollection) {
      return 'OPEN STICKER COLLECTION';
    }
    return 'OPEN STICKER CAPSULE';
  }

  String _loadingTitle() {
    if (widget.containerDto.isStickerCollection) {
      return 'Opening sticker collection...';
    }
    return 'Opening sticker capsule...';
  }

  OpeningRollSequenceData<StickerDto> _buildRollSequence(
    List<StickerDto> allStickers,
    DroppedSticker drop,
  ) {
    final highGrade = allStickers
        .where((s) => s.rarity == 'HIGH_GRADE')
        .toList();
    final remarkable = allStickers
        .where((s) => s.rarity == 'REMARKABLE')
        .toList();
    final exotic = allStickers.where((s) => s.rarity == 'EXOTIC').toList();
    final extraordinary = allStickers
        .where((s) => s.rarity == 'EXTRAORDINARY')
        .toList();
    final contraband = allStickers
        .where((s) => s.rarity == 'CONTRABAND')
        .toList();

    return OpeningRollSequenceBuilder.build<StickerDto>(
      random: _random,
      winner: drop.sticker,
      realOddsBuckets: [
        if (highGrade.isNotEmpty)
          WeightedRollBucket(items: highGrade, weight: 0.7992327),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.1598465),
        if (exotic.isNotEmpty)
          WeightedRollBucket(items: exotic, weight: 0.0319693),
        if (extraordinary.isNotEmpty)
          WeightedRollBucket(items: extraordinary, weight: 0.0063939),
        if (contraband.isNotEmpty)
          WeightedRollBucket(items: contraband, weight: 0.0012788),
      ],
      nearWinnerBuckets: [
        if (highGrade.isNotEmpty)
          WeightedRollBucket(items: highGrade, weight: 0.55),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.28),
        if (exotic.isNotEmpty) WeightedRollBucket(items: exotic, weight: 0.12),
        if (extraordinary.isNotEmpty)
          WeightedRollBucket(items: extraordinary, weight: 0.04),
        if (contraband.isNotEmpty)
          WeightedRollBucket(items: contraband, weight: 0.01),
      ],
    );
  }

  Widget _buildRollItem(
    StickerDto sticker, {
    required bool isWinner,
    required double itemWidth,
  }) {
    final rarityColor = StickerUiHelper.rarityColor(sticker);

    return OpeningRollItemCard(
      itemWidth: itemWidth,
      isWinner: isWinner,
      accentColor: rarityColor,
      imagePath: sticker.stickerImage,
      title: sticker.name,
      subtitle: StickerUiHelper.secondaryText(sticker),
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
    final sourceTypeLabel = widget.containerDto.sourceTypeLabel;
    final sourceColor = SourceColorHelper.collectibleSourceColor(
      widget.containerDto.sourceType,
      widget.containerDto.sourceId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.containerDto.name)),
      body: CollectibleOpenBody<StickerDto>(
        future: _stickersFuture,
        sliverBuilder: (context, constraints, stickers, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.containerDto.containerImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  ChipBadge(label: widget.containerDto.typeLabel, color: color),
                  if (widget.containerDto.isStickerCollection &&
                      sourceTypeLabel != null)
                    ChipBadge(label: sourceTypeLabel, color: sourceColor),
                  if (widget.containerDto.isStickerCollection &&
                      (widget.containerDto.sourceName ?? '').isNotEmpty)
                    ChipBadge(
                      label: widget.containerDto.sourceName!,
                      color: sourceColor,
                    ),
                ],
                releaseDateText: formattedReleaseDate,
                description:
                    'Sticker containers roll only sticker rarities. No float, StatTrak, souvenir, knives, or gloves.',
                buttonLabel: _openButtonLabel(),
                onPressed: (_isOpening || stickers.isEmpty)
                    ? null
                    : () => _openContainer(stickers),
              ),
            ),
            if (widget.containerDto.isStickerCapsule)
              CollectibleRollerSliver<StickerDto>(
                controller: _rollController,
                items: _rollSequence,
                winningIndex: _winningIndex,
                isRolling: _isOpening,
                itemBuilder: (sticker, isWinner, itemWidth) => _buildRollItem(
                  sticker,
                  isWinner: isWinner,
                  itemWidth: itemWidth,
                ),
              ),
            if (_isOpening && !widget.containerDto.isStickerCapsule)
              SliverToBoxAdapter(
                child: OpeningLoadingCard(title: _loadingTitle()),
              ),
            if (_dropped != null)
              SliverToBoxAdapter(child: StickerDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Sticker contents'),
            ),
            CollectibleGridSliver<StickerDto>(
              items: stickers,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (sticker) {
                final isDropped = _dropped?.sticker.id == sticker.id;
                return StickerGridTile(
                  sticker: sticker,
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
