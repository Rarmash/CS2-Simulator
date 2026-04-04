class MusicKitDto {
  final String id;
  final String name;
  final String musicKitImage;
  final String rarity;
  final String? collection;
  final bool hasRegular;
  final bool hasStatTrak;

  const MusicKitDto({
    required this.id,
    required this.name,
    required this.musicKitImage,
    required this.rarity,
    required this.collection,
    required this.hasRegular,
    required this.hasStatTrak,
  });

  factory MusicKitDto.fromJson(Map<String, dynamic> json) {
    final legacyIsStatTrak = json['isStatTrak'] as bool? ?? false;
    return MusicKitDto(
      id: json['id'] as String,
      name: json['name'] as String,
      musicKitImage: json['musicKitImage'] as String,
      rarity: json['rarity'] as String,
      collection: json['collection'] as String?,
      hasRegular: json['hasRegular'] as bool? ?? !legacyIsStatTrak,
      hasStatTrak: json['hasStatTrak'] as bool? ?? legacyIsStatTrak,
    );
  }

  MusicKitDto copyWith({
    String? id,
    String? name,
    String? musicKitImage,
    String? rarity,
    String? collection,
    bool? hasRegular,
    bool? hasStatTrak,
  }) {
    return MusicKitDto(
      id: id ?? this.id,
      name: name ?? this.name,
      musicKitImage: musicKitImage ?? this.musicKitImage,
      rarity: rarity ?? this.rarity,
      collection: collection ?? this.collection,
      hasRegular: hasRegular ?? this.hasRegular,
      hasStatTrak: hasStatTrak ?? this.hasStatTrak,
    );
  }

  String? get artist {
    final index = name.indexOf(', ');
    if (index <= 0) return null;
    return name.substring(0, index).trim();
  }

  String get trackName {
    final index = name.indexOf(', ');
    if (index <= 0 || index + 2 >= name.length) return name;
    return name.substring(index + 2).trim();
  }

  String get displayName {
    if (hasStatTrak && !hasRegular) {
      return 'StatTrak™ $name';
    }
    return name;
  }
}
