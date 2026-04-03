class GraffitiContentDto {
  final String caseId;
  final List<String> graffitiIds;

  const GraffitiContentDto({
    required this.caseId,
    required this.graffitiIds,
  });

  factory GraffitiContentDto.fromJson(Map<String, dynamic> json) {
    return GraffitiContentDto(
      caseId: json['caseId'] as String,
      graffitiIds: List<String>.from(json['graffitiIds'] as List<dynamic>),
    );
  }
}
