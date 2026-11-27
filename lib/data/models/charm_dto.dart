class CharmDto {
  final String id;
  final String name;
  final String charmImage;
  final String rarity;
  final String? collection;

  final String? video, thumbnail, description, map, stage, player;

  const CharmDto({
    required this.id,
    required this.name,
    required this.charmImage,
    required this.rarity,
    required this.collection,
    this.video,
    this.thumbnail,
    this.description,
    this.map,
    this.stage,
    this.player,
  });

  factory CharmDto.fromJson(Map<String, dynamic> json) {
    return CharmDto(
      id: json['id'] as String,
      name: json['name'] as String,
      charmImage: json['charmImage'] as String,
      rarity: json['rarity'] as String,
      collection: json['collection'] as String?,
      video: json['video'] as String?,
      thumbnail: json['thumbnail'] as String?,
      description: json['description'] as String?,
      map: json['map'] as String?,
      stage: json['stage'] as String?,
      player: json['player'] as String?,
    );
  }
}
