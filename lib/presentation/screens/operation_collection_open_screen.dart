import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/operation_collection_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/operation_collection_simulator_service.dart';
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

class OperationCollectionOpenScreen extends StatefulWidget {
  final OperationCollectionDto collection;
  final LocalDataRepository repository;

  const OperationCollectionOpenScreen({
    super.key,
    required this.collection,
    required this.repository,
  });

  @override
  State<OperationCollectionOpenScreen> createState() =>
      _OperationCollectionOpenScreenState();
}

class _OperationCollectionOpenScreenState
    extends State<OperationCollectionOpenScreen> {
  late Future<List<SkinDto>> _skinsFuture;
  final OperationCollectionSimulatorService _simulator =
      OperationCollectionSimulatorService();
  final Random _random = Random();

  DroppedSkin? _dropped;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _skinsFuture = widget.repository.loadSkinsForOperationCollection(
      widget.collection.id,
    );
  }

  Color get _operationColor =>
      SourceColorHelper.operationColor(widget.collection.operationId);

  Future<void> _openCollection(List<SkinDto> skins) async {
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
      resolveDrop: () => _simulator.openCollection(
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
    return 'OPEN COLLECTION DROP';
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
                    label: widget.collection.operationName,
                    color: _operationColor,
                  ),
                ],
                releaseDateText: formattedReleaseDate,
                description:
                    'Legacy operation collection opening. No StatTrak, no knives, no gloves.',
                buttonLabel: _openButtonLabel(),
                onPressed: (_isOpening || skins.isEmpty)
                    ? null
                    : () => _openCollection(skins),
              ),
            ),
            if (_isOpening)
              const SliverToBoxAdapter(
                child: OpeningLoadingCard(title: 'Opening collection drop...'),
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
