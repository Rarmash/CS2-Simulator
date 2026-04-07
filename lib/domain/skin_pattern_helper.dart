import 'dart:math';

import '../data/models/skin_dto.dart';

class SkinPatternHelper {
  static const _seedDrivenFinishes = <String>{
    'CASE HARDENED',
    'CRIMSON WEB',
    'CROSSFADE',
    'FADE',
    'HEAT TREATED',
    'MARBLE FADE',
  };
  static const _phaseSplitFinishes = <String>{'DOPPLER', 'GAMMA DOPPLER'};

  static int? generateSeed({required Random random, required SkinDto skin}) {
    if (!supportsPatternSeed(skin)) {
      return null;
    }
    return random.nextInt(1000);
  }

  static bool supportsPatternSeed(SkinDto skin) {
    final finish = _normalizedFinish(skin);
    if (finish == null) {
      return skin.isSpecialItem;
    }

    return _seedDrivenFinishes.contains(finish) || skin.isSpecialItem;
  }

  static bool hasExplicitPhaseVariant(SkinDto skin) {
    final finish = _normalizedFinish(skin);
    if (finish == null) {
      return false;
    }

    return _phaseSplitFinishes.contains(finish) &&
        (skin.phase ?? '').trim().isNotEmpty;
  }

  static String? patternFamilyLabel(SkinDto skin) {
    final finish = _normalizedFinish(skin);
    if (finish == null) {
      return null;
    }

    return switch (finish) {
      'CASE HARDENED' => 'Case Hardened pattern',
      'CRIMSON WEB' => 'Web pattern',
      'CROSSFADE' || 'FADE' => 'Fade pattern',
      'HEAT TREATED' => 'Heat Treated pattern',
      'MARBLE FADE' => 'Marble Fade pattern',
      'DOPPLER' => 'Doppler phase',
      'GAMMA DOPPLER' => 'Gamma Doppler phase',
      _ => null,
    };
  }

  static String? describePattern({
    required SkinDto skin,
    required int? patternSeed,
  }) {
    if (hasExplicitPhaseVariant(skin)) {
      final phase = (skin.phase ?? '').trim();
      return phase.isEmpty ? null : phase;
    }

    if (patternSeed == null) {
      return null;
    }

    final finish = _normalizedFinish(skin);
    if (finish == null) {
      return 'Seed $patternSeed';
    }

    return switch (finish) {
      'CASE HARDENED' => _caseHardenedLabel(skin, patternSeed),
      'HEAT TREATED' => _heatTreatedLabel(patternSeed),
      'CRIMSON WEB' => _crimsonWebLabel(patternSeed),
      'FADE' ||
      'CROSSFADE' => 'Fade ${_fadePercent(patternSeed).toStringAsFixed(1)}%',
      'MARBLE FADE' =>
        'Marble Fade ${_fadePercent(patternSeed).toStringAsFixed(1)}%',
      _ => 'Seed $patternSeed',
    };
  }

  static String? describePatternMetric({
    required SkinDto skin,
    required int? patternSeed,
  }) {
    if (patternSeed == null || hasExplicitPhaseVariant(skin)) {
      return null;
    }

    final finish = _normalizedFinish(skin);
    if (finish == null) {
      return null;
    }

    return switch (finish) {
      'CASE HARDENED' =>
        'Blue coverage ${_caseHardenedBlueCoverage(skin, patternSeed).toStringAsFixed(1)}%',
      'HEAT TREATED' =>
        'Blue coverage ${_heatTreatedBlueCoverage(patternSeed).toStringAsFixed(1)}%',
      'CRIMSON WEB' =>
        'Web density ${_crimsonWebDensity(patternSeed).toStringAsFixed(1)}%',
      'FADE' || 'CROSSFADE' =>
        'Fade index ${_fadePercent(patternSeed).toStringAsFixed(1)}%',
      'MARBLE FADE' =>
        'Blend index ${_fadePercent(patternSeed).toStringAsFixed(1)}%',
      _ => null,
    };
  }

