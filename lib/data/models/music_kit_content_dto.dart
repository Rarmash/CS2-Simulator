class MusicKitContentDto {
  final String caseId;
  final List<String> musicKitIds;

  const MusicKitContentDto({required this.caseId, required this.musicKitIds});

  factory MusicKitContentDto.fromJson(Map<String, dynamic> json) {
    return MusicKitContentDto(
      caseId: json['caseId'] as String,
      musicKitIds: List<String>.from(json['musicKitIds'] as List<dynamic>),
    );
  }
}
