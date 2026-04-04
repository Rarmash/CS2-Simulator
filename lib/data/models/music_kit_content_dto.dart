class MusicKitContentDto {
  final String containerId;
  final List<String> musicKitIds;

  const MusicKitContentDto({
    required this.containerId,
    required this.musicKitIds,
  });

  factory MusicKitContentDto.fromJson(Map<String, dynamic> json) {
    return MusicKitContentDto(
      containerId: json['containerId'] as String,
      musicKitIds: List<String>.from(json['musicKitIds'] as List<dynamic>),
    );
  }
}
