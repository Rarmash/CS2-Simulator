import 'dart:math';

import '../data/models/sticker_dto.dart';
import 'dropped_sticker.dart';

class StickerSimulatorService {
  final Random _random = Random();

  DroppedSticker openContainer({required List<StickerDto> stickers}) {
    if (stickers.isEmpty) {
      throw Exception('No stickers found for container');
    }

    final selectedSticker = _selectSticker(stickers);
    return DroppedSticker(sticker: selectedSticker);
  }

  StickerDto _selectSticker(List<StickerDto> stickers) {
    final availableBuckets = <_StickerBucket>[];

    void addBucket(String rarity, double weight) {
      final bucketStickers = stickers.where((s) => s.rarity == rarity).toList();
      if (bucketStickers.isNotEmpty) {
        availableBuckets.add(
          _StickerBucket(stickers: bucketStickers, weight: weight),
        );
      }
    }

    addBucket('HIGH_GRADE', 0.80);
    addBucket('REMARKABLE', 0.16);
    addBucket('EXOTIC', 0.032);
    addBucket('EXTRAORDINARY', 0.00641);
    addBucket('CONTRABAND', 0.00159);

    if (availableBuckets.isEmpty) {
      return stickers[_random.nextInt(stickers.length)];
    }

    final totalWeight = availableBuckets.fold<double>(
      0,
      (sum, bucket) => sum + bucket.weight,
    );
    final roll = _random.nextDouble() * totalWeight;

    double cumulative = 0;
    for (final bucket in availableBuckets) {
      cumulative += bucket.weight;
      if (roll <= cumulative) {
        return bucket.stickers[_random.nextInt(bucket.stickers.length)];
      }
    }

    final fallback = availableBuckets.last.stickers;
    return fallback[_random.nextInt(fallback.length)];
  }
}

class _StickerBucket {
  final List<StickerDto> stickers;
  final double weight;

  const _StickerBucket({required this.stickers, required this.weight});
}
