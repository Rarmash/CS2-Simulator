import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/patch_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_patch.dart';
import '../../domain/patch_simulator_service.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/patch_ui_helper.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/collectible_roller_sliver.dart';
import '../widgets/opening_roll_item_card.dart';
import '../widgets/patch_drop_card.dart';
import '../widgets/patch_grid_tile.dart';

class PatchContainerOpenScreen extends StatefulWidget {
  final CaseDto caseDto;
  final LocalDataRepository repository;

  const PatchContainerOpenScreen({
    super.key,
    required this.caseDto,
    required this.repository,
  });

  @override
  State<PatchContainerOpenScreen> createState() => _PatchContainerOpenScreenState();
}

class _PatchContainerOpenScreenState extends State<PatchContainerOpenScreen> {
  late Future<List<PatchDto>> _patchesFuture;
  final PatchSimulatorService _simulator = PatchSimulatorService();
  final Random _random = Random();
  final ScrollController _rollController = ScrollController();

  DroppedPatch? _dropped;
  bool _isOpening = false;
  List<PatchDto> _rollSequence = const [];
  int _winningIndex = 0;

  @override
  void initState() {
    super.initState();
    _patchesFuture = widget.repository.loadPatchesForCase(widget.caseDto.id);
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _openContainer(List<PatchDto> patches) async {
    final drop = _simulator.openContainer(patches: patches);
    final rollData = _buildRollSequence(patches, drop);
    await CollectibleOpenFlowHelper.runRoulette<PatchDto, DroppedPatch>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: patches.isNotEmpty,
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
      },
    );
  }

  OpeningRollSequenceData<PatchDto> _buildRollSequence(
    List<PatchDto> allPatches,
    DroppedPatch drop,
  ) {
    final high = allPatches.where((p) => p.rarity == 'HIGH_GRADE').toList();
    final remarkable = allPatches.where((p) => p.rarity == 'REMARKABLE').toList();
    final exotic = allPatches.where((p) => p.rarity == 'EXOTIC').toList();

    return OpeningRollSequenceBuilder.build<PatchDto>(
      random: _random,
      winner: drop.patch,
      realOddsBuckets: [
        if (high.isNotEmpty) WeightedRollBucket(items: high, weight: 0.7992327),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.1598465),
        if (exotic.isNotEmpty) WeightedRollBucket(items: exotic, weight: 0.0409208),
      ],
      nearWinnerBuckets: [
        if (high.isNotEmpty) WeightedRollBucket(items: high, weight: 0.60),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.28),
        if (exotic.isNotEmpty) WeightedRollBucket(items: exotic, weight: 0.12),
      ],
    );
  }

  Widget _buildRollItem(
    PatchDto patch, {
    required bool isWinner,
    required double itemWidth,
  }) {
    final rarityColor = PatchUiHelper.rarityColor(patch);
    return OpeningRollItemCard(
      itemWidth: itemWidth,
      isWinner: isWinner,
      accentColor: rarityColor,
      imagePath: patch.patchImage,
      title: patch.name,
      subtitle: PatchUiHelper.secondaryText(patch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.caseDto.releaseDate,
    );
    final color = SourceColorHelper.containerTypeColor(widget.caseDto.type);

    return Scaffold(
      appBar: AppBar(title: Text(widget.caseDto.name)),
      body: FutureBuilder<List<PatchDto>>(
        future: _patchesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final patches = snapshot.data!;

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
                    child: CollectibleOpenHeader(
                      assetPath: widget.caseDto.caseImage,
                      imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                      badges: [
                        ChipBadge(label: widget.caseDto.typeLabel, color: color),
                      ],
                      releaseDateText: formattedReleaseDate,
                      description:
                          'Patch packs use roulette opening and are not affected by X-Ray mode.',
                      buttonLabel:
                          _isOpening ? 'OPENING...' : 'OPEN PATCH PACK',
                      onPressed: (_isOpening || patches.isEmpty)
                          ? null
                          : () => _openContainer(patches),
                    ),
                  ),
                  CollectibleRollerSliver<PatchDto>(
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
                    SliverToBoxAdapter(child: PatchDropCard(drop: _dropped!)),
                  const SliverToBoxAdapter(
                    child: CollectibleContentsTitle(title: 'Patch contents'),
                  ),
                  CollectibleGridSliver<PatchDto>(
                    items: patches,
                    crossAxisCount: gridCount,
                    childAspectRatio: aspectRatio,
                    itemBuilder: (item) {
                      final isDropped = _dropped?.patch.id == item.id;
                      return PatchGridTile(
                        patch: item,
                        highlighted: isDropped,
                        crossAxisCount: gridCount,
                      );
                    },
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
