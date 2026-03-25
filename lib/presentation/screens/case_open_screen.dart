import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/case_simulator_service.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/terminal_offer.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/skin_ui_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/asset_collection_image.dart';
import '../widgets/chip_badge.dart';
import '../widgets/info_row.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/skin_drop_card.dart';
import '../widgets/skin_grid_tile.dart';

class CaseOpenScreen extends StatefulWidget {
  final CaseDto caseDto;
  final LocalDataRepository repository;

  const CaseOpenScreen({
    super.key,
    required this.caseDto,
    required this.repository,
  });

  @override
  State<CaseOpenScreen> createState() => _CaseOpenScreenState();
}

class _RarityBucket {
  final List<SkinDto> skins;
  final double weight;

  const _RarityBucket({
    required this.skins,
    required this.weight,
  });
}

class _CaseOpenScreenState extends State<CaseOpenScreen> {
  late Future<List<SkinDto>> _skinsFuture;
  final CaseSimulatorService _simulator = CaseSimulatorService();
  final Random _random = Random();

  final ScrollController _rollController = ScrollController();

  DroppedSkin? _dropped;
  bool _isRolling = false;

  List<SkinDto> _rollSequence = const [];
  int _winningIndex = 0;

  List<TerminalOffer> _terminalOffers = const [];
  int _terminalOfferIndex = 0;
  TerminalOffer? _acceptedTerminalOffer;
  bool _terminalStarted = false;
  bool _isTerminalLoading = false;

  static const double _rollItemGap = 10;
  static const double _rollViewportPadding = 12;

  bool get _isRegularCase => widget.caseDto.isRegularCase;
  bool get _isSouvenirPackage => widget.caseDto.isSouvenirPackage;
  bool get _isCollectionPackage => widget.caseDto.isCollectionPackage;
  bool get _isXrayPackage => widget.caseDto.isXrayPackage;
  bool get _isTerminal => widget.caseDto.isTerminal;

  bool get _supportsAnimatedOpening =>
      _isRegularCase || _isSouvenirPackage || _isCollectionPackage;

  bool get _hasActiveTerminalOffer =>
      _isTerminal &&
          _terminalStarted &&
          !_isTerminalLoading &&
          _acceptedTerminalOffer == null &&
          _terminalOfferIndex < _terminalOffers.length;

  TerminalOffer? get _currentTerminalOffer {
    if (!_hasActiveTerminalOffer) return null;
    return _terminalOffers[_terminalOfferIndex];
  }

  bool get _isTerminalFinishedWithoutAccept =>
      _isTerminal &&
          _terminalStarted &&
          !_isTerminalLoading &&
          _acceptedTerminalOffer == null &&
          _terminalOfferIndex >= _terminalOffers.length;

  @override
  void initState() {
    super.initState();
    _skinsFuture = widget.repository.loadSkinsForCase(widget.caseDto.id);
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  void _resetTerminalState() {
    _terminalOffers = const [];
    _terminalOfferIndex = 0;
    _acceptedTerminalOffer = null;
    _terminalStarted = false;
    _isTerminalLoading = false;
  }

  Future<void> _openCase(List<SkinDto> skins) async {
    if (_isRolling || skins.isEmpty || _isTerminalLoading) return;

    if (_isTerminal) {
      await _startTerminal(skins);
      return;
    }

    final drop = _simulator.openCase(
      skins: skins,
      caseDto: widget.caseDto,
    );

    if (_isXrayPackage) {
      setState(() {
        _dropped = drop;
        _rollSequence = const [];
        _isRolling = false;
        _resetTerminalState();
      });
      return;
    }

    final rollData = _buildRollSequence(skins, drop);

    setState(() {
      _isRolling = true;
      _dropped = null;
      _rollSequence = rollData.items;
      _winningIndex = rollData.winnerIndex;
      _resetTerminalState();
    });

    await Future.delayed(const Duration(milliseconds: 50));
    if (!_rollController.hasClients) return;

    _rollController.jumpTo(0);

    final viewportWidth = _rollController.position.viewportDimension;
    final itemWidth = _rollItemWidth(viewportWidth);

    final targetOffset = _computeTargetOffset(
      winningIndex: _winningIndex,
      viewportWidth: viewportWidth,
      itemWidth: itemWidth,
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
      _isRolling = false;
    });
  }

