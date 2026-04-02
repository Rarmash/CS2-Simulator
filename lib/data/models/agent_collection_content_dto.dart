class AgentCollectionContentDto {
  final String agentCollectionId;
  final List<String> agentIds;

  const AgentCollectionContentDto({
    required this.agentCollectionId,
    required this.agentIds,
  });

  factory AgentCollectionContentDto.fromJson(Map<String, dynamic> json) {
    return AgentCollectionContentDto(
      agentCollectionId: json['agentCollectionId'] as String,
      agentIds: List<String>.from(json['agentIds'] as List<dynamic>),
    );
  }
}
