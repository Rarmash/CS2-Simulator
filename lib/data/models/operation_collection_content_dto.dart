class OperationCollectionContentDto {
  final String operationCollectionId;
  final List<String> skinIds;

  OperationCollectionContentDto({
    required this.operationCollectionId,
    required this.skinIds,
  });

  factory OperationCollectionContentDto.fromJson(Map<String, dynamic> json) {
    return OperationCollectionContentDto(
      operationCollectionId: json['operationCollectionId'] as String,
      skinIds: List<String>.from(json['skinIds'] as List),
    );
  }
}