class AgentDto {
  final String id;
  final String name;
  final String agentImage;
  final String rarity;
  final String? collection;
  final String team;

  const AgentDto({
    required this.id,
    required this.name,
    required this.agentImage,
    required this.rarity,
    required this.collection,
    required this.team,
  });

  factory AgentDto.fromJson(Map<String, dynamic> json) {
    return AgentDto(
      id: json['id'] as String,
      name: json['name'] as String,
      agentImage: json['agentImage'] as String,
      rarity: json['rarity'] as String,
      collection: json['collection'] as String?,
      team: (json['team'] as String?) ?? 'UNKNOWN',
    );
  }
}
