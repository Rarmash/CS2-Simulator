import 'package:flutter/material.dart';

import '../../domain/tradeup_service.dart';
import '../helpers/skin_ui_helper.dart';

class TradeUpChanceCard extends StatelessWidget {
  final TradeUpChance chance;

  const TradeUpChanceCard({super.key, required this.chance});

  @override
  Widget build(BuildContext context) {
    final skin = chance.skin;
    final color = SkinUiHelper.rarityColor(skin);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                skin.skinImage,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          Container(height: 3, color: color),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Text(
                  SkinUiHelper.fullDropDisplayName(
                    skin: skin,
                    isStatTrak: chance.isStatTrak,
                    isSouvenir: chance.isSouvenir,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  skin.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(chance.probability * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chance.exterior,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Colors.white70),
                ),
                Text(
                  'FV ${chance.floatValue.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 9, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
