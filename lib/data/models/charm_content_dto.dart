class CharmContentDto {
  final String caseId;
  final List<String> charmIds;

  const CharmContentDto({required this.caseId, required this.charmIds});

  factory CharmContentDto.fromJson(Map<String, dynamic> json) {
    return CharmContentDto(
      caseId: json['caseId'] as String,
      charmIds: List<String>.from(json['charmIds'] as List<dynamic>),
    );
  }
}
