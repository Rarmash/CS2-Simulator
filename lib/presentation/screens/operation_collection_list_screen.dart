import 'package:flutter/material.dart';

import '../../core/collection/collection_tracking_service.dart';
import '../../data/models/container_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_filter_bar.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/collection_source_progress_metadata.dart';
import '../widgets/responsive_collection_grid.dart';
import 'operation_collection_open_screen.dart';

class OperationCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const OperationCollectionListScreen({super.key, required this.repository});

  @override
  State<OperationCollectionListScreen> createState() =>
      _OperationCollectionListScreenState();
}

class _OperationCollectionListScreenState
    extends State<OperationCollectionListScreen> {
  late Future<List<ContainerDto>> _future;
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();

  static const String _filterAll = 'ALL';
  String _selectedFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadOperationCollections();
  }

  List<String> _availableFilters(List<ContainerDto> all) {
    final ids = <String>{_filterAll};

    for (final item in all) {
      ids.add(item.sourceId ?? '');
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

  String _filterLabel(String id, List<ContainerDto> all) {
    if (id == _filterAll) return 'All';

    final match = all.cast<ContainerDto?>().firstWhere(
      (e) => e?.sourceId == id,
      orElse: () => null,
    );

    if (match != null) {
      return match.sourceLabel.replaceFirst('Operation ', '');
    }

    return id;
  }

  List<ContainerDto> _applyFilters(List<ContainerDto> all) {
    var items = List<ContainerDto>.from(all);

    if (_selectedFilter != _filterAll) {
      items = items.where((e) => e.sourceId == _selectedFilter).toList();
    }

    items.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;

      final byOperation = a.sourceLabel.compareTo(b.sourceLabel);
      if (byOperation != 0) return byOperation;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  Widget _buildFilterBar(List<ContainerDto> all) {
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

  Widget _buildCard(BuildContext context, ContainerDto collection) {
    final color = SourceColorHelper.operationColor(collection.sourceId ?? '');

    return CollectionListCard(
      imagePath: collection.containerImage,
      title: collection.name,
      releaseDate: collection.releaseDate,
      chips: [ChipBadge(label: collection.sourceLabel, color: color)],
      metadata: [
        CollectionSourceProgressMetadata(
          container: collection,
          repository: widget.repository,
          trackingService: _collectionTracking,
        ),
      ],
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
      appBar: AppBar(title: const Text('Operation Collections')),
      body: AsyncCollectionLoader<ContainerDto>(
        future: _future,
        builder: (context, all) {
          final visible = _applyFilters(all);

          return ResponsiveCollectionGrid<ContainerDto>(
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
