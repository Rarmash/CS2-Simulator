import 'package:flutter/material.dart';

import '../../domain/skin_float_helper.dart';
import '../../domain/tradeup_service.dart';
import '../helpers/skin_ui_helper.dart';

class TradeUpSelectedSlot extends StatelessWidget {
  final TradeUpInputItem? item;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const TradeUpSelectedSlot({
    super.key,
    required this.item,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Icon(Icons.add)),
      );
    }

    final skin = item!.skin;
    final color = SkinUiHelper.rarityColor(skin);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        skin.skinImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FV ${item!.floatValue.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 9, color: Colors.white70),
                  ),
                  Text(
                    _qualityLabel(item!.quality),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 8, color: Colors.white60),
                  ),
                  Text(
                    SkinFloatHelper.exteriorFromFloat(item!.floatValue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 8, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Material(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _qualityLabel(TradeUpInputQuality quality) {
    switch (quality) {
      case TradeUpInputQuality.regular:
        return 'Regular';
      case TradeUpInputQuality.statTrak:
        return 'StatTrak™';
      case TradeUpInputQuality.souvenir:
        return '';
    }
  }
}
