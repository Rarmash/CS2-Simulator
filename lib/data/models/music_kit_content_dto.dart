class MusicKitContentEntryDto {
  final String musicKitId;
  final bool hasRegular;
  final bool hasStatTrak;

  const MusicKitContentEntryDto({
    required this.musicKitId,
    required this.hasRegular,
    required this.hasStatTrak,
  });

  factory MusicKitContentEntryDto.fromJson(Map<String, dynamic> json) {
    return MusicKitContentEntryDto(
      musicKitId: json['musicKitId'] as String,
      hasRegular: json['hasRegular'] as bool? ?? false,
      hasStatTrak: json['hasStatTrak'] as bool? ?? false,
    );
  }
}

class MusicKitContentDto {
  final String containerId;
  final List<MusicKitContentEntryDto> items;

  const MusicKitContentDto({required this.containerId, required this.items});

  factory MusicKitContentDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    if (rawItems is List) {
      return MusicKitContentDto(
        containerId: json['containerId'] as String,
        items: rawItems
            .whereType<Map>()
            .map(
              (item) => MusicKitContentEntryDto.fromJson(
                item.map((k, v) => MapEntry(k.toString(), v)),
              ),
            )
            .toList(),
      );
    }

    final legacyIds = List<String>.from(json['musicKitIds'] as List<dynamic>);
    return MusicKitContentDto(
      containerId: json['containerId'] as String,
      items: legacyIds
          .map(
            (id) => MusicKitContentEntryDto(
              musicKitId: id,
              hasRegular: true,
              hasStatTrak: false,
            ),
          )
          .toList(),
    );
  }
}
