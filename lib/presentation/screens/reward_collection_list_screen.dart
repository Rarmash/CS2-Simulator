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
import 'reward_collection_open_screen.dart';

class RewardCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const RewardCollectionListScreen({super.key, required this.repository});

  @override
  State<RewardCollectionListScreen> createState() =>
      _RewardCollectionListScreenState();
}

class _RewardCollectionListScreenState
    extends State<RewardCollectionListScreen> {
  late Future<List<ContainerDto>> _future;

  static const String _filterAll = 'ALL';
  static const String _filterOperation = 'OPERATION';
  static const String _filterArmory = 'ARMORY';

  String _selectedFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadRewardCollections();
  }

  String _filterLabel(String type) {
    switch (type) {
      case _filterAll:
        return 'All';
      case _filterOperation:
        return 'Operations';
      case _filterArmory:
        return 'Armory';
      default:
        return type;
    }
  }

  List<ContainerDto> _applyFilters(List<ContainerDto> all) {
    var items = List<ContainerDto>.from(all);

    if (_selectedFilter == _filterOperation) {
      items = items.where((e) => e.isOperationRewardCollection).toList();
    } else if (_selectedFilter == _filterArmory) {
      items = items.where((e) => e.isArmoryRewardCollection).toList();
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
    const filters = [_filterAll, _filterOperation, _filterArmory];

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
    final color = SourceColorHelper.rewardSourceColor(
      isArmory: collection.isArmoryRewardCollection,
    );

    return CollectionListCard(
      imagePath: collection.containerImage,
      title: collection.name,
      releaseDate: collection.releaseDate,
      chips: [
        ChipBadge(
          label: collection.isArmoryRewardCollection ? 'Armory' : 'Operation',
          color: color,
        ),
        ChipBadge(
          label: '${collection.cost} ${collection.currencyLabel}',
          color: Colors.white70,
        ),
      ],
      metadata: [
        const SizedBox(height: 8),
        Text(
          collection.sourceLabel,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      onTap: () {
        AppNavigationHelper.pushScreen(
          context,
          RewardCollectionOpenScreen(
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
      appBar: AppBar(title: const Text('Operation / Armory Rewards')),
      body: AsyncCollectionLoader<ContainerDto>(
        future: _future,
        builder: (context, all) {
          final visible = _applyFilters(all);

          return ResponsiveCollectionGrid<ContainerDto>(
            items: visible,
            emptyMessage: 'No reward collections found.',
            header: _buildFilterBar(),
            itemBuilder: _buildCard,
          );
        },
      ),
    );
  }
}
