import 'dart:math';

class WearFloatResult {
  final double? floatValue;
  final String? exterior;

  const WearFloatResult({required this.floatValue, required this.exterior});
}

class _WearTier {
  final String label;
  final double min;
  final double max;
  final double weight;

  const _WearTier({
    required this.label,
    required this.min,
    required this.max,
    required this.weight,
  });
}

class SkinFloatHelper {
  static const List<_WearTier> _wearTiers = [
    _WearTier(label: 'Factory New', min: 0.00, max: 0.07, weight: 0.03),
    _WearTier(label: 'Minimal Wear', min: 0.07, max: 0.15, weight: 0.24),
    _WearTier(label: 'Field-Tested', min: 0.15, max: 0.38, weight: 0.33),
    _WearTier(label: 'Well-Worn', min: 0.38, max: 0.45, weight: 0.24),
    _WearTier(label: 'Battle-Scarred', min: 0.45, max: 1.00, weight: 0.16),
  ];

  static WearFloatResult generateWear({
    required Random random,
    required double minFloat,
    required double maxFloat,
  }) {
    final clampedMin = minFloat.clamp(0.0, 1.0);
    final clampedMax = maxFloat.clamp(0.0, 1.0);

    if (clampedMax <= clampedMin) {
      return WearFloatResult(
        floatValue: clampedMin.toDouble(),
        exterior: exteriorFromFloat(clampedMin.toDouble()),
      );
    }

    final availableTiers = _wearTiers
        .map((tier) {
          final intersectionMin = max(clampedMin.toDouble(), tier.min);
          final intersectionMax = min(clampedMax.toDouble(), tier.max);
          final available = intersectionMax - intersectionMin;
          if (available <= 0) return null;
          final tierSpan = tier.max - tier.min;
          final effectiveWeight = tierSpan <= 0
              ? 0.0
              : tier.weight * (available / tierSpan);
          return (
            effectiveWeight: effectiveWeight,
            tier: tier,
            min: intersectionMin,
            max: intersectionMax,
          );
        })
        .whereType<
          ({double effectiveWeight, double max, double min, _WearTier tier})
        >()
        .where((entry) => entry.effectiveWeight > 0)
        .toList();

    if (availableTiers.isEmpty) {
      final fallback = clampedMin.toDouble();
      return WearFloatResult(
        floatValue: fallback,
        exterior: exteriorFromFloat(fallback),
      );
    }

    final totalWeight = availableTiers
        .map((entry) => entry.effectiveWeight)
        .reduce((a, b) => a + b);

    var roll = random.nextDouble() * totalWeight;
    var selected = availableTiers.first;

    for (final entry in availableTiers) {
      roll -= entry.effectiveWeight;
      if (roll <= 0) {
        selected = entry;
        break;
      }
    }

    final floatValue =
        selected.min + random.nextDouble() * (selected.max - selected.min);

    return WearFloatResult(
      floatValue: floatValue,
      exterior: selected.tier.label,
    );
  }

  static String exteriorFromFloat(double value) {
    if (value <= 0.07) return 'Factory New';
    if (value <= 0.15) return 'Minimal Wear';
    if (value <= 0.38) return 'Field-Tested';
    if (value <= 0.45) return 'Well-Worn';
    return 'Battle-Scarred';
  }
}
