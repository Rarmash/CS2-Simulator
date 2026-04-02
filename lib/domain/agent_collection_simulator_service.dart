import 'dart:math';

import '../data/models/agent_collection_dto.dart';
import '../data/models/agent_dto.dart';
import 'dropped_agent.dart';

class AgentCollectionSimulatorService {
  final Random _random = Random();

  DroppedAgent openCollection({
    required List<AgentDto> agents,
    required AgentCollectionDto collection,
  }) {
    if (agents.isEmpty) {
      throw Exception('No agents found for agent collection');
    }

    final selectedAgent = _selectAgent(agents);
    return DroppedAgent(agent: selectedAgent);
  }

  AgentDto _selectAgent(List<AgentDto> agents) {
    final roll = _random.nextDouble();
    final rarity = switch (roll) {
      <= 0.80 => 'DISTINGUISHED',
      <= 0.96 => 'EXCEPTIONAL',
      <= 0.992 => 'SUPERIOR',
      _ => 'MASTER',
    };

    final filtered = agents.where((a) => a.rarity == rarity).toList();
    final pool = filtered.isEmpty ? agents : filtered;
    return pool[_random.nextInt(pool.length)];
  }
}
