import 'package:flutter/material.dart';

import '../../domain/dropped_agent.dart';
import '../helpers/agent_ui_helper.dart';
import 'collectible_drop_card.dart';

class AgentDropCard extends StatelessWidget {
  final DroppedAgent drop;

  const AgentDropCard({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AgentUiHelper.rarityColor(drop.agent);
    final sideText = AgentUiHelper.secondaryText(drop.agent);

    return CollectibleDropCard(
      imagePath: drop.agent.agentImage,
      title: drop.agent.name,
      subtitle: sideText,
      accentColor: rarityColor,
      entries: [
        CollectibleInfoEntry(
          title: 'Rarity',
          value: AgentUiHelper.rarityLabel(drop.agent),
          valueColor: rarityColor,
        ),
        const CollectibleInfoEntry(title: 'Type', value: 'Agent'),
        CollectibleInfoEntry(title: 'Side', value: sideText),
        if ((drop.agent.collection ?? '').isNotEmpty)
          CollectibleInfoEntry(
            title: 'Collection',
            value: drop.agent.collection!,
          ),
      ],
    );
  }
}
