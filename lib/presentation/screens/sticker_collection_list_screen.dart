import 'package:flutter/material.dart';

import '../../data/models/case_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import 'sticker_container_open_screen.dart';

class StickerCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const StickerCollectionListScreen({super.key, required this.repository});

  @override
  State<StickerCollectionListScreen> createState() =>
      _StickerCollectionListScreenState();
}

class _StickerCollectionListScreenState
    extends State<StickerCollectionListScreen> {
  late Future<List<CaseDto>> _future;

  static const String _filterAll = 'ALL';
  static const String _filterArmory = 'ARMORY_REWARD';
  static const String _filterOperations = 'OPERATIONS';

  String _selectedFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadStickerCollections();
  }

  String _filterLabel(String type) {
    switch (type) {
      case _filterAll:
        return 'All';
      case _filterArmory:
        return 'Armory';
      case _filterOperations:
        return 'Operations';
      default:
        return type;
    }
  }

  String _sourceGroupLabel(CaseDto collection) {
    if (collection.sourceType == _filterArmory) {
      return 'Armory';
    }
    return 'Operations';
  }

  List<CaseDto> _applyFilters(List<CaseDto> all) {
    var items = List<CaseDto>.from(all);

    if (_selectedFilter == _filterArmory) {
      items = items.where((e) => e.sourceType == _filterArmory).toList();
    } else if (_selectedFilter == _filterOperations) {
      items = items.where((e) => e.sourceType != _filterArmory).toList();
    }

    items.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return items;
  }

  Widget _buildFilterBar() {
    const filters = [_filterAll, _filterOperations, _filterArmory];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((type) {
          return ChoiceChip(
            label: Text(_filterLabel(type)),
            selected: _selectedFilter == type,
            onSelected: (_) {
              setState(() {
                _selectedFilter = type;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(BuildContext context, CaseDto collection) {
    final typeColor = SourceColorHelper.containerTypeColor(collection.type);
    final isArmory = collection.sourceType == _filterArmory;
    final sourceColor = SourceColorHelper.rewardSourceColor(isArmory: isArmory);
    final sourceLabel = _sourceGroupLabel(collection);

    return CollectionListCard(
      imagePath: collection.caseImage,
      title: collection.name,
      releaseDate: collection.releaseDate,
      chips: [
        ChipBadge(label: collection.typeLabel, color: typeColor),
        ChipBadge(label: sourceLabel, color: sourceColor),
      ],
      metadata: [
        if ((collection.sourceName ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            collection.sourceName!,
            style: TextStyle(
              color: sourceColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StickerContainerOpenScreen(
              caseDto: collection,
              repository: widget.repository,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sticker Collections')),
      body: FutureBuilder<List<CaseDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = List<CaseDto>.from(snapshot.data!);
          final visible = _applyFilters(all);

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = ResponsiveGridHelper.listCrossAxisCount(
                constraints.maxWidth,
              );
              final aspectRatio = ResponsiveGridHelper.listChildAspectRatio(
                constraints.maxWidth,
              );

              return Column(
                children: [
                  _buildFilterBar(),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(
                            child: Text(
                              'No sticker collections found.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: visible.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: aspectRatio,
                                ),
                            itemBuilder: (context, index) {
                              return _buildCard(context, visible[index]);
                            },
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
