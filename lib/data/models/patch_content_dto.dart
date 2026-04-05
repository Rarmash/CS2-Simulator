class PatchContentDto {
  final String containerId;
  final List<String> patchIds;

  const PatchContentDto({required this.containerId, required this.patchIds});

  factory PatchContentDto.fromJson(Map<String, dynamic> json) {
    return PatchContentDto(
      containerId: json['containerId'] as String,
      patchIds: List<String>.from(json['patchIds'] as List<dynamic>),
    );
  }
}
