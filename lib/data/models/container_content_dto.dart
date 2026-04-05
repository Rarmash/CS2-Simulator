class ContainerContentDto {
  final String containerId;
  final List<String> skinIds;

  ContainerContentDto({required this.containerId, required this.skinIds});

  factory ContainerContentDto.fromJson(Map<String, dynamic> json) {
    return ContainerContentDto(
      containerId: json['containerId'] as String,
      skinIds: List<String>.from(json['skinIds'] as List),
    );
  }
}