  static String? patternExplanation(SkinDto skin) {
    final finish = _normalizedFinish(skin);
    if (finish == null) {
      return skin.isSpecialItem
          ? 'Special items can carry finish-specific seed details.'
          : null;
    }

    return switch (finish) {
      'CASE HARDENED' =>
        'Pattern seed changes blue coverage and can produce rare Blue Gem-style layouts.',
      'HEAT TREATED' =>
        'Pattern seed changes blue coverage, with rare blue-heavy results at the top end.',
      'CRIMSON WEB' =>
        'Pattern seed changes how dense and visible the web pattern appears.',
      'FADE' || 'CROSSFADE' =>
        'Pattern seed controls fade percentage and how complete the fade coverage looks.',
      'MARBLE FADE' =>
        'Pattern seed changes the color blend balance across the finish.',
      'DOPPLER' =>
        'This finish uses weighted phase outcomes rather than equal odds for every variant.',
      'GAMMA DOPPLER' =>
        'This finish uses weighted phase outcomes, with Emerald kept rarer than standard phases.',
      _ =>
        skin.isSpecialItem
            ? 'Special items can carry finish-specific seed details.'
            : null,
    };
  }

  static List<String> possiblePatternOutcomes(SkinDto skin) {
    final finish = _normalizedFinish(skin);
    if (finish == null) {
      return const [];
    }

    return switch (finish) {
      'CASE HARDENED' => const [
        'Possible outcomes include Blue Gem, blue-heavy, gold-heavy, and purple-heavy patterns.',
        'Displayed pattern detail is driven by estimated blue coverage from the seed.',
      ],
      'HEAT TREATED' => const [
        'Possible outcomes include Blue Gem, blue-heavy, and purple-heavy patterns.',
        'Displayed pattern detail is driven by estimated blue coverage from the seed.',
      ],
      'CRIMSON WEB' => const [
        'Possible outcomes range from sparse to dense web layouts.',
        'Dense web patterns are presented as the rarer end of the finish.',
      ],
      'FADE' || 'CROSSFADE' => const [
        'Possible outcomes vary by fade percentage.',
        'Higher fade values indicate fuller fade coverage across the item.',
      ],
      'MARBLE FADE' => const [
        'Possible outcomes vary by blend balance.',
        'Exact gem-style seed mapping is not simulated separately yet.',
      ],
      'DOPPLER' => const [
        'Possible phases: Phase 1, Phase 2, Phase 3, Phase 4, Ruby, Sapphire, and Black Pearl.',
        'Ruby, Sapphire, and Black Pearl are weighted rarer than the standard phases.',
      ],
      'GAMMA DOPPLER' => const [
        'Possible phases: Phase 1, Phase 2, Phase 3, Phase 4, and Emerald.',
        'Emerald is weighted rarer than the standard phases.',
      ],
      _ => const [],
    };
  }

  static String? _normalizedFinish(SkinDto skin) {
    final finish = (skin.finishCatalogName ?? '').trim();
    if (finish.isEmpty) {
      return null;
    }
    return finish.toUpperCase();
  }

  static String _caseHardenedLabel(SkinDto skin, int seed) {
    final score = _normalizedHash(
      '${skin.itemId}|${skin.name}|case_hardened|$seed',
    );

    if (score >= 0.992) {
      return 'Blue Gem';
    }
    if (score >= 0.93) {
      return 'Blue-heavy pattern';
    }
    if (score >= 0.78) {
      return 'Gold-heavy pattern';
    }
    if (score <= 0.08) {
      return 'Purple-heavy pattern';
    }
    return 'Seed $seed';
  }

  static double _caseHardenedBlueCoverage(SkinDto skin, int seed) {
    return 100 *
        _normalizedHash('${skin.itemId}|${skin.name}|case_hardened|$seed');
  }

  static String _heatTreatedLabel(int seed) {
    final score = _normalizedHash('heat_treated|$seed');
    if (score >= 0.985) {
      return 'Blue Gem';
    }
    if (score >= 0.88) {
      return 'Blue-heavy pattern';
    }
    if (score >= 0.7) {
      return 'Purple-heavy pattern';
    }
    return 'Seed $seed';
  }

  static double _heatTreatedBlueCoverage(int seed) {
    return 100 * _normalizedHash('heat_treated|$seed');
  }

  static String _crimsonWebLabel(int seed) {
    final score = _normalizedHash('crimson_web|$seed');
    if (score >= 0.82) {
      return 'Dense web pattern';
    }
    if (score >= 0.42) {
      return 'Standard web pattern';
    }
    return 'Sparse web pattern';
  }

  static double _crimsonWebDensity(int seed) {
    return 100 * _normalizedHash('crimson_web|$seed');
  }

  static double _fadePercent(int seed) {
    return 100 * (1 - (seed / 999));
  }

  static double _normalizedHash(String input) {
    var hash = 2166136261;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return (hash % 1000000) / 1000000;
  }
}
