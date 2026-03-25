import 'package:flutter/material.dart';

import '../../data/models/reward_collection_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import 'reward_collection_open_screen.dart';

class RewardCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const RewardCollectionListScreen({
    super.key,
    required this.repository,
  });

  @override
  State<RewardCollectionListScreen> createState() =>
      _RewardCollectionListScreenState();
}

class _RewardCollectionListScreenState
    extends State<RewardCollectionListScreen> {
  late Future<List<RewardCollectionDto>> _future;

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

  List<RewardCollectionDto> _applyFilters(List<RewardCollectionDto> all) {
    var items = List<RewardCollectionDto>.from(all);

    if (_selectedFilter == _filterOperation) {
      items = items.where((e) => e.isOperation).toList();
    } else if (_selectedFilter == _filterArmory) {
      items = items.where((e) => e.isArmory).toList();
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

  Widget _buildCard(BuildContext context, RewardCollectionDto collection) {
    final color = SourceColorHelper.rewardSourceColor(
      isArmory: collection.isArmory,
    );

    return CollectionListCard(
      imagePath: collection.image,
      title: collection.name,
      releaseDate: collection.releaseDate,
      chips: [
        ChipBadge(
          label: collection.isArmory ? 'Armory' : 'Operation',
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RewardCollectionOpenScreen(
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
        title: const Text('Operation / Armory Rewards'),
      ),
      body: FutureBuilder<List<RewardCollectionDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = List<RewardCollectionDto>.from(snapshot.data!);
          final visible = _applyFilters(all);

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
              ResponsiveGridHelper.listCrossAxisCount(constraints.maxWidth);
              final aspectRatio =
              ResponsiveGridHelper.listChildAspectRatio(constraints.maxWidth);

              return Column(
                children: [
                  _buildFilterBar(),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(
                      child: Text(
                        'No reward collections found.',
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