import 'package:flutter/material.dart';

import '../../data/models/operation_collection_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_filter_bar.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/responsive_collection_grid.dart';
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

    return CollectionFilterBar<String>(
      items: filters,
      selectedItem: _selectedFilter,
      labelBuilder: (id) => _filterLabel(id, all),
      onSelected: (id) {
        setState(() {
          _selectedFilter = id;
        });
      },
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
        AppNavigationHelper.pushScreen(
          context,
          OperationCollectionOpenScreen(
            collection: collection,
            repository: widget.repository,
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
      body: AsyncCollectionLoader<OperationCollectionDto>(
        future: _future,
        builder: (context, all) {
          final visible = _applyFilters(all);

          return ResponsiveCollectionGrid<OperationCollectionDto>(
            items: visible,
            emptyMessage: 'No operation collections found.',
            header: _buildFilterBar(all),
            itemBuilder: _buildCard,
          );
        },
      ),
    );
  }
}
