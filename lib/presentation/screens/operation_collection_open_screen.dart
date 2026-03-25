import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/operation_collection_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_skin.dart';
import '../../domain/operation_collection_simulator_service.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/asset_collection_image.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/skin_drop_card.dart';
import '../widgets/skin_grid_tile.dart';
import '../widgets/source_badge.dart';

class OperationCollectionOpenScreen extends StatefulWidget {
  final OperationCollectionDto collection;
  final LocalDataRepository repository;

  const OperationCollectionOpenScreen({
    super.key,
    required this.collection,
    required this.repository,
  });

  @override
  State<OperationCollectionOpenScreen> createState() =>
      _OperationCollectionOpenScreenState();
}

class _OperationCollectionOpenScreenState
    extends State<OperationCollectionOpenScreen> {
  late Future<List<SkinDto>> _skinsFuture;
  final OperationCollectionSimulatorService _simulator =
  OperationCollectionSimulatorService();
  final Random _random = Random();

  DroppedSkin? _dropped;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _skinsFuture = widget.repository.loadSkinsForOperationCollection(
      widget.collection.id,
    );
  }

  Color get _operationColor =>
      SourceColorHelper.operationColor(widget.collection.operationId);

  Future<void> _openCollection(List<SkinDto> skins) async {
    if (_isOpening || skins.isEmpty) return;

    setState(() {
      _isOpening = true;
      _dropped = null;
    });

    await Future.delayed(
      Duration(milliseconds: 1200 + _random.nextInt(800)),
    );

    final drop = _simulator.openCollection(
      skins: skins,
      collection: widget.collection,
    );

    if (!mounted) return;

    setState(() {
      _dropped = drop;
      _isOpening = false;
    });
  }

  String _openButtonLabel() {
    if (_isOpening) {
      return 'OPENING...';
    }
    return 'OPEN COLLECTION DROP';
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate =
    DateFormatHelper.formatReleaseDate(widget.collection.releaseDate);

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
                            assetPath: widget.collection.image,
                            height: constraints.maxWidth < 700 ? 90 : 120,
                          ),
                          const SizedBox(height: 10),
                          SourceBadge(
                            label: widget.collection.operationName,
                            color: _operationColor,
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
                            'Legacy operation collection opening. No StatTrak, no knives, no gloves.',
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
                              onPressed: (_isOpening || skins.isEmpty)
                                  ? null
                                  : () => _openCollection(skins),
                              child: Text(_openButtonLabel()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isOpening)
                    const SliverToBoxAdapter(
                      child: OpeningLoadingCard(
                        title: 'Opening collection drop...',
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