import 'package:flutter/material.dart';

import '../../core/collection/collection_tracking_service.dart';

class CollectionSourceStatsWidget extends StatelessWidget {
  final String sourceName;
  final String sourceType;
  final CollectionTrackingService service;
  final int? totalCount;
  final bool compact;

  const CollectionSourceStatsWidget({
    super.key,
    required this.sourceName,
    required this.sourceType,
    required this.service,
    this.totalCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CollectionSourceStatsData>(
      future: _load(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        if (stats == null ||
            (stats.openedCount == 0 && stats.collectedUniqueCount == 0)) {
          return const SizedBox.shrink();
        }

        if (compact) {
          final progressText = totalCount == null
              ? 'Collected: ${stats.collectedUniqueCount}'
              : 'Progress: ${stats.collectedUniqueCount} / $totalCount';

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$progressText  •  Opened: ${stats.openedCount}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _StatPill(
                icon: Icons.local_mall_outlined,
                label: 'Opened',
                value: '${stats.openedCount}',
              ),
              _StatPill(
                icon: Icons.inventory_2_outlined,
                label: 'Collected',
                value: '${stats.collectedUniqueCount} unique',
              ),
              if (totalCount != null)
                _StatPill(
                  icon: Icons.checklist_outlined,
                  label: 'Progress',
                  value: '${stats.collectedUniqueCount} / $totalCount',
                ),
            ],
          ),
        );
      },
    );
  }

  Future<CollectionSourceStatsData> _load() async {
    final stats = await service.loadSourceStats(
      sourceName: sourceName,
      sourceType: sourceType,
    );
    return CollectionSourceStatsData(
      openedCount: stats.openedCount,
      collectedUniqueCount: stats.collectedUniqueCount,
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CollectionSourceStatsData {
  final int openedCount;
  final int collectedUniqueCount;

  const CollectionSourceStatsData({
    required this.openedCount,
    required this.collectedUniqueCount,
  });
}
