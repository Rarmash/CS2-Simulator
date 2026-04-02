import 'dart:math';

import '../data/models/pin_dto.dart';
import 'dropped_pin.dart';

class PinSimulatorService {
  final Random _random = Random();

  DroppedPin openContainer({required List<PinDto> pins}) {
    if (pins.isEmpty) {
      throw Exception('No pins found for container');
    }

    final selectedPin = _selectPin(pins);
    return DroppedPin(pin: selectedPin);
  }

  PinDto _selectPin(List<PinDto> pins) {
    final availableBuckets = <_PinBucket>[];

    void addBucket(String rarity, double weight) {
      final bucketPins = pins.where((p) => p.rarity == rarity).toList();
      if (bucketPins.isNotEmpty) {
        availableBuckets.add(_PinBucket(pins: bucketPins, weight: weight));
      }
    }

    addBucket('HIGH_GRADE', 0.7992327);
    addBucket('REMARKABLE', 0.1598465);
    addBucket('EXOTIC', 0.0319693);
    addBucket('EXTRAORDINARY', 0.0089515);

    if (availableBuckets.isEmpty) {
      return pins[_random.nextInt(pins.length)];
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
        return bucket.pins[_random.nextInt(bucket.pins.length)];
      }
    }

    final fallback = availableBuckets.last.pins;
    return fallback[_random.nextInt(fallback.length)];
  }
}

class _PinBucket {
  final List<PinDto> pins;
  final double weight;

  const _PinBucket({required this.pins, required this.weight});
}
