import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/reward_collection_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/reward_collection_simulator_service.dart';
import '../widgets/asset_collection_image.dart';

class RewardCollectionOpenScreen extends StatefulWidget {
  final RewardCollectionDto collection;
  final LocalDataRepository repository;

  const RewardCollectionOpenScreen({
    super.key,
    required this.collection,
    required this.repository,
  });

  @override
  State<RewardCollectionOpenScreen> createState() =>
      _RewardCollectionOpenScreenState();
}

class _RewardCollectionOpenScreenState
    extends State<RewardCollectionOpenScreen> {
  late Future<List<SkinDto>> _skinsFuture;
  final RewardCollectionSimulatorService _simulator =
  RewardCollectionSimulatorService();
  final Random _random = Random();

  DroppedSkin? _dropped;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _skinsFuture = widget.repository.loadSkinsForRewardCollection(
      widget.collection.id,
    );
  }

  Color _sourceColor() {
    return widget.collection.isArmory
        ? Colors.deepPurpleAccent
        : Colors.amber;
  }

  Color _rarityColorForSkin(SkinDto skin) {
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
      case 'INDUSTRIAL':
        return Colors.lightBlueAccent;
      case 'CONSUMER':
        return Colors.grey;
      default:
        return Colors.white24;
    }
  }

  String _rarityLabelForSkin(SkinDto skin) {
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
      case 'SHOTGUN':
        return 'Shotgun';
      case 'MACHINE_GUN':
        return 'Machine Gun';
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

  Future<void> _openReward(List<SkinDto> skins) async {
    if (_isOpening || skins.isEmpty) return;

    setState(() {
      _isOpening = true;
      _dropped = null;
    });

    await Future.delayed(
      Duration(milliseconds: 1200 + _random.nextInt(800)),
    );

    final drop = _simulator.openRewardCollection(
      skins: skins,
      collection: widget.collection,
    );

    if (!mounted) return;

    setState(() {
      _dropped = drop;
      _isOpening = false;
    });
  }

  Widget _buildOpeningCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 14),
              Text(
                widget.collection.isArmory
                    ? 'Opening armory reward...'
                    : 'Opening operation reward...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please wait',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
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
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported,
                  size: isNarrow ? 64 : 80,
                ),
              );

              final info = Column(
                crossAxisAlignment:
                isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    '${drop.skin.itemDisplayName} | ${drop.skin.name}',
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
                  _infoRow(
                    'Rarity',
                    _rarityLabelForSkin(drop.skin),
                    valueColor: rarityColor,
                  ),
                  _infoRow('Weapon type', _weaponTypeLabel(drop.skin.weaponType)),
                  _infoRow('Float', drop.skinFloat?.toStringAsFixed(6) ?? '-'),
                  _infoRow('Exterior', drop.exterior ?? '-'),
                  if (drop.skin.collection != null &&
                      drop.skin.collection!.isNotEmpty)
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

  Widget _buildSourceBadge() {
    final color = _sourceColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        widget.collection.isArmory ? 'Armory Reward' : 'Operation Reward',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _openButtonLabel() {
    if (_isOpening) {
      return 'OPENING...';
    }
    return widget.collection.actionLabel.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = _formatReleaseDate(widget.collection.releaseDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection.name),
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
                          AssetCollectionImage(
                            assetPath: widget.collection.image,
                            height: constraints.maxWidth < 700 ? 90 : 120,
                          ),
                          const SizedBox(height: 10),
                          _buildSourceBadge(),
                          const SizedBox(height: 8),
                          Text(
                            widget.collection.sourceLabel,
                            style: TextStyle(
                              color: _sourceColor(),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cost: ${widget.collection.cost} ${widget.collection.currencyLabel}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          if (formattedReleaseDate != null) ...[
                            const SizedBox(height: 4),
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
                            'This mode simulates collection rewards. No StatTrak, no knives, no gloves.',
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
                              onPressed:
                              (_isOpening || skins.isEmpty) ? null : () => _openReward(skins),
                              child: Text(_openButtonLabel()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isOpening)
                    SliverToBoxAdapter(
                      child: _buildOpeningCard(),
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
                          'Collection contents',
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