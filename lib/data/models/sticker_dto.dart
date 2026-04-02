class StickerDto {
  final String id;
  final String name;
  final String stickerImage;
  final String rarity;
  final String stickerType;
  final String effect;
  final String? collection;
  final String? tournament;

  const StickerDto({
    required this.id,
    required this.name,
    required this.stickerImage,
    required this.rarity,
    required this.stickerType,
    required this.effect,
    required this.collection,
    required this.tournament,
  });

  factory StickerDto.fromJson(Map<String, dynamic> json) {
    return StickerDto(
      id: json['id'] as String,
      name: json['name'] as String,
      stickerImage: json['stickerImage'] as String,
      rarity: json['rarity'] as String,
      stickerType: json['stickerType'] as String,
      effect: json['effect'] as String,
      collection: json['collection'] as String?,
      tournament: json['tournament'] as String?,
    );
  }

  String get sourceLabel {
    if ((collection ?? '').isNotEmpty) {
      return collection!;
    }
    if ((tournament ?? '').isNotEmpty) {
      return tournament!;
    }
    return stickerTypeLabel;
  }

  String get stickerTypeLabel {
    switch (stickerType) {
      case 'AUTOGRAPH':
        return 'Autograph';
      case 'EVENT':
        return 'Event';
      default:
        return 'Sticker';
    }
  }
}
