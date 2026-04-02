import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/graffiti_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_graffiti.dart';
import '../../domain/graffiti_simulator_service.dart';
import '../helpers/graffiti_ui_helper.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/asset_collection_image.dart';
import '../widgets/chip_badge.dart';
import '../widgets/graffiti_drop_card.dart';
import '../widgets/graffiti_grid_tile.dart';
import '../widgets/opening_roll_item_card.dart';
import '../widgets/opening_roller.dart';

class GraffitiBoxOpenScreen extends StatefulWidget {
  final CaseDto caseDto;
  final LocalDataRepository repository;

  const GraffitiBoxOpenScreen({
    super.key,
    required this.caseDto,
    required this.repository,
  });

  @override
  State<GraffitiBoxOpenScreen> createState() => _GraffitiBoxOpenScreenState();
}

class _GraffitiBoxOpenScreenState extends State<GraffitiBoxOpenScreen> {
  late Future<List<GraffitiDto>> _graffitiFuture;
  final GraffitiSimulatorService _simulator = GraffitiSimulatorService();
  final Random _random = Random();
  final ScrollController _rollController = ScrollController();

  DroppedGraffiti? _dropped;
  bool _isOpening = false;
  List<GraffitiDto> _rollSequence = const [];
  int _winningIndex = 0;

  @override
  void initState() {
    super.initState();
    _graffitiFuture = widget.repository.loadGraffitiForCase(widget.caseDto.id);
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _waitForRollLayout() async {
    for (int i = 0; i < 6; i++) {
      await SchedulerBinding.instance.endOfFrame;
      if (_rollController.hasClients &&
          _rollController.position.hasContentDimensions &&
          _rollController.position.maxScrollExtent > 0) {
        return;
      }
    }
  }

  Future<void> _openContainer(List<GraffitiDto> graffiti) async {
    if (_isOpening || graffiti.isEmpty) return;
    final drop = _simulator.openContainer(graffiti: graffiti);
    final rollData = _buildRollSequence(graffiti, drop);

    setState(() {
      _isOpening = true;
      _dropped = null;
      _rollSequence = rollData.items;
      _winningIndex = rollData.winnerIndex;
    });

    await _waitForRollLayout();
    if (!_rollController.hasClients) return;
    _rollController.jumpTo(0);
    await _waitForRollLayout();
    if (!_rollController.hasClients) return;

    final viewportWidth = _rollController.position.viewportDimension;
    final itemWidth = OpeningRollLayout.rollItemWidth(viewportWidth);
    final targetOffset = OpeningRollLayout.computeTargetOffset(
      winningIndex: _winningIndex,
      viewportWidth: viewportWidth,
      itemWidth: itemWidth,
      maxScrollExtent: _rollController.position.maxScrollExtent,
    );

    await _rollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 6800),
      curve: Curves.easeOutQuart,
    );

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _dropped = drop;
      _isOpening = false;
    });
  }

  OpeningRollSequenceData<GraffitiDto> _buildRollSequence(
    List<GraffitiDto> allGraffiti,
    DroppedGraffiti drop,
  ) {
    final base = allGraffiti.where((g) => g.rarity == 'BASE_GRADE').toList();
    final high = allGraffiti.where((g) => g.rarity == 'HIGH_GRADE').toList();
    final remarkable = allGraffiti.where((g) => g.rarity == 'REMARKABLE').toList();
    final exotic = allGraffiti.where((g) => g.rarity == 'EXOTIC').toList();

    return OpeningRollSequenceBuilder.build<GraffitiDto>(
      random: _random,
      winner: drop.graffiti,
      realOddsBuckets: [
        if (base.isNotEmpty) WeightedRollBucket(items: base, weight: 0.7992327),
        if (high.isNotEmpty) WeightedRollBucket(items: high, weight: 0.1598465),
        if (remarkable.isNotEmpty)
          WeightedRollBucket(items: remarkable, weight: 0.0319693),
        if (exotic.isNotEmpty) WeightedRollBucket(items: exotic, weight: 0.0089515),
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
      widget.caseDto.releaseDate,
    );
    final color = SourceColorHelper.containerTypeColor(widget.caseDto.type);

    return Scaffold(
      appBar: AppBar(title: Text(widget.caseDto.name)),
      body: FutureBuilder<List<GraffitiDto>>(
        future: _graffitiFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final graffiti = snapshot.data!;

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
                            assetPath: widget.caseDto.caseImage,
                            height: constraints.maxWidth < 700 ? 90 : 120,
                          ),
                          const SizedBox(height: 10),
                          ChipBadge(label: widget.caseDto.typeLabel, color: color),
                          if (formattedReleaseDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Released: $formattedReleaseDate',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'Graffiti boxes use roulette opening and are not affected by X-Ray mode.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isOpening || graffiti.isEmpty)
                                  ? null
                                  : () => _openContainer(graffiti),
                              child: Text(_isOpening ? 'OPENING...' : 'OPEN GRAFFITI BOX'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_rollSequence.isNotEmpty)
                    SliverToBoxAdapter(
                      child: OpeningRoller<GraffitiDto>(
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
                    ),
                  if (_dropped != null)
                    SliverToBoxAdapter(child: GraffitiDropCard(drop: _dropped!)),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Graffiti contents',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((_, index) {
                        final item = graffiti[index];
                        final isDropped = _dropped?.graffiti.id == item.id;
                        return GraffitiGridTile(
                          graffiti: item,
                          highlighted: isDropped,
                          crossAxisCount: gridCount,
                        );
                      }, childCount: graffiti.length),
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
