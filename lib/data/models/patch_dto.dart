class PatchDto {
  final String id;
  final String name;
  final String patchImage;
  final String rarity;
  final String? collection;

  const PatchDto({
    required this.id,
    required this.name,
    required this.patchImage,
    required this.rarity,
    required this.collection,
  });

  factory PatchDto.fromJson(Map<String, dynamic> json) {
    return PatchDto(
      id: json['id'] as String,
      name: json['name'] as String,
      patchImage: json['patchImage'] as String,
      rarity: json['rarity'] as String,
      collection: json['collection'] as String?,
    );
  }
}
