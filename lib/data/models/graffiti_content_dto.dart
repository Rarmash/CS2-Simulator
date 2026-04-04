class GraffitiContentDto {
  final String containerId;
  final List<String> graffitiIds;

  const GraffitiContentDto({
    required this.containerId,
    required this.graffitiIds,
  });

  factory GraffitiContentDto.fromJson(Map<String, dynamic> json) {
    return GraffitiContentDto(
      containerId: json['containerId'] as String,
      graffitiIds: List<String>.from(json['graffitiIds'] as List<dynamic>),
    );
  }
}
