import 'collection_entry.dart';

class CollectionSummary {
  final String stackKey;
  final String category;
  final String filterCategory;
  final String title;
  final String subtitle;
  final String imagePath;
  final String rarity;
  final int count;
  final DateTime latestAcquiredAt;
  final double? bestFloat;
  final bool hasStatTrak;
  final bool hasSouvenir;
  final CollectionEntry latestEntry;

  const CollectionSummary({
    required this.stackKey,
    required this.category,
    required this.filterCategory,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.rarity,
    required this.count,
    required this.latestAcquiredAt,
    required this.bestFloat,
    required this.hasStatTrak,
    required this.hasSouvenir,
    required this.latestEntry,
  });
}
