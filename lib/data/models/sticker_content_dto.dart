class StickerContentDto {
  final String caseId;
  final List<String> stickerIds;

  const StickerContentDto({required this.caseId, required this.stickerIds});

  factory StickerContentDto.fromJson(Map<String, dynamic> json) {
    return StickerContentDto(
      caseId: json['caseId'] as String,
      stickerIds: (json['stickerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}
