class GraffitiDto {
  final String id;
  final String name;
  final String graffitiImage;
  final String rarity;
  final String? collection;

  const GraffitiDto({
    required this.id,
    required this.name,
    required this.graffitiImage,
    required this.rarity,
    required this.collection,
  });

  factory GraffitiDto.fromJson(Map<String, dynamic> json) {
    return GraffitiDto(
      id: json['id'] as String,
      name: json['name'] as String,
      graffitiImage: json['graffitiImage'] as String,
      rarity: json['rarity'] as String,
      collection: json['collection'] as String?,
    );
  }
}
