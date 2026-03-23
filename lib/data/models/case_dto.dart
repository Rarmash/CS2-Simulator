class CaseDto {
  final String id;
  final String name;
  final String caseImage;
  final String? releaseDate;

  CaseDto({
    required this.id,
    required this.name,
    required this.caseImage,
    required this.releaseDate,
  });

  factory CaseDto.fromJson(Map<String, dynamic> json) {
    return CaseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      caseImage: json['caseImage'] as String,
      releaseDate: json['releaseDate'] as String?,
    );
  }
}