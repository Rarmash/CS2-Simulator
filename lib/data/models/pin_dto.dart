class PinDto {
  final String id;
  final String name;
  final String pinImage;
  final String rarity;
  final String? collection;

  const PinDto({
    required this.id,
    required this.name,
    required this.pinImage,
    required this.rarity,
    required this.collection,
  });

  factory PinDto.fromJson(Map<String, dynamic> json) {
    return PinDto(
      id: json['id'] as String,
      name: json['name'] as String,
      pinImage: json['pinImage'] as String,
      rarity: json['rarity'] as String,
      collection: json['collection'] as String?,
    );
  }
}
