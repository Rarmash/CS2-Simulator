import 'package:flutter/material.dart';

import '../../data/models/container_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_filter_bar.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/responsive_collection_grid.dart';

class StickerCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const StickerCollectionListScreen({super.key, required this.repository});

  @override
  State<StickerCollectionListScreen> createState() =>
      _StickerCollectionListScreenState();
}

class _StickerCollectionListScreenState
    extends State<StickerCollectionListScreen> {
  late Future<List<ContainerDto>> _future;

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

  String _sourceGroupLabel(ContainerDto collection) {
    if (collection.sourceType == _filterArmory) {
      return 'Armory';
    }
    return 'Operations';
  }

  List<ContainerDto> _applyFilters(List<ContainerDto> all) {
    var items = List<ContainerDto>.from(all);

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

    return CollectionFilterBar<String>(
      items: filters,
      selectedItem: _selectedFilter,
      labelBuilder: _filterLabel,
      onSelected: (type) {
        setState(() {
          _selectedFilter = type;
        });
      },
    );
  }

  Widget _buildCard(BuildContext context, ContainerDto collection) {
    final typeColor = SourceColorHelper.containerTypeColor(collection.type);
    final isArmory = collection.sourceType == _filterArmory;
    final sourceColor = SourceColorHelper.rewardSourceColor(isArmory: isArmory);
    final sourceLabel = _sourceGroupLabel(collection);

    return CollectionListCard(
      imagePath: collection.containerImage,
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
        AppNavigationHelper.pushScreen(
          context,
          AppNavigationHelper.buildContainerOpenScreen(
            containerDto: collection,
            repository: widget.repository,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sticker Collections')),
      body: AsyncCollectionLoader<ContainerDto>(
        future: _future,
        builder: (context, all) {
          final visible = _applyFilters(all);

          return ResponsiveCollectionGrid<ContainerDto>(
            items: visible,
            emptyMessage: 'No sticker collections found.',
            header: _buildFilterBar(),
            itemBuilder: _buildCard,
          );
        },
      ),
    );
  }
}
