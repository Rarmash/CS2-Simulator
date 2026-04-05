class PinContentDto {
  final String containerId;
  final List<String> pinIds;

  const PinContentDto({required this.containerId, required this.pinIds});

  factory PinContentDto.fromJson(Map<String, dynamic> json) {
    return PinContentDto(
      containerId: json['containerId'] as String,
      pinIds: List<String>.from(json['pinIds'] as List<dynamic>),
    );
  }
}
