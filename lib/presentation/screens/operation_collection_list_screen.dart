import 'package:flutter/material.dart';

import '../../data/models/operation_collection_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../widgets/asset_collection_image.dart';
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

  Color _operationColor(String operationId) {
    switch (operationId) {
      case 'SHATTERED_WEB':
        return Colors.deepPurpleAccent;
      case 'BLOODHOUND':
        return Colors.redAccent;
      case 'BREAKOUT':
        return Colors.lightBlueAccent;
      case 'PHOENIX':
        return Colors.orangeAccent;
      case 'BRAVO':
        return Colors.greenAccent;
      case 'PAYBACK':
        return Colors.blueAccent;
      default:
        return Colors.blueGrey;
    }
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
    final releaseDate = _formatReleaseDate(collection.releaseDate);
    final color = _operationColor(collection.operationId);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
                      collection.operationName,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  if (releaseDate != null) ...[
                    const SizedBox(height: 8),
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
              final crossAxisCount = _crossAxisCount(constraints.maxWidth);
              final aspectRatio = _childAspectRatio(constraints.maxWidth);

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