class CharmDto {
  final String id;
  final String name;
  final String charmImage;
  final String rarity;
  final String? collection;

  const CharmDto({
    required this.id,
    required this.name,
    required this.charmImage,
    required this.rarity,
    required this.collection,
  });

  factory CharmDto.fromJson(Map<String, dynamic> json) {
    return CharmDto(
      id: json['id'] as String,
      name: json['name'] as String,
      charmImage: json['charmImage'] as String,
      rarity: json['rarity'] as String,
      collection: json['collection'] as String?,
    );
  }
}
