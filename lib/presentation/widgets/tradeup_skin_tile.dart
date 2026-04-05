import 'package:flutter/material.dart';

import '../../data/models/skin_dto.dart';
import '../helpers/skin_ui_helper.dart';

class TradeUpSkinTile extends StatelessWidget {
  final SkinDto skin;
  final int selectedCount;
  final bool blocked;
  final VoidCallback? onTap;

  const TradeUpSkinTile({
    super.key,
    required this.skin,
    required this.selectedCount,
    required this.blocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = SkinUiHelper.rarityColor(skin);

    return Opacity(
      opacity: blocked ? 0.55 : 1,
      child: GestureDetector(
        onTap: blocked ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Center(
                        child: Image.asset(
                          skin.skinImage,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                  Container(height: 3, color: color),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Text(
                          skin.itemDisplayName,
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
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                        if (skin.collection != null &&
                            skin.collection!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            skin.collection!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (selectedCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'x$selectedCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
