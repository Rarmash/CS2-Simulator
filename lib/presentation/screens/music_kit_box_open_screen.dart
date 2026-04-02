import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/music_kit_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_music_kit.dart';
import '../../domain/music_kit_simulator_service.dart';
import '../helpers/collectible_open_flow_helper.dart';
import '../helpers/music_kit_ui_helper.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/collectible_roller_sliver.dart';
import '../widgets/music_kit_drop_card.dart';
import '../widgets/music_kit_grid_tile.dart';
import '../widgets/opening_roll_item_card.dart';

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

  Future<void> _openContainer(List<MusicKitDto> musicKits) async {
    final drop = _simulator.openContainer(musicKits: musicKits);
    final rollData = _buildRollSequence(musicKits, drop);
    await CollectibleOpenFlowHelper.runRoulette<MusicKitDto, DroppedMusicKit>(
      setState: setState,
      isMounted: () => mounted,
      isOpening: _isOpening,
      hasItems: musicKits.isNotEmpty,
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

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.caseDto.releaseDate,
    );
    final color = SourceColorHelper.containerTypeColor(widget.caseDto.type);

    return Scaffold(
      appBar: AppBar(title: Text(widget.caseDto.name)),
      body: CollectibleOpenBody<MusicKitDto>(
        future: _musicKitsFuture,
        sliverBuilder: (context, constraints, musicKits, gridCount, aspectRatio) {
          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.caseDto.caseImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  ChipBadge(label: widget.caseDto.typeLabel, color: color),
                ],
                releaseDateText: formattedReleaseDate,
                description:
                    'Music Kit Boxes roll music kits only. StatTrak variants are supported through their dedicated boxes.',
                buttonLabel: _isOpening ? 'OPENING...' : 'OPEN MUSIC KIT BOX',
                onPressed: (_isOpening || musicKits.isEmpty)
                    ? null
                    : () => _openContainer(musicKits),
              ),
            ),
            CollectibleRollerSliver<MusicKitDto>(
              controller: _rollController,
              items: _rollSequence,
              winningIndex: _winningIndex,
              isRolling: _isOpening,
              itemBuilder: (musicKit, isWinner, itemWidth) => _buildRollItem(
                musicKit,
                isWinner: isWinner,
                itemWidth: itemWidth,
              ),
            ),
            if (_dropped != null)
              SliverToBoxAdapter(child: MusicKitDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Music kit contents'),
            ),
            CollectibleGridSliver<MusicKitDto>(
              items: musicKits,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (musicKit) {
                final isDropped = _dropped?.musicKit.id == musicKit.id;
                return MusicKitGridTile(
                  musicKit: musicKit,
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
