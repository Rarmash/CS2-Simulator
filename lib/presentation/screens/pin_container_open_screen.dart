import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/pin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_pin.dart';
import '../../domain/pin_simulator_service.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/pin_ui_helper.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/asset_collection_image.dart';
import '../widgets/chip_badge.dart';
import '../widgets/opening_roll_item_card.dart';
import '../widgets/opening_roller.dart';
import '../widgets/pin_drop_card.dart';
import '../widgets/pin_grid_tile.dart';

class PinContainerOpenScreen extends StatefulWidget {
  final CaseDto caseDto;
  final LocalDataRepository repository;

  const PinContainerOpenScreen({
    super.key,
    required this.caseDto,
    required this.repository,
  });

  @override
  State<PinContainerOpenScreen> createState() => _PinContainerOpenScreenState();
}

class _PinContainerOpenScreenState extends State<PinContainerOpenScreen> {
  late Future<List<PinDto>> _pinsFuture;
  final PinSimulatorService _simulator = PinSimulatorService();
  final Random _random = Random();
  final ScrollController _rollController = ScrollController();

  DroppedPin? _dropped;
  bool _isOpening = false;
  List<PinDto> _rollSequence = const [];
  int _winningIndex = 0;

  @override
  void initState() {
    super.initState();
    _pinsFuture = widget.repository.loadPinsForCase(widget.caseDto.id);
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

  Future<void> _openContainer(List<PinDto> pins) async {
    if (_isOpening || pins.isEmpty) return;

    final drop = _simulator.openContainer(pins: pins);
    final rollData = _buildRollSequence(pins, drop);

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

  Widget _buildRoller() {
    if (_rollSequence.isEmpty) return const SizedBox.shrink();

    return OpeningRoller<PinDto>(
      controller: _rollController,
      items: _rollSequence,
      winningIndex: _winningIndex,
      isRolling: _isOpening,
      itemBuilder: (pin, isWinner, itemWidth) =>
          _buildRollItem(pin, isWinner: isWinner, itemWidth: itemWidth),
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
      body: FutureBuilder<List<PinDto>>(
        future: _pinsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pins = snapshot.data!;

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
                          ChipBadge(
                            label: widget.caseDto.typeLabel,
                            color: color,
                          ),
                          if (formattedReleaseDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Released: $formattedReleaseDate',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'Pin capsules roll collectible pins only.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isOpening || pins.isEmpty)
                                  ? null
                                  : () => _openContainer(pins),
                              child: Text(
                                _isOpening ? 'OPENING...' : 'OPEN PIN CAPSULE',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_rollSequence.isNotEmpty)
                    SliverToBoxAdapter(child: _buildRoller()),
                  if (_dropped != null)
                    SliverToBoxAdapter(child: PinDropCard(drop: _dropped!)),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pin contents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((_, index) {
                        final pin = pins[index];
                        final isDropped = _dropped?.pin.id == pin.id;

                        return PinGridTile(
                          pin: pin,
                          highlighted: isDropped,
                          crossAxisCount: gridCount,
                        );
                      }, childCount: pins.length),
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
