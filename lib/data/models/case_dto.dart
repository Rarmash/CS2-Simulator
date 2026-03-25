class CaseDto {
  final String id;
  final String name;
  final String caseImage;
  final String? releaseDate;
  final String type;

  CaseDto({
    required this.id,
    required this.name,
    required this.caseImage,
    required this.releaseDate,
    required this.type,
  });

  factory CaseDto.fromJson(Map<String, dynamic> json) {
    return CaseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      caseImage: json['caseImage'] as String,
      releaseDate: json['releaseDate'] as String?,
      type: (json['type'] as String?) ?? 'CASE',
    );
  }

  bool get isRegularCase => type == 'CASE';
  bool get isSouvenirPackage => type == 'SOUVENIR_PACKAGE';
  bool get isCollectionPackage => type == 'COLLECTION_PACKAGE';
  bool get isXrayPackage => type == 'XRAY_PACKAGE';
  bool get isTerminal => type == 'TERMINAL';

  String get typeLabel {
    switch (type) {
      case 'CASE':
        return 'Case';
      case 'SOUVENIR_PACKAGE':
        return 'Souvenir Package';
      case 'COLLECTION_PACKAGE':
        return 'Collection Package';
      case 'XRAY_PACKAGE':
        return 'X-Ray Package';
      case 'TERMINAL':
        return 'Terminal';
      default:
        return type;
    }
  }
}