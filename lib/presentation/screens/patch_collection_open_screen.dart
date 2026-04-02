import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/patch_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/dropped_patch.dart';
import '../../domain/patch_simulator_service.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/asset_collection_image.dart';
import '../widgets/chip_badge.dart';
import '../widgets/opening_loading_card.dart';
import '../widgets/patch_drop_card.dart';
import '../widgets/patch_grid_tile.dart';

class PatchCollectionOpenScreen extends StatefulWidget {
  final CaseDto collection;
  final LocalDataRepository repository;

  const PatchCollectionOpenScreen({
    super.key,
    required this.collection,
    required this.repository,
  });

  @override
  State<PatchCollectionOpenScreen> createState() =>
      _PatchCollectionOpenScreenState();
}

class _PatchCollectionOpenScreenState extends State<PatchCollectionOpenScreen> {
  late Future<List<PatchDto>> _patchesFuture;
  final PatchSimulatorService _simulator = PatchSimulatorService();
  final Random _random = Random();

  DroppedPatch? _dropped;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _patchesFuture = widget.repository.loadPatchesForCase(widget.collection.id);
  }

  Future<void> _openCollection(List<PatchDto> patches) async {
    if (_isOpening || patches.isEmpty) return;

    setState(() {
      _isOpening = true;
      _dropped = null;
    });

    await Future.delayed(Duration(milliseconds: 1200 + _random.nextInt(800)));
    final drop = _simulator.openContainer(patches: patches);

    if (!mounted) return;
    setState(() {
      _dropped = drop;
      _isOpening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedReleaseDate = DateFormatHelper.formatReleaseDate(
      widget.collection.releaseDate,
    );
    final typeColor = SourceColorHelper.containerTypeColor(widget.collection.type);
    final sourceColor = SourceColorHelper.collectibleSourceColor(
      widget.collection.sourceType,
      widget.collection.sourceId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: FutureBuilder<List<PatchDto>>(
        future: _patchesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final patches = snapshot.data!;

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
                            assetPath: widget.collection.caseImage,
                            height: constraints.maxWidth < 700 ? 90 : 120,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ChipBadge(
                                label: widget.collection.typeLabel,
                                color: typeColor,
                              ),
                              if (widget.collection.sourceTypeLabel != null)
                                ChipBadge(
                                  label: widget.collection.sourceTypeLabel!,
                                  color: sourceColor,
                                ),
                            ],
                          ),
                          if ((widget.collection.sourceName ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.collection.sourceName!,
                              style: TextStyle(
                                color: sourceColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                            'Patch collections open like reward collections: no roulette, just the final reveal.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isOpening || patches.isEmpty)
                                  ? null
                                  : () => _openCollection(patches),
                              child: Text(
                                _isOpening ? 'OPENING...' : 'OPEN PATCH COLLECTION',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isOpening)
                    const SliverToBoxAdapter(
                      child: OpeningLoadingCard(
                        title: 'Opening patch collection...',
                      ),
                    ),
                  if (_dropped != null)
                    SliverToBoxAdapter(child: PatchDropCard(drop: _dropped!)),
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
                      delegate: SliverChildBuilderDelegate((_, index) {
                        final patch = patches[index];
                        final isDropped = _dropped?.patch.id == patch.id;
                        return PatchGridTile(
                          patch: patch,
                          highlighted: isDropped,
                          crossAxisCount: gridCount,
                        );
                      }, childCount: patches.length),
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
