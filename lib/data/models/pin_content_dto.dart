class PinContentDto {
  final String caseId;
  final List<String> pinIds;

  const PinContentDto({required this.caseId, required this.pinIds});

  factory PinContentDto.fromJson(Map<String, dynamic> json) {
    return PinContentDto(
      caseId: json['caseId'] as String,
      pinIds: List<String>.from(json['pinIds'] as List<dynamic>),
    );
  }
}
