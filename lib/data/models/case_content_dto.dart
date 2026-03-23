class CaseContentDto {
  final String caseId;
  final List<String> skinIds;

  CaseContentDto({
    required this.caseId,
    required this.skinIds,
  });

  factory CaseContentDto.fromJson(Map<String, dynamic> json) {
    return CaseContentDto(
      caseId: json['caseId'] as String,
      skinIds: List<String>.from(json['skinIds'] as List),
    );
  }
}