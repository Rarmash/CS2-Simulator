class PatchContentDto {
  final String caseId;
  final List<String> patchIds;

  const PatchContentDto({
    required this.caseId,
    required this.patchIds,
  });

  factory PatchContentDto.fromJson(Map<String, dynamic> json) {
    return PatchContentDto(
      caseId: json['caseId'] as String,
      patchIds: List<String>.from(json['patchIds'] as List<dynamic>),
    );
  }
}
