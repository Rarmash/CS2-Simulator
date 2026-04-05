class StickerContentDto {
  final String containerId;
  final List<String> stickerIds;

  const StickerContentDto({
    required this.containerId,
    required this.stickerIds,
  });

  factory StickerContentDto.fromJson(Map<String, dynamic> json) {
    return StickerContentDto(
      containerId: json['containerId'] as String,
      stickerIds: (json['stickerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}
