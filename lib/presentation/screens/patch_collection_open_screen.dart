import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/patch_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_patch.dart';
import '../../domain/patch_simulator_service.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/patch_drop_card.dart';
import '../widgets/patch_grid_tile.dart';

class PatchCollectionOpenScreen extends StatefulWidget {
  final CaseDto collection;
  final LocalDataRepository repository;

  const PatchCollectionOpenScreen({
    super.key,
    required this.collection,
    required this.repository,
  });

  @override
  State<PatchCollectionOpenScreen> createState() =>
      _PatchCollectionOpenScreenState();
}

class _PatchCollectionOpenScreenState extends State<PatchCollectionOpenScreen> {
  late Future<List<PatchDto>> _patchesFuture;
  final PatchSimulatorService _simulator = PatchSimulatorService();
  final Random _random = Random();

  DroppedPatch? _dropped;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _patchesFuture = widget.repository.loadPatchesForCase(widget.collection.id);
  }

  Future<void> _openCollection(List<PatchDto> patches) async {
    await CollectibleOpenFlowHelper.runReveal<DroppedPatch>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: patches.isNotEmpty,
      random: _random,
      onStart: () {
        _isOpening = true;
        _dropped = null;
      },
      resolveDrop: () => _simulator.openContainer(patches: patches),
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
    final typeColor = SourceColorHelper.containerTypeColor(widget.collection.type);
    final sourceColor = SourceColorHelper.collectibleSourceColor(
      widget.collection.sourceType,
      widget.collection.sourceId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: CollectibleOpenBody<PatchDto>(
        future: _patchesFuture,
        sliverBuilder: (context, constraints, patches, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.collection.caseImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  ChipBadge(label: widget.collection.typeLabel, color: typeColor),
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
                    'Patch collections open like reward collections: no roulette, just the final reveal.',
                buttonLabel:
                    _isOpening ? 'OPENING...' : 'OPEN PATCH COLLECTION',
                onPressed: (_isOpening || patches.isEmpty)
                    ? null
                    : () => _openCollection(patches),
              ),
            ),
            if (_isOpening)
              const SliverToBoxAdapter(
                child: OpeningLoadingCard(title: 'Opening patch collection...'),
              ),
            if (_dropped != null)
              SliverToBoxAdapter(child: PatchDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Collection contents'),
            ),
            CollectibleGridSliver<PatchDto>(
              items: patches,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (patch) {
                final isDropped = _dropped?.patch.id == patch.id;
                return PatchGridTile(
                  patch: patch,
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
