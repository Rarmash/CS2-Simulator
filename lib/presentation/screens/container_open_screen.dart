import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/collection/collection_tracking_service.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/container_simulator_service.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/special_item_variant_helper.dart';
import '../helpers/opening_roll_sequence_builder.dart';
import '../helpers/skin_ui_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collectible_contents_title.dart';
import '../widgets/collectible_grid_sliver.dart';
import '../widgets/collectible_open_body.dart';
import '../widgets/collectible_open_header.dart';
import '../widgets/collectible_roller_sliver.dart';
import '../widgets/opening_roll_item_card.dart';
import '../widgets/opening_roller.dart';
import '../widgets/skin_drop_card.dart';
import '../widgets/skin_grid_tile.dart';
import '../widgets/xray_reveal_card.dart';

class ContainerOpenScreen extends StatefulWidget {
  final ContainerDto containerDto;
  final LocalDataRepository repository;
  final SettingsController? settingsController;

  const ContainerOpenScreen({
    super.key,
    required this.containerDto,
    required this.repository,
    required this.settingsController,
  });

  @override
  State<ContainerOpenScreen> createState() => _ContainerOpenScreenState();
}

class _ContainerOpenScreenState extends State<ContainerOpenScreen> {
  late Future<List<SkinDto>> _skinsFuture;
  final ContainerSimulatorService _simulator = ContainerSimulatorService();
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();
  final Random _random = Random();
  final ScrollController _rollController = ScrollController();

  DroppedSkin? _dropped;
  bool _isRolling = false;
  List<SkinDto> _rollSequence = const [];
  int _winningIndex = 0;
  DroppedSkin? _pendingXrayDrop;
  bool _xrayRevealActive = false;

  bool get _isRegularCase => widget.containerDto.isRegularCase;
  bool get _isSouvenirPackage => widget.containerDto.isSouvenirPackage;
  bool get _isCollectionPackage => widget.containerDto.isCollectionPackage;
  bool get _isXrayPackage => widget.containerDto.isXrayPackage;
  bool get _xrayModeEnabled =>
      widget.settingsController?.xrayOpeningEnabled ?? false;

  bool get _shouldUseSettingsXrayMode =>
      _xrayModeEnabled && _isRegularCase && !_isXrayPackage;

  bool get _supportsAnimatedOpening =>
      !_shouldUseSettingsXrayMode &&
      (_isRegularCase || _isSouvenirPackage || _isCollectionPackage);