  Future<void> _startTerminal(List<SkinDto> skins) async {
    final offers = _simulator.buildTerminalOffers(skins: skins);

    setState(() {
      _terminalOffers = offers;
      _terminalOfferIndex = 0;
      _acceptedTerminalOffer = null;
      _terminalStarted = true;
      _dropped = null;
      _rollSequence = const [];
      _isRolling = false;
      _isTerminalLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    setState(() {
      _isTerminalLoading = false;
    });
  }

  Future<void> _acceptTerminalOffer() async {
    if (_isTerminalLoading) return;

    final offer = _currentTerminalOffer;
    if (offer == null) return;

    setState(() {
      _acceptedTerminalOffer = offer;
      _dropped = DroppedSkin(
        skin: offer.skin,
        isStatTrak: offer.isStatTrak,
        isSouvenir: false,
        skinFloat: offer.skinFloat,
        exterior: offer.exterior,
      );
    });
  }

  Future<void> _skipTerminalOffer() async {
    if (!_hasActiveTerminalOffer) return;

    setState(() {
      _isTerminalLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1100));

    if (!mounted) return;

    setState(() {
      _terminalOfferIndex += 1;
      _isTerminalLoading = false;
    });
  }

  double _rollItemWidth(double viewportWidth) {
    final raw = viewportWidth * 0.18;
    return raw.clamp(120.0, 170.0);
  }

  double _computeTargetOffset({
    required int winningIndex,
    required double viewportWidth,
    required double itemWidth,
  }) {
    final itemExtent = itemWidth + _rollItemGap;
    final itemLeft = _rollViewportPadding + winningIndex * itemExtent;
    final itemCenter = itemLeft + itemWidth / 2;
    final target = itemCenter - viewportWidth / 2;

    return target.clamp(0.0, _rollController.position.maxScrollExtent);
  }

  _RollSequenceData _buildRollSequence(List<SkinDto> allSkins, DroppedSkin drop) {
    if (_isSouvenirPackage || _isCollectionPackage) {
      return _buildPackageRollSequence(allSkins, drop);
    }

    return _buildCaseRollSequence(allSkins, drop);
  }

  _RollSequenceData _buildCaseRollSequence(List<SkinDto> allSkins, DroppedSkin drop) {
    final flyoverPool = allSkins.where((s) => !s.isSpecialItem).toList();

    final milSpec = flyoverPool.where((s) => s.rarity == 'MIL_SPEC').toList();
    final restricted = flyoverPool.where((s) => s.rarity == 'RESTRICTED').toList();
    final classified = flyoverPool.where((s) => s.rarity == 'CLASSIFIED').toList();
    final covert = flyoverPool
        .where((s) => s.rarity == 'COVERT' || s.rarity == 'CONTRABAND')
        .toList();

    SkinDto pickRandom(List<SkinDto> list) {
      return list[_random.nextInt(list.length)];
    }

    SkinDto pickByRealCaseOdds() {
      final availableBuckets = <_RarityBucket>[];

      if (milSpec.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: milSpec, weight: 0.7992327));
      }
      if (restricted.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: restricted, weight: 0.1598465));
      }
      if (classified.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: classified, weight: 0.0319693));
      }
      if (covert.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: covert, weight: 0.0063939));
      }

      if (availableBuckets.isEmpty) {
        throw Exception('No flyover skins available');
      }

      final totalWeight =
      availableBuckets.fold<double>(0, (sum, bucket) => sum + bucket.weight);

      final roll = _random.nextDouble() * totalWeight;
      double cumulative = 0;

      for (final bucket in availableBuckets) {
        cumulative += bucket.weight;
        if (roll <= cumulative) {
          return pickRandom(bucket.skins);
        }
      }

      return pickRandom(availableBuckets.last.skins);
    }

    SkinDto pickNearWinner() {
      final availableBuckets = <_RarityBucket>[];

      if (milSpec.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: milSpec, weight: 0.55));
      }
      if (restricted.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: restricted, weight: 0.28));
      }
      if (classified.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: classified, weight: 0.12));
      }
      if (covert.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: covert, weight: 0.05));
      }

      final totalWeight =
      availableBuckets.fold<double>(0, (sum, bucket) => sum + bucket.weight);

      final roll = _random.nextDouble() * totalWeight;
      double cumulative = 0;

      for (final bucket in availableBuckets) {
        cumulative += bucket.weight;
        if (roll <= cumulative) {
          return pickRandom(bucket.skins);
        }
      }

      return pickRandom(availableBuckets.last.skins);
    }

    final sequence = <SkinDto>[];

    for (int i = 0; i < 28; i++) {
      sequence.add(pickByRealCaseOdds());
    }

    sequence.add(pickNearWinner());
    sequence.add(pickByRealCaseOdds());
    sequence.add(pickByRealCaseOdds());

    final winnerIndex = sequence.length;
    sequence.add(drop.skin);

    for (int i = 0; i < 8; i++) {
      sequence.add(pickByRealCaseOdds());
    }

    return _RollSequenceData(
      items: sequence,
      winnerIndex: winnerIndex,
    );
  }

  _RollSequenceData _buildPackageRollSequence(List<SkinDto> allSkins, DroppedSkin drop) {
    final flyoverPool = allSkins.where((s) => !s.isSpecialItem).toList();

    final consumer = flyoverPool.where((s) => s.rarity == 'CONSUMER').toList();
    final industrial = flyoverPool.where((s) => s.rarity == 'INDUSTRIAL').toList();
    final milSpec = flyoverPool.where((s) => s.rarity == 'MIL_SPEC').toList();
    final restricted = flyoverPool.where((s) => s.rarity == 'RESTRICTED').toList();
    final classified = flyoverPool.where((s) => s.rarity == 'CLASSIFIED').toList();
    final covert = flyoverPool
        .where((s) => s.rarity == 'COVERT' || s.rarity == 'CONTRABAND')
        .toList();

    SkinDto pickRandom(List<SkinDto> list) {
      return list[_random.nextInt(list.length)];
    }

    SkinDto pickByRealPackageOdds() {
      final availableBuckets = <_RarityBucket>[];

      if (consumer.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: consumer, weight: 0.80));
      }
      if (industrial.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: industrial, weight: 0.16));
      }
      if (milSpec.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: milSpec, weight: 0.032));
      }
      if (restricted.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: restricted, weight: 0.0064));
      }
      if (classified.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: classified, weight: 0.00128));
      }
      if (covert.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: covert, weight: 0.000256));
      }

      if (availableBuckets.isEmpty) {
        throw Exception('No package flyover skins available');
      }

      final totalWeight =
      availableBuckets.fold<double>(0, (sum, bucket) => sum + bucket.weight);

      final roll = _random.nextDouble() * totalWeight;
      double cumulative = 0;

      for (final bucket in availableBuckets) {
        cumulative += bucket.weight;
        if (roll <= cumulative) {
          return pickRandom(bucket.skins);
        }
      }

      return pickRandom(availableBuckets.last.skins);
    }

    SkinDto pickNearWinner() {
      final availableBuckets = <_RarityBucket>[];

      if (consumer.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: consumer, weight: 0.58));
      }
      if (industrial.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: industrial, weight: 0.24));
      }
      if (milSpec.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: milSpec, weight: 0.11));
      }
      if (restricted.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: restricted, weight: 0.05));
      }
      if (classified.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: classified, weight: 0.015));
      }
      if (covert.isNotEmpty) {
        availableBuckets.add(_RarityBucket(skins: covert, weight: 0.005));
      }

      final totalWeight =
      availableBuckets.fold<double>(0, (sum, bucket) => sum + bucket.weight);

      final roll = _random.nextDouble() * totalWeight;
      double cumulative = 0;

      for (final bucket in availableBuckets) {
        cumulative += bucket.weight;
        if (roll <= cumulative) {
          return pickRandom(bucket.skins);
        }
      }

      return pickRandom(availableBuckets.last.skins);
    }

    final sequence = <SkinDto>[];

    for (int i = 0; i < 28; i++) {
      sequence.add(pickByRealPackageOdds());
    }

    sequence.add(pickNearWinner());
    sequence.add(pickByRealPackageOdds());
    sequence.add(pickByRealPackageOdds());

    final winnerIndex = sequence.length;
    sequence.add(drop.skin);

    for (int i = 0; i < 8; i++) {
      sequence.add(pickByRealPackageOdds());
    }

    return _RollSequenceData(
      items: sequence,
      winnerIndex: winnerIndex,
    );
  }

  Widget _buildRollItem(
      SkinDto skin, {
        required bool isWinner,
        required double itemWidth,
      }) {
    final rarityColor = SkinUiHelper.rarityColor(skin);

    return Container(
      width: itemWidth,
      margin: const EdgeInsets.only(right: _rollItemGap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWinner ? Colors.white : rarityColor.withOpacity(0.55),
            width: isWinner ? 2.6 : 1.4,
          ),
          boxShadow: isWinner
              ? [
            BoxShadow(
              color: rarityColor.withOpacity(0.5),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: Card(
          margin: EdgeInsets.zero,
          color: rarityColor.withOpacity(isWinner ? 0.18 : 0.08),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Image.asset(
                    skin.skinImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              Container(
                height: 4,
                color: rarityColor,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skin.itemDisplayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      SkinUiHelper.secondaryText(skin),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoller() {
    if (_rollSequence.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final itemWidth = _rollItemWidth(viewportWidth);
        final rollerHeight = viewportWidth < 600 ? 190.0 : 228.0;
        final lineHeight = viewportWidth < 600 ? 160.0 : 200.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(
            height: rollerHeight,
            child: Stack(
              children: [
                ListView.builder(
                  controller: _rollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: _rollViewportPadding),
                  itemCount: _rollSequence.length,
                  itemBuilder: (_, index) {
                    final skin = _rollSequence[index];
                    final isWinner = !_isRolling && index == _winningIndex;

                    return _buildRollItem(
                      skin,
                      isWinner: isWinner,
                      itemWidth: itemWidth,
                    );
                  },
                ),
                Positioned(
                  left: viewportWidth / 2 - 2,
                  top: (rollerHeight - lineHeight) / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: 4,
                      height: lineHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white38,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _openButtonLabel() {
    if (_isRolling) {
      if (_isSouvenirPackage || _isCollectionPackage) {
        return 'OPENING PACKAGE...';
      }
      if (_isXrayPackage) {
        return 'REVEALING...';
      }
      return 'OPENING...';
    }

    if (_isTerminal) return _terminalStarted ? 'RESTART TERMINAL' : 'OPEN TERMINAL';
    if (_isXrayPackage) return 'REVEAL ITEM';
    if (_isSouvenirPackage || _isCollectionPackage) return 'OPEN PACKAGE';
    return 'OPEN CASE';
  }

  Widget? _buildInfoNote(List<SkinDto> skins) {
    if (_isXrayPackage && skins.length == 1) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'This package contains exactly one item.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      );
    }

    if (_isCollectionPackage) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Collection packages open without special items.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      );
    }

    if (_isTerminal) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Terminal opening is offer-based: open for free, then hold to take or skip up to five offers.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildContainerTypeBadge() {
    final color = SourceColorHelper.containerTypeColor(widget.caseDto.type);

    return ChipBadge(
      label: widget.caseDto.typeLabel,
      color: color,
    );
  }

  Widget _buildTerminalOfferCard(TerminalOffer offer) {
    final rarityColor = SkinUiHelper.rarityColor(offer.skin);

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: rarityColor, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Offer ${offer.offerIndex} / ${_terminalOffers.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Image.asset(
              offer.skin.skinImage,
              height: 140,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_not_supported, size: 72),
            ),
            const SizedBox(height: 12),
            Text(
              '${offer.isStatTrak ? 'StatTrak™ ' : ''}${offer.skin.itemDisplayName} | ${offer.skin.name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: rarityColor,
              ),
            ),
            if (offer.skin.displayVariant != null) ...[
              const SizedBox(height: 6),
              Text(
                offer.skin.displayVariant!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 10),
            InfoRow(
              title: 'Rarity',
              value: SkinUiHelper.rarityLabel(offer.skin),
              valueColor: rarityColor,
            ),
            InfoRow(
              title: 'Weapon type',
              value: SkinUiHelper.weaponTypeLabel(offer.skin.weaponType),
            ),
            InfoRow(
              title: 'Item',
              value: offer.skin.itemDisplayName,
            ),
            InfoRow(
              title: 'StatTrak',
              value: offer.isStatTrak ? 'Yes' : 'No',
            ),
            InfoRow(
              title: 'Float',
              value: offer.skinFloat?.toStringAsFixed(6) ?? '-',
            ),
            InfoRow(
              title: 'Exterior',
              value: offer.exterior ?? '-',
            ),
            if (offer.skin.collection != null && offer.skin.collection!.isNotEmpty)
              InfoRow(
                title: 'Collection',
                value: offer.skin.collection!,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: HoldToConfirmButton(
                    label: 'SKIP OFFER',
                    duration: const Duration(milliseconds: 950),
                    onCompleted: _skipTerminalOffer,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HoldToConfirmButton(
                    label: 'TAKE OFFER',
                    duration: const Duration(milliseconds: 950),
                    onCompleted: _acceptTerminalOffer,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate =
    DateFormatHelper.formatReleaseDate(widget.caseDto.releaseDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseDto.name),
      ),
      body: FutureBuilder<List<SkinDto>>(
        future: _skinsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final skins = snapshot.data!;
          final infoNote = _buildInfoNote(skins);

          return LayoutBuilder(
            builder: (context, constraints) {
              final gridCount =
              ResponsiveGridHelper.skinGridCrossAxisCount(
                constraints.maxWidth,
              );
              final aspectRatio =
              ResponsiveGridHelper.skinGridChildAspectRatio(
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
                          _buildContainerTypeBadge(),
                          const SizedBox(height: 8),
                          if (formattedReleaseDate != null)
                            Text(
                              'Released: $formattedReleaseDate',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          if (infoNote != null) infoNote,
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isRolling || skins.isEmpty || _isTerminalLoading)
                                  ? null
                                  : () => _openCase(skins),
                              child: Text(_openButtonLabel()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_supportsAnimatedOpening && _rollSequence.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildRoller(),
                    ),
                  if (_isTerminalLoading)
                    const SliverToBoxAdapter(
                      child: OpeningLoadingCard(
                        title: 'Loading terminal offer...',
                      ),
                    ),
                  if (_hasActiveTerminalOffer)
                    SliverToBoxAdapter(
                      child: _buildTerminalOfferCard(_currentTerminalOffer!),
                    ),
                  if (_isTerminalFinishedWithoutAccept)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No offers were accepted. This terminal session is finished.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_dropped != null)
                    SliverToBoxAdapter(
                      child: SkinDropCard(drop: _dropped!),
                    ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Case contents',
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
                      delegate: SliverChildBuilderDelegate(
                            (_, index) {
                          final skin = skins[index];
                          final isDropped = _dropped?.skin.id == skin.id;

                          return SkinGridTile(
                            skin: skin,
                            highlighted: isDropped,
                            crossAxisCount: gridCount,
                          );
                        },
                        childCount: skins.length,
                      ),
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

class _RollSequenceData {
  final List<SkinDto> items;
  final int winnerIndex;

  const _RollSequenceData({
    required this.items,
    required this.winnerIndex,
  });
}

class HoldToConfirmButton extends StatefulWidget {
  final String label;
  final Duration duration;
  final FutureOr<void> Function() onCompleted;
  final bool isPrimary;

  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.duration,
    required this.onCompleted,
    required this.isPrimary,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _triggered = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) async {
      if (status == AnimationStatus.completed && !_triggered && !_busy) {
        _triggered = true;
        _busy = true;
        try {
          await widget.onCompleted();
        } finally {
          if (mounted) {
            _controller.reset();
            _triggered = false;
            _busy = false;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_busy) return;
    _triggered = false;
    _controller.forward(from: 0);
  }

  void _cancelHold() {
    if (_busy) return;
    if (_controller.isAnimating || _controller.value > 0) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.isPrimary
        ? ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
    )
        : OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
    );

    final child = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _controller.value,
                    child: Container(
                      color: widget.isPrimary
                          ? Colors.white.withOpacity(0.18)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_busy) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(_busy ? 'PROCESSING...' : widget.label),
              ],
            ),
          ],
        );
      },
    );

    final button = widget.isPrimary
        ? ElevatedButton(
      onPressed: _busy ? null : () {},
      style: baseStyle,
      child: child,
    )
        : OutlinedButton(
      onPressed: _busy ? null : () {},
      style: baseStyle,
      child: child,
    );

    return Listener(
      onPointerDown: (_) => _startHold(),
      onPointerUp: (_) => _cancelHold(),
      onPointerCancel: (_) => _cancelHold(),
      child: button,
    );
  }
}