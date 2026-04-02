import 'dart:math';

class OpeningRollSequenceData<T> {
  final List<T> items;
  final int winnerIndex;

  const OpeningRollSequenceData({
    required this.items,
    required this.winnerIndex,
  });
}

class WeightedRollBucket<T> {
  final List<T> items;
  final double weight;

  const WeightedRollBucket({required this.items, required this.weight});
}

class OpeningRollSequenceBuilder {
  static OpeningRollSequenceData<T> build<T>({
    required Random random,
    required List<WeightedRollBucket<T>> realOddsBuckets,
    required List<WeightedRollBucket<T>> nearWinnerBuckets,
    required T winner,
    int preWinnerCount = 28,
    int bridgeCount = 3,
    int postWinnerCount = 8,
  }) {
    final sequence = <T>[];

    T pickRandom(List<T> items) {
      return items[random.nextInt(items.length)];
    }

    T pickFromBuckets(List<WeightedRollBucket<T>> buckets) {
      if (buckets.isEmpty) {
        throw Exception('No roll buckets available');
      }

      final totalWeight = buckets.fold<double>(
        0,
        (sum, bucket) => sum + bucket.weight,
      );
      final roll = random.nextDouble() * totalWeight;

      double cumulative = 0;
      for (final bucket in buckets) {
        cumulative += bucket.weight;
        if (roll <= cumulative) {
          return pickRandom(bucket.items);
        }
      }

      return pickRandom(buckets.last.items);
    }

    for (int i = 0; i < preWinnerCount; i++) {
      sequence.add(pickFromBuckets(realOddsBuckets));
    }

    sequence.add(pickFromBuckets(nearWinnerBuckets));

    for (int i = 1; i < bridgeCount; i++) {
      sequence.add(pickFromBuckets(realOddsBuckets));
    }

    final winnerIndex = sequence.length;
    sequence.add(winner);

    for (int i = 0; i < postWinnerCount; i++) {
      sequence.add(pickFromBuckets(realOddsBuckets));
    }

    return OpeningRollSequenceData<T>(
      items: sequence,
      winnerIndex: winnerIndex,
    );
  }
}
