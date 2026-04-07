import 'package:flutter/material.dart';

import '../../domain/terminal_offer.dart';
import '../../domain/skin_pattern_helper.dart';
import '../helpers/skin_ui_helper.dart';
import 'hold_to_confirm_button.dart';
import 'info_row.dart';

class TerminalOfferCard extends StatelessWidget {
  final TerminalOffer offer;
  final int totalOffers;
  final Future<void> Function() onSkip;
  final Future<void> Function() onAccept;

  const TerminalOfferCard({
    super.key,
    required this.offer,
    required this.totalOffers,
    required this.onSkip,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = SkinUiHelper.rarityColor(offer.skin);
    final patternSummary = SkinPatternHelper.describePattern(
      skin: offer.skin,
      patternSeed: offer.patternSeed,
    );
    final patternMetric = SkinPatternHelper.describePatternMetric(
      skin: offer.skin,
      patternSeed: offer.patternSeed,
    );
    final patternFamily = SkinPatternHelper.patternFamilyLabel(offer.skin);

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: rarityColor, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Offer ${offer.offerIndex} / $totalOffers',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Image.asset(
              offer.skin.skinImage,
              height: 140,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.image_not_supported, size: 72),
            ),
            const SizedBox(height: 12),
            Text(
              "${offer.isStatTrak ? 'StatTrak™ ' : ''}${offer.skin.itemDisplayName} | ${offer.skin.name}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: rarityColor,
              ),
            ),
            if (offer.skin.displayVariant != null) ...[
              const SizedBox(height: 6),
              Text(
                offer.skin.displayVariant!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const SizedBox(height: 10),
            InfoRow(
              title: 'Rarity',
              value: SkinUiHelper.rarityLabel(offer.skin),
              valueColor: rarityColor,
            ),
            InfoRow(
              title: 'Weapon type',
              value: SkinUiHelper.weaponTypeLabel(offer.skin.weaponType),
            ),
            InfoRow(title: 'Item', value: offer.skin.itemDisplayName),
            InfoRow(title: 'StatTrak', value: offer.isStatTrak ? 'Yes' : 'No'),
            InfoRow(
              title: 'Float',
              value: offer.skinFloat?.toStringAsFixed(6) ?? '-',
            ),
            InfoRow(title: 'Exterior', value: offer.exterior ?? '-'),
            if ((offer.skin.phase ?? '').trim().isNotEmpty)
              InfoRow(title: 'Phase', value: offer.skin.phase!.trim()),
            if (offer.patternSeed != null)
              InfoRow(
                title: 'Pattern seed',
                value: offer.patternSeed.toString(),
              ),
            if (patternFamily != null)
              InfoRow(title: 'Pattern family', value: patternFamily),
            if (patternSummary != null)
              InfoRow(title: 'Pattern', value: patternSummary),
            if (patternMetric != null)
              InfoRow(title: 'Pattern detail', value: patternMetric),
            if (offer.skin.collection != null &&
                offer.skin.collection!.isNotEmpty)
              InfoRow(title: 'Collection', value: offer.skin.collection!),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: HoldToConfirmButton(
                    label: 'SKIP OFFER',
                    duration: const Duration(milliseconds: 950),
                    onCompleted: onSkip,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HoldToConfirmButton(
                    label: 'TAKE OFFER',
                    duration: const Duration(milliseconds: 950),
                    onCompleted: onAccept,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
