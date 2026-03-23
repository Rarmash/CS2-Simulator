import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/case_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/case_simulator_service.dart';
import '../../domain/dropped_skin.dart';

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

class _CaseOpenScreenState extends State<CaseOpenScreen> {
  late Future<List<SkinDto>> _skinsFuture;
  final CaseSimulatorService _simulator = CaseSimulatorService();
  final Random _random = Random();

  final ScrollController _rollController = ScrollController();

  DroppedSkin? _dropped;
  bool _isRolling = false;

  List<SkinDto> _rollSequence = const [];
  int _winningIndex = 0;

  static const double _rollItemGap = 10;
  static const double _rollViewportPadding = 12;

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

  Color _rarityColor(String rarity) {
    switch (rarity) {
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

  Future<void> _openCase(List<SkinDto> skins) async {
    if (_isRolling || skins.isEmpty) return;

    final drop = _simulator.openCase(skins);
    final rollData = _buildRollSequence(skins, drop);

    setState(() {
      _isRolling = true;
      _dropped = null;
      _rollSequence = rollData.items;
      _winningIndex = rollData.winnerIndex;
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
    final nonSpecial = allSkins.where((s) => !s.isSpecialItem).toList();
    final milSpec = nonSpecial.where((s) => s.rarity == 'MIL_SPEC').toList();
    final restricted = nonSpecial.where((s) => s.rarity == 'RESTRICTED').toList();
    final classified = nonSpecial.where((s) => s.rarity == 'CLASSIFIED').toList();
    final covert =
    nonSpecial.where((s) => s.rarity == 'COVERT' || s.rarity == 'CONTRABAND').toList();

    SkinDto pickFrom(List<SkinDto> list, List<SkinDto> fallback) {
      if (list.isNotEmpty) return list[_random.nextInt(list.length)];
      return fallback[_random.nextInt(fallback.length)];
    }

    SkinDto pickFlyover() {
      final roll = _random.nextDouble();

      if (covert.isNotEmpty && roll < 0.03) {
        return pickFrom(covert, nonSpecial);
      }
      if (classified.isNotEmpty && roll < 0.14) {
        return pickFrom(classified, nonSpecial);
      }
      if (restricted.isNotEmpty && roll < 0.42) {
        return pickFrom(restricted, nonSpecial);
      }
      if (milSpec.isNotEmpty) {
        return pickFrom(milSpec, nonSpecial);
      }
      return nonSpecial[_random.nextInt(nonSpecial.length)];
    }

    final sequence = <SkinDto>[];

    for (int i = 0; i < 28; i++) {
      sequence.add(pickFlyover());
    }

    if (!drop.skin.isSpecialItem && covert.isNotEmpty && _random.nextDouble() < 0.35) {
      sequence.add(pickFrom(covert, nonSpecial));
    } else if (classified.isNotEmpty && _random.nextDouble() < 0.55) {
      sequence.add(pickFrom(classified, nonSpecial));
    } else if (restricted.isNotEmpty) {
      sequence.add(pickFrom(restricted, nonSpecial));
    } else {
      sequence.add(pickFlyover());
    }

    sequence.add(pickFlyover());
    sequence.add(pickFlyover());

    final winnerIndex = sequence.length;
    sequence.add(drop.skin);

    for (int i = 0; i < 8; i++) {
      sequence.add(pickFlyover());
    }

    return _RollSequenceData(
      items: sequence,
      winnerIndex: winnerIndex,
    );
  }

  Widget _buildDropCard(DroppedSkin drop) {
    final rarityColor = _rarityColorForSkin(drop.skin);

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
                  const SizedBox(height: 10),
                  _infoRow('Rarity', _rarityLabelForSkin(drop.skin), valueColor: rarityColor),
                  _infoRow('Weapon type', _weaponTypeLabel(drop.skin.weaponType)),
                  _infoRow('Item', drop.skin.itemDisplayName),
                  _infoRow('Souvenir', drop.skin.isSouvenir ? 'Yes' : 'No'),
                  _infoRow('StatTrak', drop.isStatTrak ? 'Yes' : 'No'),
                  _infoRow('Float', drop.skinFloat?.toStringAsFixed(6) ?? '-'),
                  _infoRow('Exterior', drop.exterior ?? '-'),
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
                    skin.name,
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
                      skin.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                          const SizedBox(height: 8),
                          if (formattedReleaseDate != null)
                            Text(
                              'Released: $formattedReleaseDate',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isRolling ? null : () => _openCase(skins),
                              child: Text(_isRolling ? 'OPENING...' : 'OPEN CASE'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_rollSequence.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildRoller(),
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