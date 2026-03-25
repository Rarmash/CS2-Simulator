class RewardCollectionContentDto {
  final String rewardCollectionId;
  final List<String> skinIds;

  RewardCollectionContentDto({
    required this.rewardCollectionId,
    required this.skinIds,
  });

  factory RewardCollectionContentDto.fromJson(Map<String, dynamic> json) {
    return RewardCollectionContentDto(
      rewardCollectionId: json['rewardCollectionId'] as String,
      skinIds: List<String>.from(json['skinIds'] as List),
    );
  }
}