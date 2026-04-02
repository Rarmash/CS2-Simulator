class MusicKitDto {
  final String id;
  final String name;
  final String musicKitImage;
  final String rarity;
  final String? collection;
  final bool isStatTrak;

  const MusicKitDto({
    required this.id,
    required this.name,
    required this.musicKitImage,
    required this.rarity,
    required this.collection,
    required this.isStatTrak,
  });

  factory MusicKitDto.fromJson(Map<String, dynamic> json) {
    return MusicKitDto(
      id: json['id'] as String,
      name: json['name'] as String,
      musicKitImage: json['musicKitImage'] as String,
      rarity: json['rarity'] as String,
      collection: json['collection'] as String?,
      isStatTrak: json['isStatTrak'] as bool? ?? false,
    );
  }

  String get displayName {
    return isStatTrak ? 'StatTrak™ $name' : name;
  }
}
