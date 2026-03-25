class OperationCollectionDto {
  final String id;
  final String name;
  final String image;
  final String operationId;
  final String operationName;
  final String? releaseDate;

  OperationCollectionDto({
    required this.id,
    required this.name,
    required this.image,
    required this.operationId,
    required this.operationName,
    required this.releaseDate,
  });

  factory OperationCollectionDto.fromJson(Map<String, dynamic> json) {
    return OperationCollectionDto(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      operationId: json['operationId'] as String,
      operationName: json['operationName'] as String,
      releaseDate: json['releaseDate'] as String?,
    );
  }

  String get operationLabel => operationName;
}