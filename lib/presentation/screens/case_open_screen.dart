import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/case_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/case_odds.dart';
import '../../domain/case_simulator_service.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/terminal_offer.dart';

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

  Color _rarityColorForSkin(SkinDto skin) {
    if (skin.isSpecialItem) {
      return Colors.amber;
    }

    switch (skin.rarity) {
      case 'MIL_SPEC':
        return Colors.blue;
      case 'RESTRICTED':
        return Colors.purple;
      case 'CLASSIFIED':
        return Colors.pink;
      case 'COVERT':
      case 'CONTRABAND':
        return Colors.red;
      case 'EXTRAORDINARY':
        return Colors.amber;
      case 'INDUSTRIAL':
        return Colors.lightBlueAccent;
      case 'CONSUMER':
        return Colors.grey;
      default:
        return Colors.white24;
    }
  }

  String _rarityLabelForSkin(SkinDto skin) {
    if (skin.isSpecialItem) return 'Special Item';

    switch (skin.rarity) {
      case 'MIL_SPEC':
        return 'Mil-Spec';
      case 'RESTRICTED':
        return 'Restricted';
      case 'CLASSIFIED':
        return 'Classified';
      case 'COVERT':
        return 'Covert';
      case 'CONTRABAND':
        return 'Contraband';
      case 'EXTRAORDINARY':
        return 'Extraordinary';
      case 'INDUSTRIAL':
        return 'Industrial';
      case 'CONSUMER':
        return 'Consumer';
      default:
        return skin.rarity;
    }
  }

  String _weaponTypeLabel(String type) {
    switch (type) {
      case 'PISTOL':
        return 'Pistol';
      case 'SMG':
        return 'SMG';
      case 'SNIPER_RIFLE':
        return 'Sniper Rifle';
      case 'RIFLE':
        return 'Rifle';
      case 'KNIFE':
        return 'Knife';
      case 'SHOTGUN':
        return 'Shotgun';
      case 'MACHINE_GUN':
        return 'Machine Gun';
      case 'GLOVES':
        return 'Gloves';
      case 'EQUIPMENT':
        return 'Equipment';
      default:
        return type;
    }
  }

  String? _formatReleaseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final parts = raw.split('-');
    if (parts.length != 3) return raw;

    const months = {
      '01': 'Jan',
      '02': 'Feb',
      '03': 'Mar',
      '04': 'Apr',
      '05': 'May',
      '06': 'Jun',
      '07': 'Jul',
      '08': 'Aug',
      '09': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec',
    };

    final year = parts[0];
    final month = months[parts[1]] ?? parts[1];
    final day = parts[2];

    return '$day $month $year';
  }

  String _skinSecondaryText(SkinDto skin) {
    final variant = skin.displayVariant;
    if (variant != null && variant.isNotEmpty) {
      return '${skin.name} • $variant';
    }
    return skin.name;
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
        availableBuckets.add(_RarityBucket(
          skins: milSpec,
          weight: 0.7992327,
        ));
      }
      if (restricted.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: restricted,
          weight: 0.1598465,
        ));
      }
      if (classified.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: classified,
          weight: 0.0319693,
        ));
      }
      if (covert.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: covert,
          weight: 0.0063939,
        ));
      }

      if (availableBuckets.isEmpty) {
        throw Exception('No flyover skins available');
      }

      final totalWeight = availableBuckets.fold<double>(
        0,
            (sum, bucket) => sum + bucket.weight,
      );

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
        availableBuckets.add(_RarityBucket(
          skins: milSpec,
          weight: 0.55,
        ));
      }
      if (restricted.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: restricted,
          weight: 0.28,
        ));
      }
      if (classified.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: classified,
          weight: 0.12,
        ));
      }
      if (covert.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: covert,
          weight: 0.05,
        ));
      }

      final totalWeight = availableBuckets.fold<double>(
        0,
            (sum, bucket) => sum + bucket.weight,
      );

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
        availableBuckets.add(_RarityBucket(
          skins: consumer,
          weight: 0.80,
        ));
      }
      if (industrial.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: industrial,
          weight: 0.16,
        ));
      }
      if (milSpec.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: milSpec,
          weight: 0.032,
        ));
      }
      if (restricted.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: restricted,
          weight: 0.0064,
        ));
      }
      if (classified.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: classified,
          weight: 0.00128,
        ));
      }
      if (covert.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: covert,
          weight: 0.000256,
        ));
      }

      if (availableBuckets.isEmpty) {
        throw Exception('No package flyover skins available');
      }

      final totalWeight = availableBuckets.fold<double>(
        0,
            (sum, bucket) => sum + bucket.weight,
      );

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
        availableBuckets.add(_RarityBucket(
          skins: consumer,
          weight: 0.58,
        ));
      }
      if (industrial.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: industrial,
          weight: 0.24,
        ));
      }
      if (milSpec.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: milSpec,
          weight: 0.11,
        ));
      }
      if (restricted.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: restricted,
          weight: 0.05,
        ));
      }
      if (classified.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: classified,
          weight: 0.015,
        ));
      }
      if (covert.isNotEmpty) {
        availableBuckets.add(_RarityBucket(
          skins: covert,
          weight: 0.005,
        ));
      }

      final totalWeight = availableBuckets.fold<double>(
        0,
            (sum, bucket) => sum + bucket.weight,
      );

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

  Widget _buildDropCard(DroppedSkin drop) {
    final rarityColor = _rarityColorForSkin(drop.skin);
    final variantText = _skinSecondaryText(drop.skin);

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: rarityColor, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              rarityColor.withOpacity(0.18),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;

              final image = Image.asset(
                drop.skin.skinImage,
                height: isNarrow ? 120 : 160,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.image_not_supported, size: isNarrow ? 64 : 80),
              );

              final info = Column(
                crossAxisAlignment:
                isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    drop.fullDisplayName,
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      fontSize: isNarrow ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: rarityColor,
                    ),
                  ),
                  if (variantText != drop.skin.name) ...[
                    const SizedBox(height: 6),
                    Text(
                      variantText,
                      textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _infoRow('Rarity', _rarityLabelForSkin(drop.skin), valueColor: rarityColor),
                  _infoRow('Weapon type', _weaponTypeLabel(drop.skin.weaponType)),
                  _infoRow('Float', drop.skinFloat?.toStringAsFixed(6) ?? '-'),
                  _infoRow('Exterior', drop.exterior ?? '-'),
                  if (drop.skin.collection != null && drop.skin.collection!.isNotEmpty)
                    _infoRow('Collection', drop.skin.collection!),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    image,
                    const SizedBox(height: 12),
                    info,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Center(child: image),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: info,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalLoadingCard() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 14),
              Text(
                'Loading terminal offer...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Please wait',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalOfferCard(TerminalOffer offer) {
    final rarityColor = _rarityColorForSkin(offer.skin);

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
            _infoRow('Rarity', _rarityLabelForSkin(offer.skin), valueColor: rarityColor),
            _infoRow('Weapon type', _weaponTypeLabel(offer.skin.weaponType)),
            _infoRow('Item', offer.skin.itemDisplayName),
            _infoRow('StatTrak', offer.isStatTrak ? 'Yes' : 'No'),
            _infoRow('Float', offer.skinFloat?.toStringAsFixed(6) ?? '-'),
            _infoRow('Exterior', offer.exterior ?? '-'),
            if (offer.skin.collection != null && offer.skin.collection!.isNotEmpty)
              _infoRow('Collection', offer.skin.collection!),
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

  Widget _infoRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              '$title:',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSkinTile(
      SkinDto skin, {
        bool highlighted = false,
        int crossAxisCount = 3,
      }) {
    final rarityColor = _rarityColorForSkin(skin);
    final compact = crossAxisCount >= 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? rarityColor : Colors.white10,
          width: highlighted ? 2.5 : 1,
        ),
        boxShadow: highlighted
            ? [
          BoxShadow(
            color: rarityColor.withOpacity(0.45),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: highlighted ? rarityColor.withOpacity(0.12) : null,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(compact ? 6 : 8),
                child: Image.asset(
                  skin.skinImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            Container(
              height: 5,
              color: rarityColor,
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 6 : 8),
              child: Column(
                children: [
                  Text(
                    skin.itemDisplayName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 11 : 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _skinSecondaryText(skin),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: compact ? 10 : 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rarityLabelForSkin(skin),
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (skin.collection != null &&
                      skin.collection!.isNotEmpty &&
                      !compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      skin.collection!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRollItem(
      SkinDto skin, {
        required bool isWinner,
        required double itemWidth,
      }) {
    final rarityColor = _rarityColorForSkin(skin);

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
                      _skinSecondaryText(skin),
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

  int _gridCrossAxisCount(double width) {
    if (width >= 1500) return 6;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _gridChildAspectRatio(double width) {
    if (width >= 1200) return 0.82;
    if (width >= 900) return 0.78;
    if (width >= 600) return 0.74;
    return 0.7;
  }

  Widget _buildContainerTypeBadge() {
    Color color = Colors.blueGrey;

    if (_isSouvenirPackage) {
      color = Colors.amber;
    } else if (_isCollectionPackage) {
      color = Colors.lightBlueAccent;
    } else if (_isXrayPackage) {
      color = Colors.greenAccent;
    } else if (_isTerminal) {
      color = Colors.deepPurpleAccent;
    } else if (_isRegularCase) {
      color = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        widget.caseDto.typeLabel,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = _formatReleaseDate(widget.caseDto.releaseDate);

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
              final gridCount = _gridCrossAxisCount(constraints.maxWidth);
              final aspectRatio = _gridChildAspectRatio(constraints.maxWidth);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Image.asset(
                            widget.caseDto.caseImage,
                            height: constraints.maxWidth < 700 ? 90 : 120,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.inventory_2, size: 64),
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
                    SliverToBoxAdapter(
                      child: _buildTerminalLoadingCard(),
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
                      child: _buildDropCard(_dropped!),
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

                          return _buildGridSkinTile(
                            skin,
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