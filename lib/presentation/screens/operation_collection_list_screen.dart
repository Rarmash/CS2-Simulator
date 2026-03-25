import 'package:flutter/material.dart';

import '../../data/models/operation_collection_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import 'operation_collection_open_screen.dart';

class OperationCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const OperationCollectionListScreen({
    super.key,
    required this.repository,
  });

  @override
  State<OperationCollectionListScreen> createState() =>
      _OperationCollectionListScreenState();
}

class _OperationCollectionListScreenState
    extends State<OperationCollectionListScreen> {
  late Future<List<OperationCollectionDto>> _future;

  static const String _filterAll = 'ALL';
  String _selectedFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadOperationCollections();
  }

  List<String> _availableFilters(List<OperationCollectionDto> all) {
    final ids = <String>{_filterAll};

    for (final item in all) {
      ids.add(item.operationId);
    }

    final ordered = <String>[_filterAll];
    final knownOrder = [
      'PAYBACK',
      'BRAVO',
      'PHOENIX',
      'BREAKOUT',
      'BLOODHOUND',
      'SHATTERED_WEB',
    ];

    for (final id in knownOrder) {
      if (ids.contains(id)) {
        ordered.add(id);
      }
    }

    for (final id in ids) {
      if (!ordered.contains(id)) {
        ordered.add(id);
      }
    }

    return ordered;
  }

  String _filterLabel(String id, List<OperationCollectionDto> all) {
    if (id == _filterAll) return 'All';

    final match = all.cast<OperationCollectionDto?>().firstWhere(
          (e) => e?.operationId == id,
      orElse: () => null,
    );

    if (match != null) {
      return match.operationName.replaceFirst('Operation ', '');
    }

    return id;
  }

  List<OperationCollectionDto> _applyFilters(List<OperationCollectionDto> all) {
    var items = List<OperationCollectionDto>.from(all);

    if (_selectedFilter != _filterAll) {
      items = items.where((e) => e.operationId == _selectedFilter).toList();
    }

    items.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;

      final byOperation = a.operationName.compareTo(b.operationName);
      if (byOperation != 0) return byOperation;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  Widget _buildFilterBar(List<OperationCollectionDto> all) {
    final filters = _availableFilters(all);

    if (_selectedFilter != _filterAll && !filters.contains(_selectedFilter)) {
      _selectedFilter = _filterAll;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((id) {
          return ChoiceChip(
            label: Text(_filterLabel(id, all)),
            selected: _selectedFilter == id,
            onSelected: (_) {
              setState(() {
                _selectedFilter = id;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(BuildContext context, OperationCollectionDto collection) {
    final color = SourceColorHelper.operationColor(collection.operationId);

    return CollectionListCard(
      imagePath: collection.image,
      title: collection.name,
      releaseDate: collection.releaseDate,
      chips: [
        ChipBadge(
          label: collection.operationName,
          color: color,
        ),
      ],
      metadata: const [],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OperationCollectionOpenScreen(
              collection: collection,
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
      appBar: AppBar(
        title: const Text('Operation Collections'),
      ),
      body: FutureBuilder<List<OperationCollectionDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = List<OperationCollectionDto>.from(snapshot.data!);
          final visible = _applyFilters(all);

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
              ResponsiveGridHelper.listCrossAxisCount(constraints.maxWidth);
              final aspectRatio =
              ResponsiveGridHelper.listChildAspectRatio(constraints.maxWidth);

              return Column(
                children: [
                  _buildFilterBar(all),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(
                      child: Text(
                        'No operation collections found.',
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