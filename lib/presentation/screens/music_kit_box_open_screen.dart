import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/music_kit_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_music_kit.dart';
import '../../domain/music_kit_simulator_service.dart';
import '../helpers/music_kit_ui_helper.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/asset_collection_image.dart';
import '../widgets/chip_badge.dart';
import '../widgets/music_kit_drop_card.dart';
import '../widgets/music_kit_grid_tile.dart';
import '../widgets/opening_roll_item_card.dart';
import '../widgets/opening_roller.dart';

class MusicKitBoxOpenScreen extends StatefulWidget {
  final CaseDto caseDto;
  final LocalDataRepository repository;

  const MusicKitBoxOpenScreen({
    super.key,
    required this.caseDto,
    required this.repository,
  });

  @override
  State<MusicKitBoxOpenScreen> createState() => _MusicKitBoxOpenScreenState();
}

class _MusicKitBoxOpenScreenState extends State<MusicKitBoxOpenScreen> {
  late Future<List<MusicKitDto>> _musicKitsFuture;
  final MusicKitSimulatorService _simulator = MusicKitSimulatorService();
  final Random _random = Random();
  final ScrollController _rollController = ScrollController();

  DroppedMusicKit? _dropped;
  bool _isOpening = false;
  List<MusicKitDto> _rollSequence = const [];
  int _winningIndex = 0;

  @override
  void initState() {
    super.initState();
    _musicKitsFuture = widget.repository.loadMusicKitsForCase(
      widget.caseDto.id,
    );
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

  Future<void> _openContainer(List<MusicKitDto> musicKits) async {
    if (_isOpening || musicKits.isEmpty) return;

    final drop = _simulator.openContainer(musicKits: musicKits);
    final rollData = _buildRollSequence(musicKits, drop);

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

  OpeningRollSequenceData<MusicKitDto> _buildRollSequence(
    List<MusicKitDto> allMusicKits,
    DroppedMusicKit drop,
  ) {
    return OpeningRollSequenceBuilder.build<MusicKitDto>(
      random: _random,
      winner: drop.musicKit,
      realOddsBuckets: [WeightedRollBucket(items: allMusicKits, weight: 1)],
      nearWinnerBuckets: [WeightedRollBucket(items: allMusicKits, weight: 1)],
    );
  }

  Widget _buildRollItem(
    MusicKitDto musicKit, {
    required bool isWinner,
    required double itemWidth,
  }) {
    final rarityColor = MusicKitUiHelper.rarityColor(musicKit);

    return OpeningRollItemCard(
      itemWidth: itemWidth,
      isWinner: isWinner,
      accentColor: rarityColor,
      imagePath: musicKit.musicKitImage,
      title: musicKit.displayName,
      subtitle: MusicKitUiHelper.secondaryText(musicKit),
    );
  }

  Widget _buildRoller() {
    if (_rollSequence.isEmpty) return const SizedBox.shrink();

    return OpeningRoller<MusicKitDto>(
      controller: _rollController,
      items: _rollSequence,
      winningIndex: _winningIndex,
      isRolling: _isOpening,
      itemBuilder: (musicKit, isWinner, itemWidth) =>
          _buildRollItem(musicKit, isWinner: isWinner, itemWidth: itemWidth),
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
      body: FutureBuilder<List<MusicKitDto>>(
        future: _musicKitsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final musicKits = snapshot.data!;

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
                            'Music Kit Boxes roll music kits only. StatTrak variants are supported through their dedicated boxes.',
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
                              onPressed: (_isOpening || musicKits.isEmpty)
                                  ? null
                                  : () => _openContainer(musicKits),
                              child: Text(
                                _isOpening
                                    ? 'OPENING...'
                                    : 'OPEN MUSIC KIT BOX',
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
                    SliverToBoxAdapter(
                      child: MusicKitDropCard(drop: _dropped!),
                    ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Music kit contents',
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
                        final musicKit = musicKits[index];
                        final isDropped = _dropped?.musicKit.id == musicKit.id;

                        return MusicKitGridTile(
                          musicKit: musicKit,
                          highlighted: isDropped,
                          crossAxisCount: gridCount,
                        );
                      }, childCount: musicKits.length),
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
