import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/reward_collection_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/reward_collection_simulator_service.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/skin_drop_card.dart';
import '../widgets/skin_grid_tile.dart';
import '../widgets/source_badge.dart';

class RewardCollectionOpenScreen extends StatefulWidget {
  final RewardCollectionDto collection;
  final LocalDataRepository repository;

  const RewardCollectionOpenScreen({
    super.key,
    required this.collection,
    required this.repository,
  });

  @override
  State<RewardCollectionOpenScreen> createState() =>
      _RewardCollectionOpenScreenState();
}

class _RewardCollectionOpenScreenState
    extends State<RewardCollectionOpenScreen> {
  late Future<List<SkinDto>> _skinsFuture;
  final RewardCollectionSimulatorService _simulator =
      RewardCollectionSimulatorService();
  final Random _random = Random();

  DroppedSkin? _dropped;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _skinsFuture = widget.repository.loadSkinsForRewardCollection(
      widget.collection.id,
    );
  }

  Color get _sourceColor => SourceColorHelper.rewardSourceColor(
    isArmory: widget.collection.isArmory,
  );

  Future<void> _openReward(List<SkinDto> skins) async {
    await CollectibleOpenFlowHelper.runReveal<DroppedSkin>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: skins.isNotEmpty,
      random: _random,
      onStart: () {
        _isOpening = true;
        _dropped = null;
      },
      resolveDrop: () => _simulator.openRewardCollection(
        skins: skins,
        collection: widget.collection,
      ),
      onComplete: (drop) {
        _dropped = drop;
        _isOpening = false;
      },
    );
  }

  String _openButtonLabel() {
    if (_isOpening) {
      return 'OPENING...';
    }
    return widget.collection.actionLabel.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.collection.releaseDate,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: CollectibleOpenBody<SkinDto>(
        future: _skinsFuture,
        sliverBuilder: (context, constraints, skins, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.collection.image,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  SourceBadge(
                    label: widget.collection.isArmory
                        ? 'Armory Reward'
                        : 'Operation Reward',
                    color: _sourceColor,
                  ),
                ],
                metadata: [
                  const SizedBox(height: 8),
                  Text(
                    widget.collection.sourceLabel,
                    style: TextStyle(
                      color: _sourceColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cost: ${widget.collection.cost} ${widget.collection.currencyLabel}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                releaseDateText: formattedReleaseDate,
                description:
                    'This mode simulates collection rewards. No StatTrak, no knives, no gloves.',
                buttonLabel: _openButtonLabel(),
                onPressed: (_isOpening || skins.isEmpty)
                    ? null
                    : () => _openReward(skins),
              ),
            ),
            if (_isOpening)
              SliverToBoxAdapter(
                child: OpeningLoadingCard(
                  title: widget.collection.isArmory
                      ? 'Opening armory reward...'
                      : 'Opening operation reward...',
                ),
              ),
            if (_dropped != null)
              SliverToBoxAdapter(child: SkinDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Collection contents'),
            ),
            CollectibleGridSliver<SkinDto>(
              items: skins,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (skin) {
                final isDropped = _dropped?.skin.id == skin.id;
                return SkinGridTile(
                  skin: skin,
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
