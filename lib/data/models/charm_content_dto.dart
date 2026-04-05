class CharmContentDto {
  final String containerId;
  final List<String> charmIds;

  const CharmContentDto({required this.containerId, required this.charmIds});

  factory CharmContentDto.fromJson(Map<String, dynamic> json) {
    return CharmContentDto(
      containerId: json['containerId'] as String,
      charmIds: List<String>.from(json['charmIds'] as List<dynamic>),
    );
  }
}
