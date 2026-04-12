import 'package:flutter/material.dart';

import '../../core/collection/collection_entry.dart';
import '../../core/collection/collection_summary.dart';
import '../../core/collection/collection_tracking_service.dart';
import '../../core/settings/settings_controller.dart';
import '../../data/models/container_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import 'agent_details_screen.dart';
import 'charm_details_screen.dart';
import 'graffiti_details_screen.dart';
import 'music_kit_details_screen.dart';
import 'patch_details_screen.dart';
import 'pin_details_screen.dart';
import 'skin_details_screen.dart';
import 'sticker_details_screen.dart';

class MyCollectionScreen extends StatefulWidget {
  final LocalDataRepository repository;
  final SettingsController settingsController;

  const MyCollectionScreen({
    super.key,
    required this.repository,
    required this.settingsController,
  });

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
    final progress = await _loadProgress(summaries);
    final sourceHighlights = await _loadSourceHighlights(entries);

    return _CollectionData(
      entries: entries,
      summaries: summaries,
      progress: progress,
      sourceHighlights: sourceHighlights,
    );
  }

  Future<List<_CollectionProgressItem>> _loadProgress(
    List<CollectionSummary> summaries,
  ) async {
    final results = await Future.wait<dynamic>([
      widget.repository.loadSkinGroups(),
      widget.repository.loadStickers(),
      widget.repository.loadPins(),
      widget.repository.loadGroupedMusicKits(),
      widget.repository.loadAgents(),
      widget.repository.loadGraffiti(),
      widget.repository.loadPatches(),
      widget.repository.loadCharms(),
    ]);

    final skinGroups = results[0] as List<dynamic>;
    final stickers = results[1] as List<dynamic>;
    final pins = results[2] as List<dynamic>;
    final musicKits = results[3] as List<dynamic>;
    final agents = results[4] as List<dynamic>;
    final graffiti = results[5] as List<dynamic>;
    final patches = results[6] as List<dynamic>;
    final charms = results[7] as List<dynamic>;

    final collectedByCategory = <String, Set<String>>{};
    for (final summary in summaries) {
      collectedByCategory
          .putIfAbsent(summary.category, () => <String>{})
          .add(summary.latestEntry.itemId);
      collectedByCategory
          .putIfAbsent(summary.filterCategory, () => <String>{})
          .add(summary.latestEntry.itemId);
    }

    int groupedCollectedCount(
      Iterable<dynamic> groups,
      String category,
      bool Function(dynamic group) predicate,
    ) {
      final collected = collectedByCategory[category] ?? const <String>{};
      return groups.where(predicate).where((group) {
        final variants = (group.variants as List<dynamic>)
            .map((variant) => variant.id as String)
            .toSet();
        return variants.any(collected.contains);
      }).length;
    }

    return [
      _CollectionProgressItem(
        key: 'skin',
        label: 'Skins',
        icon: Icons.menu_book,
        collected: groupedCollectedCount(
          skinGroups,
          'skin',
          (group) => group.itemKind == 'WEAPON',
        ),
        total: skinGroups.where((group) => group.itemKind == 'WEAPON').length,
      ),
      _CollectionProgressItem(
        key: 'knife',
        label: 'Knives',
        icon: Icons.content_cut,
        collected: groupedCollectedCount(
          skinGroups,
          'knife',
          (group) => group.itemKind == 'KNIFE',
        ),
        total: skinGroups.where((group) => group.itemKind == 'KNIFE').length,
      ),
      _CollectionProgressItem(
        key: 'gloves',
        label: 'Gloves',
        icon: Icons.back_hand_outlined,
        collected: groupedCollectedCount(
          skinGroups,
          'gloves',
          (group) => group.itemKind == 'GLOVES',
        ),
        total: skinGroups.where((group) => group.itemKind == 'GLOVES').length,
      ),
      _CollectionProgressItem(
        key: 'sticker',
        label: 'Stickers',
        icon: Icons.sell,
        collected: (collectedByCategory['sticker'] ?? const <String>{}).length,
        total: stickers.length,
      ),
      _CollectionProgressItem(
        key: 'pin',
        label: 'Pins',
        icon: Icons.push_pin,
        collected: (collectedByCategory['pin'] ?? const <String>{}).length,
        total: pins.length,
      ),
      _CollectionProgressItem(
        key: 'music_kit',
        label: 'Music Kits',
        icon: Icons.library_music,
        collected: musicKits.where((group) {
          final collected =
              collectedByCategory['music_kit'] ?? const <String>{};
          final variants = (group.variants as List<dynamic>)
              .map((variant) => variant.id as String)
              .toSet();
          return variants.any(collected.contains);
        }).length,
        total: musicKits.length,
      ),
      _CollectionProgressItem(
        key: 'agent',
        label: 'Agents',
        icon: Icons.badge,
        collected: (collectedByCategory['agent'] ?? const <String>{}).length,
        total: agents.length,
      ),
      _CollectionProgressItem(
        key: 'graffiti',
        label: 'Graffiti',
        icon: Icons.brush,
        collected: (collectedByCategory['graffiti'] ?? const <String>{}).length,
        total: graffiti.length,
      ),
      _CollectionProgressItem(
        key: 'patch',
        label: 'Patches',
        icon: Icons.style,
        collected: (collectedByCategory['patch'] ?? const <String>{}).length,
        total: patches.length,
      ),
      _CollectionProgressItem(
        key: 'charm',
        label: 'Charms',
        icon: Icons.key,
        collected: (collectedByCategory['charm'] ?? const <String>{}).length,
        total: charms.length,
      ),
    ];
  }

  Future<List<_SourceProgressItem>> _loadSourceHighlights(
    List<CollectionEntry> entries,
  ) async {
    final sourceEntriesByKey = <String, List<CollectionEntry>>{};
    for (final entry in entries) {
      final key = '${entry.sourceType}|${entry.sourceName}';
      sourceEntriesByKey.putIfAbsent(key, () => <CollectionEntry>[]).add(entry);
    }

    if (sourceEntriesByKey.isEmpty) {
      return const [];
    }

    final results = await Future.wait<dynamic>([
      widget.repository.loadContainers(),
      widget.repository.loadContainerContents(),
      widget.repository.loadStickerContents(),
      widget.repository.loadPinContents(),
      widget.repository.loadMusicKitContents(),
      widget.repository.loadGraffitiContents(),
      widget.repository.loadPatchContents(),
      widget.repository.loadCharmContents(),
      widget.repository.loadAgentCollectionContents(),
      widget.repository.loadRewardCollectionContents(),
      widget.repository.loadOperationCollectionContents(),
    ]);

    final containers = results[0] as List<ContainerDto>;
    final containerItemCounts = {
      for (final item in results[1] as List<dynamic>)
        item.containerId as String: (item.skinIds as List<dynamic>).length,
    };
    final stickerItemCounts = {
      for (final item in results[2] as List<dynamic>)
        item.containerId as String: (item.stickerIds as List<dynamic>).length,
    };
    final pinItemCounts = {
      for (final item in results[3] as List<dynamic>)
        item.containerId as String: (item.pinIds as List<dynamic>).length,
    };
    final musicKitItemCounts = {
      for (final item in results[4] as List<dynamic>)
        item.containerId as String: (item.items as List<dynamic>)
            .map((entry) => entry.musicKitId as String)
            .toSet()
            .length,
    };
    final graffitiItemCounts = {
      for (final item in results[5] as List<dynamic>)
        item.containerId as String: (item.graffitiIds as List<dynamic>).length,
    };
    final patchItemCounts = {
      for (final item in results[6] as List<dynamic>)
        item.containerId as String: (item.patchIds as List<dynamic>).length,
    };
    final charmItemCounts = {
      for (final item in results[7] as List<dynamic>)
        item.containerId as String: (item.charmIds as List<dynamic>).length,
    };
    final agentItemCounts = {
      for (final item in results[8] as List<dynamic>)
        item.agentCollectionId as String:
            (item.agentIds as List<dynamic>).length,
    };
    final rewardItemCounts = {
      for (final item in results[9] as List<dynamic>)
        item.rewardCollectionId as String:
            (item.skinIds as List<dynamic>).length,
    };
    final operationItemCounts = {
      for (final item in results[10] as List<dynamic>)
        item.operationCollectionId as String:
            (item.skinIds as List<dynamic>).length,
    };

    int? totalCountFor(ContainerDto container) {
      switch (container.type) {
        case 'CASE':
        case 'SOUVENIR_PACKAGE':
        case 'TERMINAL':
        case 'XRAY_PACKAGE':
          return containerItemCounts[container.id];
        case 'STICKER_CAPSULE':
        case 'STICKER_COLLECTION':
          return stickerItemCounts[container.id];
        case 'PIN_CAPSULE':
          return pinItemCounts[container.id];
        case 'MUSIC_KIT_BOX':
          return musicKitItemCounts[container.id];
        case 'GRAFFITI_BOX':
          return graffitiItemCounts[container.id];
        case 'PATCH_PACK':
        case 'PATCH_COLLECTION':
          return patchItemCounts[container.id];
        case 'CHARM_COLLECTION':
          return charmItemCounts[container.id];
        case 'AGENT_COLLECTION':
          return agentItemCounts[container.id];
        case 'REWARD_COLLECTION':
          return rewardItemCounts[container.id];
        case 'OPERATION_COLLECTION':
          return operationItemCounts[container.id];
        default:
          return null;
      }
    }

    final highlights = <_SourceProgressItem>[];
    for (final container in containers) {
      final key = '${container.type}|${container.name}';
      final sourceEntries = sourceEntriesByKey[key];
      if (sourceEntries == null || sourceEntries.isEmpty) {
        continue;
      }

      final totalCount = totalCountFor(container);
      if (totalCount == null || totalCount == 0) {
        continue;
      }

      highlights.add(
        _SourceProgressItem(
          container: container,
          openedCount: sourceEntries.length,
          collectedCount: sourceEntries
              .map((item) => '${item.category}:${item.itemId}')
              .toSet()
              .length,
          totalCount: totalCount,
        ),
      );
    }

    highlights.sort((a, b) {
      final completionCompare = b.completion.compareTo(a.completion);
      if (completionCompare != 0) {
        return completionCompare;
      }
      final collectedCompare = b.collectedCount.compareTo(a.collectedCount);
      if (collectedCompare != 0) {
        return collectedCompare;
      }
      final openedCompare = b.openedCount.compareTo(a.openedCount);
      if (openedCompare != 0) {
        return openedCompare;
      }
      return a.container.name.compareTo(b.container.name);
    });

    return highlights.take(6).toList();
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
                CollectionHistoryScreen(
                  repository: widget.repository,
                  settingsController: widget.settingsController,
                ),
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
          final totalCollected = data.progress.fold<int>(
            0,
            (sum, item) => sum + item.collected,
          );
          final totalAvailable = data.progress.fold<int>(
            0,
            (sum, item) => sum + item.total,
          );

          return Column(
            children: [
              _CollectionOverview(
                totalEntries: data.entries.length,
                uniqueItems: data.summaries.length,
                totalCollected: totalCollected,
                totalAvailable: totalAvailable,
              ),
              _CollectionProgressSection(items: data.progress),
              _SourceHighlightsSection(
                items: data.sourceHighlights,
                onItemTap: _openSourceHighlight,
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
                  onItemTap: _openSummary,
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
  final LocalDataRepository repository;
  final SettingsController settingsController;

  const CollectionHistoryScreen({
    super.key,
    required this.repository,
    required this.settingsController,
  });

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

          return _HistoryTab(entries: snapshot.data!, onItemTap: _openEntry);
        },
      ),
    );
  }

  Future<void> _openEntry(CollectionEntry entry) async {
    final screen = await _buildDetailsScreen(
      repository: widget.repository,
      settingsController: widget.settingsController,
      category: entry.category,
      itemId: entry.itemId,
    );

    if (!mounted) {
      return;
    }

    if (screen == null) {
      _showMissingItemMessage();
      return;
    }

    AppNavigationHelper.pushScreen(context, screen);
  }

  void _showMissingItemMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This item is no longer available in the current glossary data.',
        ),
      ),
    );
  }
}

