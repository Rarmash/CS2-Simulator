class CollectionEntry {
  final String entryId;
  final String category;
  final String filterCategory;
  final String itemId;
  final String stackKey;
  final String title;
  final String subtitle;
  final String imagePath;
  final String rarity;
  final String sourceName;
  final String sourceType;
  final DateTime acquiredAt;
  final bool isStatTrak;
  final bool isSouvenir;
  final double? floatValue;
  final String? exterior;
  final int? patternSeed;

  const CollectionEntry({
    required this.entryId,
    required this.category,
    required this.filterCategory,
    required this.itemId,
    required this.stackKey,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.rarity,
    required this.sourceName,
    required this.sourceType,
    required this.acquiredAt,
    required this.isStatTrak,
    required this.isSouvenir,
    required this.floatValue,
    required this.exterior,
    required this.patternSeed,
  });

  factory CollectionEntry.fromJson(Map<String, dynamic> json) {
    return CollectionEntry(
      entryId: json['entryId'] as String,
      category: json['category'] as String,
      filterCategory:
          (json['filterCategory'] as String?) ?? (json['category'] as String),
      itemId: json['itemId'] as String,
      stackKey: json['stackKey'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imagePath: json['imagePath'] as String,
      rarity: json['rarity'] as String,
      sourceName: json['sourceName'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      acquiredAt: DateTime.parse(json['acquiredAt'] as String),
      isStatTrak: json['isStatTrak'] as bool? ?? false,
      isSouvenir: json['isSouvenir'] as bool? ?? false,
      floatValue: (json['floatValue'] as num?)?.toDouble(),
      exterior: json['exterior'] as String?,
      patternSeed: json['patternSeed'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'category': category,
      'filterCategory': filterCategory,
      'itemId': itemId,
      'stackKey': stackKey,
      'title': title,
      'subtitle': subtitle,
      'imagePath': imagePath,
      'rarity': rarity,
      'sourceName': sourceName,
      'sourceType': sourceType,
      'acquiredAt': acquiredAt.toIso8601String(),
      'isStatTrak': isStatTrak,
      'isSouvenir': isSouvenir,
      'floatValue': floatValue,
      'exterior': exterior,
      'patternSeed': patternSeed,
    };
  }
}
