import 'package:flutter/material.dart';

import '../../data/models/agent_dto.dart';

class AgentUiHelper {
  static const Color _blue = Color(0xFF4B69FF);
  static const Color _purple = Color(0xFF8847FF);
  static const Color _pink = Color(0xFFD32CE6);
  static const Color _red = Color(0xFFEB4B4B);

  static Color rarityColor(AgentDto agent) {
    switch (agent.rarity) {
      case 'EXCEPTIONAL':
        return _purple;
      case 'SUPERIOR':
        return _pink;
      case 'MASTER':
        return _red;
      case 'DISTINGUISHED':
      default:
        return _blue;
    }
  }

  static String rarityLabel(AgentDto agent) {
    switch (agent.rarity) {
      case 'DISTINGUISHED':
        return 'Distinguished';
      case 'EXCEPTIONAL':
        return 'Exceptional';
      case 'SUPERIOR':
        return 'Superior';
      case 'MASTER':
        return 'Master';
      default:
        return agent.rarity;
    }
  }

  static String secondaryText(AgentDto agent) {
    return switch (agent.team) {
      'TERRORIST' => 'T Side',
      'COUNTER-TERRORIST' => 'CT Side',
      _ => agent.collection ?? 'Agent',
    };
  }
}