class _CollectionOverview extends StatelessWidget {
  final int totalEntries;
  final int uniqueItems;
  final int totalCollected;
  final int totalAvailable;

  const _CollectionOverview({
    required this.totalEntries,
    required this.uniqueItems,
    required this.totalCollected,
    required this.totalAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final completion = totalAvailable == 0
        ? 0
        : totalCollected / totalAvailable;

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
              _StatChip(
                icon: Icons.checklist_outlined,
                label: 'Overall completion',
                value:
                    '$totalCollected / $totalAvailable (${(completion * 100).floor()}%)',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionProgressSection extends StatelessWidget {
  final List<_CollectionProgressItem> items;

  const _CollectionProgressSection({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collection Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map((item) => _ProgressTile(item: item))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceHighlightsSection extends StatelessWidget {
  final List<_SourceProgressItem> items;
  final ValueChanged<_SourceProgressItem> onItemTap;

  const _SourceHighlightsSection({
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Best Source Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your most completed containers and collection sources.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SourceHighlightTile(
                    item: item,
                    onTap: () => onItemTap(item),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceHighlightTile extends StatelessWidget {
  final _SourceProgressItem item;
  final VoidCallback onTap;

  const _SourceHighlightTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
            color: Colors.white.withValues(alpha: 0.03),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: Image.asset(
                  item.container.containerImage,
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
                      item.container.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.container.typeLabel} • ${item.collectedCount}/${item.totalCount} collected • ${item.openedCount} opened',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.completion,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(item.completion * 100).floor()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final _CollectionProgressItem item;

  const _ProgressTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final total = item.total == 0 ? 1 : item.total;
    final progress = item.collected / total;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
          color: Colors.white.withValues(alpha: 0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${item.collected}/${item.total}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).floor()}% complete',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
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
  final ValueChanged<CollectionSummary> onItemTap;

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
    required this.onItemTap,
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
                  itemBuilder: (context, index) => _InventoryCard(
                    summary: summaries[index],
                    onTap: () => onItemTap(summaries[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final CollectionSummary summary;
  final VoidCallback onTap;

  const _InventoryCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = _rarityColor(summary.rarity);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
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
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<CollectionEntry> entries;
  final ValueChanged<CollectionEntry> onItemTap;

  const _HistoryTab({required this.entries, required this.onItemTap});

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
      itemBuilder: (context, index) => _HistoryCard(
        entry: entries[index],
        onTap: () => onItemTap(entries[index]),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CollectionEntry entry;
  final VoidCallback onTap;

  const _HistoryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = _rarityColor(entry.rarity);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
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
  final List<_CollectionProgressItem> progress;
  final List<_SourceProgressItem> sourceHighlights;

  const _CollectionData({
    required this.entries,
    required this.summaries,
    required this.progress,
    required this.sourceHighlights,
  });
}

class _CollectionProgressItem {
  final String key;
  final String label;
  final IconData icon;
  final int collected;
  final int total;

  const _CollectionProgressItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.collected,
    required this.total,
  });
}

class _SourceProgressItem {
  final ContainerDto container;
  final int openedCount;
  final int collectedCount;
  final int totalCount;

  const _SourceProgressItem({
    required this.container,
    required this.openedCount,
    required this.collectedCount,
    required this.totalCount,
  });

  double get completion => totalCount == 0 ? 0 : collectedCount / totalCount;
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

extension on _MyCollectionScreenState {
  void _openSourceHighlight(_SourceProgressItem item) {
    AppNavigationHelper.pushScreen(
      context,
      AppNavigationHelper.buildContainerOpenScreen(
        containerDto: item.container,
        repository: widget.repository,
        settingsController: widget.settingsController,
      ),
    );
  }

  Future<void> _openSummary(CollectionSummary summary) async {
    final screen = await _buildDetailsScreen(
      repository: widget.repository,
      settingsController: widget.settingsController,
      category: summary.category,
      itemId: summary.latestEntry.itemId,
    );

    if (!mounted) {
      return;
    }

    if (screen == null) {
      _showMissingItemMessage();
      return;
    }

    AppNavigationHelper.pushScreen(context, screen);
  }

  void _showMissingItemMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This item is no longer available in the current glossary data.',
        ),
      ),
    );
  }
}

Future<Widget?> _buildDetailsScreen({
  required LocalDataRepository repository,
  required SettingsController settingsController,
  required String category,
  required String itemId,
}) async {
  switch (category) {
    case 'skin':
    case 'knife':
    case 'gloves':
      final items = await repository.loadSkins();
      final skin = _firstWhereOrNull(items, (item) => item.id == itemId);
      if (skin == null) {
        return null;
      }
      return SkinDetailsScreen(
        repository: repository,
        settingsController: settingsController,
        skin: skin,
      );
    case 'sticker':
      final items = await repository.loadStickers();
      final sticker = _firstWhereOrNull(items, (item) => item.id == itemId);
      if (sticker == null) {
        return null;
      }
      return StickerDetailsScreen(repository: repository, sticker: sticker);
    case 'pin':
      final items = await repository.loadPins();
      final pin = _firstWhereOrNull(items, (item) => item.id == itemId);
      if (pin == null) {
        return null;
      }
      return PinDetailsScreen(repository: repository, pin: pin);
    case 'music_kit':
      final items = await repository.loadGroupedMusicKits();
      final group = _firstWhereOrNull(
        items,
        (item) => item.variants.any((variant) => variant.id == itemId),
      );
      if (group == null) {
        return null;
      }
      return MusicKitDetailsScreen(
        repository: repository,
        musicKitName: group.name,
        collection: group.collection,
      );
    case 'agent':
      final items = await repository.loadAgents();
      final agent = _firstWhereOrNull(items, (item) => item.id == itemId);
      if (agent == null) {
        return null;
      }
      return AgentDetailsScreen(repository: repository, agent: agent);
    case 'graffiti':
      final items = await repository.loadGraffiti();
      final graffiti = _firstWhereOrNull(items, (item) => item.id == itemId);
      if (graffiti == null) {
        return null;
      }
      return GraffitiDetailsScreen(repository: repository, graffiti: graffiti);
    case 'patch':
      final items = await repository.loadPatches();
      final patch = _firstWhereOrNull(items, (item) => item.id == itemId);
      if (patch == null) {
        return null;
      }
      return PatchDetailsScreen(repository: repository, patch: patch);
    case 'charm':
      final items = await repository.loadCharms();
      final charm = _firstWhereOrNull(items, (item) => item.id == itemId);
      if (charm == null) {
        return null;
      }
      return CharmDetailsScreen(repository: repository, charm: charm);
    default:
      return null;
  }
}

T? _firstWhereOrNull<T>(List<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}