  @override
  void initState() {
    super.initState();
    _skinsFuture = widget.repository.loadSkinsForContainer(
      widget.containerDto.id,
    );
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  void _resetXrayState() {
    _pendingXrayDrop = null;
    _xrayRevealActive = false;
  }

  Future<void> _openCase(List<SkinDto> skins) async {
    if (_isRolling || skins.isEmpty || _xrayRevealActive) {
      return;
    }

    final drop = _simulator.openCase(
      skins: skins,
      containerDto: widget.containerDto,
    );

    if (_isXrayPackage) {
      setState(() {
        _dropped = drop;
        _rollSequence = const [];
        _isRolling = false;
        _resetXrayState();
      });
      await _collectionTracking.recordSkinDrop(
        drop: drop,
        sourceName: widget.containerDto.name,
        sourceType: widget.containerDto.typeLabel,
      );
      return;
    }

    if (_shouldUseSettingsXrayMode) {
      setState(() {
        _pendingXrayDrop = drop;
        _xrayRevealActive = true;
        _dropped = null;
        _rollSequence = const [];
        _isRolling = false;
      });
      return;
    }

    final rollData = _buildRollSequence(skins, drop);

    setState(() {
      _isRolling = true;
      _dropped = null;
      _rollSequence = rollData.items;
      _winningIndex = rollData.winnerIndex;
      _resetXrayState();
    });

    await Future.delayed(const Duration(milliseconds: 50));
    if (!_rollController.hasClients) {
      return;
    }

    _rollController.jumpTo(0);

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

    if (!mounted) {
      return;
    }

    setState(() {
      _dropped = drop;
      _isRolling = false;
    });
    await _collectionTracking.recordSkinDrop(
      drop: drop,
      sourceName: widget.containerDto.name,
      sourceType: widget.containerDto.typeLabel,
    );
  }

  Future<void> _claimXrayDrop() async {
    if (_pendingXrayDrop == null) {
      return;
    }

    setState(() {
      _dropped = _pendingXrayDrop;
      _pendingXrayDrop = null;
      _xrayRevealActive = false;
    });
    await _collectionTracking.recordSkinDrop(
      drop: _dropped!,
      sourceName: widget.containerDto.name,
      sourceType: widget.containerDto.typeLabel,
    );
  }

  Future<void> _destroyXrayDrop() async {
    setState(() {
      _pendingXrayDrop = null;
      _dropped = null;
      _xrayRevealActive = false;
    });
  }

  OpeningRollSequenceData<SkinDto> _buildRollSequence(
    List<SkinDto> allSkins,
    DroppedSkin drop,
  ) {
    if (_isSouvenirPackage || _isCollectionPackage) {
      return _buildPackageRollSequence(allSkins, drop);
    }

    return _buildCaseRollSequence(allSkins, drop);
  }

  OpeningRollSequenceData<SkinDto> _buildCaseRollSequence(
    List<SkinDto> allSkins,
    DroppedSkin drop,
  ) {
    final flyoverPool = allSkins.where((s) => !s.isSpecialItem).toList();
    final milSpec = flyoverPool.where((s) => s.rarity == 'MIL_SPEC').toList();
    final restricted = flyoverPool
        .where((s) => s.rarity == 'RESTRICTED')
        .toList();
    final classified = flyoverPool
        .where((s) => s.rarity == 'CLASSIFIED')
        .toList();
    final covert = flyoverPool
        .where((s) => s.rarity == 'COVERT' || s.rarity == 'CONTRABAND')
        .toList();

    return OpeningRollSequenceBuilder.build<SkinDto>(
      random: _random,
      winner: drop.skin,
      realOddsBuckets: [
        if (milSpec.isNotEmpty)
          WeightedRollBucket(items: milSpec, weight: 0.7992327),
        if (restricted.isNotEmpty)
          WeightedRollBucket(items: restricted, weight: 0.1598465),
        if (classified.isNotEmpty)
          WeightedRollBucket(items: classified, weight: 0.0319693),
        if (covert.isNotEmpty)
          WeightedRollBucket(items: covert, weight: 0.0063939),
      ],
      nearWinnerBuckets: [
        if (milSpec.isNotEmpty)
          WeightedRollBucket(items: milSpec, weight: 0.55),
        if (restricted.isNotEmpty)
          WeightedRollBucket(items: restricted, weight: 0.28),
        if (classified.isNotEmpty)
          WeightedRollBucket(items: classified, weight: 0.12),
        if (covert.isNotEmpty) WeightedRollBucket(items: covert, weight: 0.05),
      ],
    );
  }

  OpeningRollSequenceData<SkinDto> _buildPackageRollSequence(
    List<SkinDto> allSkins,
    DroppedSkin drop,
  ) {
    final flyoverPool = allSkins.where((s) => !s.isSpecialItem).toList();
    final consumer = flyoverPool.where((s) => s.rarity == 'CONSUMER').toList();
    final industrial = flyoverPool
        .where((s) => s.rarity == 'INDUSTRIAL')
        .toList();
    final milSpec = flyoverPool.where((s) => s.rarity == 'MIL_SPEC').toList();
    final restricted = flyoverPool
        .where((s) => s.rarity == 'RESTRICTED')
        .toList();
    final classified = flyoverPool
        .where((s) => s.rarity == 'CLASSIFIED')
        .toList();
    final covert = flyoverPool
        .where((s) => s.rarity == 'COVERT' || s.rarity == 'CONTRABAND')
        .toList();

    return OpeningRollSequenceBuilder.build<SkinDto>(
      random: _random,
      winner: drop.skin,
      realOddsBuckets: [
        if (consumer.isNotEmpty)
          WeightedRollBucket(items: consumer, weight: 0.80),
        if (industrial.isNotEmpty)
          WeightedRollBucket(items: industrial, weight: 0.16),
        if (milSpec.isNotEmpty)
          WeightedRollBucket(items: milSpec, weight: 0.032),
        if (restricted.isNotEmpty)
          WeightedRollBucket(items: restricted, weight: 0.0064),
        if (classified.isNotEmpty)
          WeightedRollBucket(items: classified, weight: 0.00128),
        if (covert.isNotEmpty)
          WeightedRollBucket(items: covert, weight: 0.000256),
      ],
      nearWinnerBuckets: [
        if (consumer.isNotEmpty)
          WeightedRollBucket(items: consumer, weight: 0.58),
        if (industrial.isNotEmpty)
          WeightedRollBucket(items: industrial, weight: 0.24),
        if (milSpec.isNotEmpty)
          WeightedRollBucket(items: milSpec, weight: 0.11),
        if (restricted.isNotEmpty)
          WeightedRollBucket(items: restricted, weight: 0.05),
        if (classified.isNotEmpty)
          WeightedRollBucket(items: classified, weight: 0.015),
        if (covert.isNotEmpty) WeightedRollBucket(items: covert, weight: 0.005),
      ],
    );
  }

  Widget _buildRollItem(
    SkinDto skin, {
    required bool isWinner,
    required double itemWidth,
  }) {
    final rarityColor = SkinUiHelper.rarityColor(skin);

    return OpeningRollItemCard(
      itemWidth: itemWidth,
      isWinner: isWinner,
      accentColor: rarityColor,
      imagePath: skin.skinImage,
      title: skin.itemDisplayName,
      subtitle: SkinUiHelper.secondaryText(skin),
    );
  }

  String _openButtonLabel() {
    if (_xrayRevealActive) {
      return 'ITEM REVEALED';
    }

    if (_isRolling) {
      if (_isSouvenirPackage || _isCollectionPackage) {
        return 'OPENING PACKAGE...';
      }
      if (_isXrayPackage) {
        return 'REVEALING...';
      }
      return 'OPENING...';
    }

    if (_isXrayPackage) return 'REVEAL ITEM';
    if (_shouldUseSettingsXrayMode) return 'OPEN CASE (X-RAY)';
    if (_isSouvenirPackage || _isCollectionPackage) return 'OPEN PACKAGE';
    return 'OPEN CASE';
  }

  String? _infoNoteText(List<SkinDto> skins) {
    if (_shouldUseSettingsXrayMode) {
      return 'X-Ray mode is enabled for regular cases: the item is revealed first, then you choose whether to claim or destroy it.';
    }

    if (_isXrayPackage && skins.length == 1) {
      return 'This package contains exactly one item.';
    }

    if (_isCollectionPackage) {
      return 'Collection packages open without special items.';
    }

    return null;
  }

  String _headerDescription(List<SkinDto> skins) {
    return _infoNoteText(skins) ??
        (_isSouvenirPackage || _isCollectionPackage
            ? 'Packages use realistic CS-style rarity distribution without knives or gloves.'
            : 'Open the container to simulate a CS-style drop.');
  }

  List<_DisplayedContainerSkin> _displayedContents(List<SkinDto> skins) {
    final families = <String, List<SkinDto>>{};
    for (final skin in skins) {
      final key = SpecialItemVariantHelper.familyKeyForSkin(skin);
      families.putIfAbsent(key, () => <SkinDto>[]).add(skin);
    }

    final displayed = <_DisplayedContainerSkin>[];
    final emitted = <String>{};

    for (final skin in skins) {
      final key = SpecialItemVariantHelper.familyKeyForSkin(skin);
      if (emitted.contains(key)) {
        continue;
      }

      final family = families[key] ?? <SkinDto>[skin];
      final shouldGroup =
          family.length > 1 &&
          SpecialItemVariantHelper.hasConfiguredVariantWeights(family);

      if (!shouldGroup) {
        displayed.add(
          _DisplayedContainerSkin(
            skin: skin,
            family: const [],
            secondaryText: SkinUiHelper.secondaryText(skin),
          ),
        );
        emitted.add(key);
        continue;
      }

      displayed.add(
        _DisplayedContainerSkin(
          skin: family.first,
          family: family,
          secondaryText: SkinUiHelper.familySecondaryText(family),
          detailText: SkinUiHelper.familyDetailText(family),
        ),
      );
      emitted.add(key);
    }

    return displayed;
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.containerDto.releaseDate,
    );
    final typeColor = SourceColorHelper.containerTypeColor(
      widget.containerDto.type,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.containerDto.name)),
      body: CollectibleOpenBody<SkinDto>(
        future: _skinsFuture,
        sliverBuilder: (context, constraints, skins, gridCount, aspectRatio) {
          final displayedContents = _displayedContents(skins);

          return [
            SliverToBoxAdapter(
              child: CollectibleOpenHeader(
                assetPath: widget.containerDto.containerImage,
                imageHeight: constraints.maxWidth < 700 ? 90 : 120,
                badges: [
                  ChipBadge(
                    label: widget.containerDto.typeLabel,
                    color: typeColor,
                  ),
                ],
                releaseDateText: formattedReleaseDate,
                description: _headerDescription(skins),
                buttonLabel: _openButtonLabel(),
                onPressed: (_isRolling || skins.isEmpty || _xrayRevealActive)
                    ? null
                    : () => _openCase(skins),
              ),
            ),
            if (_supportsAnimatedOpening && _rollSequence.isNotEmpty)
              CollectibleRollerSliver<SkinDto>(
                controller: _rollController,
                items: _rollSequence,
                winningIndex: _winningIndex,
                isRolling: _isRolling,
                itemBuilder: (skin, isWinner, itemWidth) => _buildRollItem(
                  skin,
                  isWinner: isWinner,
                  itemWidth: itemWidth,
                ),
              ),
            if (_xrayRevealActive && _pendingXrayDrop != null)
              SliverToBoxAdapter(
                child: XrayRevealCard(
                  drop: _pendingXrayDrop!,
                  onClaim: _claimXrayDrop,
                  onDestroy: _destroyXrayDrop,
                ),
              ),
            if (_dropped != null)
              SliverToBoxAdapter(child: SkinDropCard(drop: _dropped!)),
            const SliverToBoxAdapter(
              child: CollectibleContentsTitle(title: 'Case contents'),
            ),
            CollectibleGridSliver<_DisplayedContainerSkin>(
              items: displayedContents,
              crossAxisCount: gridCount,
              childAspectRatio: aspectRatio,
              itemBuilder: (entry) {
                final droppedId = _dropped?.skin.id;
                final pendingId = _pendingXrayDrop?.skin.id;
                final isDropped =
                    droppedId == entry.skin.id ||
                    pendingId == entry.skin.id ||
                    entry.family.any(
                      (variant) =>
                          variant.id == droppedId || variant.id == pendingId,
                    );

                return SkinGridTile(
                  skin: entry.skin,
                  highlighted: isDropped,
                  crossAxisCount: gridCount,
                  secondaryTextOverride: entry.secondaryText,
                  detailTextOverride: entry.detailText,
                );
              },
            ),
          ];
        },
      ),
    );
  }
}

class _DisplayedContainerSkin {
  final SkinDto skin;
  final List<SkinDto> family;
  final String secondaryText;
  final String? detailText;

  const _DisplayedContainerSkin({
    required this.skin,
    required this.family,
    required this.secondaryText,
    this.detailText,
  });
}
