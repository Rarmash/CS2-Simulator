import 'package:flutter/material.dart';

import '../../data/models/reward_collection_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../widgets/asset_collection_image.dart';
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

  int _crossAxisCount(double width) {
    if (width >= 1500) return 4;
    if (width >= 1100) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  double _childAspectRatio(double width) {
    if (width >= 1100) return 1.45;
    if (width >= 700) return 1.35;
    return 2.25;
  }

  Color _sourceColor(RewardCollectionDto collection) {
    if (collection.isArmory) return Colors.deepPurpleAccent;
    return Colors.amber;
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
    final releaseDate = _formatReleaseDate(collection.releaseDate);
    final color = _sourceColor(collection);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 320;

              final image = AssetCollectionImage(
                assetPath: collection.image,
                fit: BoxFit.contain,
              );

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Text(
                          collection.isArmory ? 'Armory' : 'Operation',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${collection.cost} ${collection.currencyLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    collection.name,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    collection.sourceLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (releaseDate != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Released: $releaseDate',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              );

              if (constraints.maxWidth < 500) {
                return Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: image,
                      ),
                    ),
                    Expanded(child: textBlock),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: image,
                    ),
                  ),
                  textBlock,
                ],
              );
            },
          ),
        ),
      ),
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
              final crossAxisCount = _crossAxisCount(constraints.maxWidth);
              final aspectRatio = _childAspectRatio(constraints.maxWidth);

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