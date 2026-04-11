import 'package:flutter/material.dart';

import '../../core/collection/collection_entry.dart';
import '../../core/collection/collection_summary.dart';
import '../../core/collection/collection_tracking_service.dart';
import '../helpers/app_navigation_helper.dart';

class MyCollectionScreen extends StatefulWidget {
  const MyCollectionScreen({super.key});

  @override
  State<MyCollectionScreen> createState() => _MyCollectionScreenState();
}

class _MyCollectionScreenState extends State<MyCollectionScreen> {
  final CollectionTrackingService _service = CollectionTrackingService();

  late Future<_CollectionData> _dataFuture;
  String _inventorySearch = '';
  String _inventoryCategory = 'ALL';
  String _inventoryRarity = 'ALL';
  String _inventoryStatTrak = 'ALL';
  String _inventorySort = 'LATEST';

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_CollectionData> _loadData() async {
    final entries = await _service.loadEntries();
    final summaries = await _service.loadSummaries();
    return _CollectionData(entries: entries, summaries: summaries);
  }

  Future<void> _refresh() async {
    final future = _loadData();
    setState(() {
      _dataFuture = future;
    });
    await future;
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear collection data?'),
        content: const Text(
          'This will remove all saved collection items and recent activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _service.clearAll();
    await _refresh();
  }

  List<CollectionSummary> _filterInventory(List<CollectionSummary> summaries) {
    final query = _inventorySearch.trim().toLowerCase();

    final filtered = summaries.where((summary) {
      if (_inventoryCategory != 'ALL' &&
          summary.filterCategory != _inventoryCategory) {
        return false;
      }

      if (_inventoryRarity != 'ALL' && summary.rarity != _inventoryRarity) {
        return false;
      }

      if (_inventoryStatTrak == 'ONLY' && !summary.hasStatTrak) {
        return false;
      }

      if (_inventoryStatTrak == 'NONE' && summary.hasStatTrak) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return summary.title.toLowerCase().contains(query) ||
          summary.subtitle.toLowerCase().contains(query) ||
          summary.latestEntry.sourceName.toLowerCase().contains(query) ||
          summary.categoryLabel.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_inventorySort) {
        case 'A_Z':
          return a.title.compareTo(b.title);
        case 'MOST_OWNED':
          final countCompare = b.count.compareTo(a.count);
          if (countCompare != 0) {
            return countCompare;
          }
          return b.latestAcquiredAt.compareTo(a.latestAcquiredAt);
        case 'BEST_FLOAT':
          final aFloat = a.bestFloat ?? 999;
          final bFloat = b.bestFloat ?? 999;
          final floatCompare = aFloat.compareTo(bFloat);
          if (floatCompare != 0) {
            return floatCompare;
          }
          return a.title.compareTo(b.title);
        case 'LATEST':
        default:
          return b.latestAcquiredAt.compareTo(a.latestAcquiredAt);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          IconButton(
            tooltip: 'Recent activity',
            onPressed: () {
              AppNavigationHelper.pushScreen(
                context,
                const CollectionHistoryScreen(),
              );
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Clear all',
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder<_CollectionData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final filteredSummaries = _filterInventory(data.summaries);

          return Column(
            children: [
              _CollectionOverview(
                totalEntries: data.entries.length,
                uniqueItems: data.summaries.length,
              ),
              Expanded(
                child: _InventoryTab(
                  summaries: filteredSummaries,
                  totalCount: data.summaries.length,
                  search: _inventorySearch,
                  selectedCategory: _inventoryCategory,
                  selectedRarity: _inventoryRarity,
                  selectedStatTrak: _inventoryStatTrak,
                  selectedSort: _inventorySort,
                  onSearchChanged: (value) {
                    setState(() {
                      _inventorySearch = value;
                    });
                  },
                  onCategoryChanged: (value) {
                    setState(() {
                      _inventoryCategory = value;
                    });
                  },
                  onRarityChanged: (value) {
                    setState(() {
                      _inventoryRarity = value;
                    });
                  },
                  onStatTrakChanged: (value) {
                    setState(() {
                      _inventoryStatTrak = value;
                    });
                  },
                  onSortChanged: (value) {
                    setState(() {
                      _inventorySort = value;
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CollectionHistoryScreen extends StatefulWidget {
  const CollectionHistoryScreen({super.key});

  @override
  State<CollectionHistoryScreen> createState() =>
      _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState extends State<CollectionHistoryScreen> {
  final CollectionTrackingService _service = CollectionTrackingService();
  late Future<List<CollectionEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadEntries();
  }

  Future<void> _refresh() async {
    final future = _service.loadEntries();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activity'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<CollectionEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return _HistoryTab(entries: snapshot.data!);
        },
      ),
    );
  }
}

class _CollectionOverview extends StatelessWidget {
  final int totalEntries;
  final int uniqueItems;

  const _CollectionOverview({
    required this.totalEntries,
    required this.uniqueItems,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(
                icon: Icons.inventory_2_outlined,
                label: 'Collected entries',
                value: '$totalEntries',
              ),
              _StatChip(
                icon: Icons.collections_bookmark_outlined,
                label: 'Unique items',
                value: '$uniqueItems',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  final List<CollectionSummary> summaries;
  final int totalCount;
  final String search;
  final String selectedCategory;
  final String selectedRarity;
  final String selectedStatTrak;
  final String selectedSort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onRarityChanged;
  final ValueChanged<String> onStatTrakChanged;
  final ValueChanged<String> onSortChanged;

  const _InventoryTab({
    required this.summaries,
    required this.totalCount,
    required this.search,
    required this.selectedCategory,
    required this.selectedRarity,
    required this.selectedStatTrak,
    required this.selectedSort,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onRarityChanged,
    required this.onStatTrakChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categoryValues =
        summaries.map((item) => item.filterCategory).toSet().toList()..sort();
    final rarityValues = summaries.map((item) => item.rarity).toSet().toList()
      ..sort();

    final categoryOptions = <String>['ALL', ...categoryValues];
    final rarityOptions = <String>['ALL', ...rarityValues];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final fieldWidth = wide
                      ? (constraints.maxWidth - 24) / 3
                      : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: search,
                        decoration: const InputDecoration(
                          hintText: 'Search your collection...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: onSearchChanged,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                isDense: true,
                              ),
                              items: categoryOptions
                                  .map(
                                    (option) => DropdownMenuItem<String>(
                                      value: option,
                                      child: Text(
                                        option == 'ALL'
                                            ? 'All'
                                            : _categoryLabelFor(option),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  onCategoryChanged(value);
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedRarity,
                              decoration: const InputDecoration(
                                labelText: 'Rarity',
                                isDense: true,
                              ),
                              items: rarityOptions
                                  .map(
                                    (option) => DropdownMenuItem<String>(
                                      value: option,
                                      child: Text(
                                        option == 'ALL'
                                            ? 'All'
                                            : _rarityLabel(option),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  onRarityChanged(value);
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedStatTrak,
                              decoration: const InputDecoration(
                                labelText: 'StatTrak',
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'ALL',
                                  child: Text('All'),
                                ),
                                DropdownMenuItem(
                                  value: 'ONLY',
                                  child: Text('Only StatTrak'),
                                ),
                                DropdownMenuItem(
                                  value: 'NONE',
                                  child: Text('No StatTrak'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  onStatTrakChanged(value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedSort,
                              decoration: const InputDecoration(
                                labelText: 'Sort by',
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'LATEST',
                                  child: Text('Latest'),
                                ),
                                DropdownMenuItem(
                                  value: 'MOST_OWNED',
                                  child: Text('Most collected'),
                                ),
                                DropdownMenuItem(
                                  value: 'BEST_FLOAT',
                                  child: Text('Best float'),
                                ),
                                DropdownMenuItem(
                                  value: 'A_Z',
                                  child: Text('Name A-Z'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  onSortChanged(value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${summaries.length} / $totalCount',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: summaries.isEmpty
              ? const _EmptyCollectionState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No items match these filters',
                  subtitle:
                      'Try a broader search or clear one of the active filters.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: summaries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _InventoryCard(summary: summaries[index]),
                ),
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final CollectionSummary summary;

  const _InventoryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final accent = _rarityColor(summary.rarity);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 88,
              height: 72,
              alignment: Alignment.center,
              child: Image.asset(
                summary.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaBadge(
                        label: '${summary.count} collected',
                        color: accent,
                      ),
                      _MetaBadge(label: summary.categoryLabel),
                      if (summary.bestFloat != null)
                        _MetaBadge(
                          label:
                              'Best FV ${summary.bestFloat!.toStringAsFixed(5)}',
                        ),
                      if (summary.hasStatTrak)
                        const _MetaBadge(label: 'StatTrak'),
                      if (summary.hasSouvenir)
                        const _MetaBadge(label: 'Souvenir'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latest: ${summary.latestEntry.sourceName} - ${_formatDateTime(summary.latestAcquiredAt)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<CollectionEntry> entries;

  const _HistoryTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyCollectionState(
        icon: Icons.history,
        title: 'No history yet',
        subtitle: 'Your opening and Trade-Up results will show up here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _HistoryCard(entry: entries[index]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CollectionEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final accent = _rarityColor(entry.rarity);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 76,
              height: 60,
              alignment: Alignment.center,
              child: Image.asset(
                entry.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaBadge(label: entry.categoryLabel, color: accent),
                      if ((entry.exterior ?? '').isNotEmpty)
                        _MetaBadge(label: entry.exterior!),
                      if (entry.floatValue != null)
                        _MetaBadge(
                          label: 'FV ${entry.floatValue!.toStringAsFixed(5)}',
                        ),
                      if (entry.patternSeed != null)
                        _MetaBadge(label: 'Pattern ${entry.patternSeed}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${entry.sourceName} - ${_formatDateTime(entry.acquiredAt)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const _MetaBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (color ?? Colors.white24).withValues(alpha: 0.5),
        ),
        color: (color ?? Colors.white).withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color ?? Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyCollectionState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCollectionState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionData {
  final List<CollectionEntry> entries;
  final List<CollectionSummary> summaries;

  const _CollectionData({required this.entries, required this.summaries});
}

Color _rarityColor(String rarity) {
  switch (rarity) {
    case 'CONSUMER':
      return Colors.grey;
    case 'INDUSTRIAL':
      return Colors.lightBlueAccent;
    case 'MIL_SPEC':
      return Colors.blue;
    case 'RESTRICTED':
      return Colors.purpleAccent;
    case 'CLASSIFIED':
      return Colors.pinkAccent;
    case 'COVERT':
      return Colors.redAccent;
    case 'CONTRABAND':
      return const Color(0xFFFF8A00);
    case 'HIGH_GRADE':
      return Colors.blueAccent;
    case 'REMARKABLE':
      return Colors.purpleAccent;
    case 'EXOTIC':
      return Colors.pinkAccent;
    case 'EXTRAORDINARY':
      return const Color(0xFFEB4B4B);
    default:
      return Colors.white70;
  }
}

String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}

extension on CollectionEntry {
  String get categoryLabel => _categoryLabelFor(category);
}

extension on CollectionSummary {
  String get categoryLabel => _categoryLabelFor(filterCategory);
}

String _categoryLabelFor(String category) {
  switch (category) {
    case 'knife':
      return 'Knife';
    case 'gloves':
      return 'Gloves';
    case 'skin':
      return 'Skin';
    case 'sticker':
      return 'Sticker';
    case 'pin':
      return 'Pin';
    case 'music_kit':
      return 'Music Kit';
    case 'agent':
      return 'Agent';
    case 'graffiti':
      return 'Graffiti';
    case 'patch':
      return 'Patch';
    case 'charm':
      return 'Charm';
    default:
      return category;
  }
}

String _rarityLabel(String rarity) {
  switch (rarity) {
    case 'CONSUMER':
      return 'Consumer';
    case 'INDUSTRIAL':
      return 'Industrial';
    case 'MIL_SPEC':
      return 'Mil-Spec';
    case 'RESTRICTED':
      return 'Restricted';
    case 'CLASSIFIED':
      return 'Classified';
    case 'COVERT':
      return 'Covert';
    case 'CONTRABAND':
      return 'Contraband';
    case 'HIGH_GRADE':
      return 'High Grade';
    case 'REMARKABLE':
      return 'Remarkable';
    case 'EXOTIC':
      return 'Exotic';
    case 'EXTRAORDINARY':
      return 'Extraordinary';
    default:
      return rarity;
  }
}
