class TeamNameHelper {
  const TeamNameHelper._();

  static const Map<String, String> _aliases = {
    'complexity gaming': 'Complexity',
    'complexitygaming': 'Complexity',
    'gambit gaming': 'Gambit Esports',
    'gambit esports': 'Gambit Esports',
    'heroic': 'HEROIC',
    'mousesports': 'MOUZ',
    'team envy': 'Team EnVyUs',
  };

  static String canonicalize(String rawName) {
    final normalized = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return normalized;
    }

    final lower = normalized.toLowerCase();
    if (_aliases.containsKey(lower)) {
      return _aliases[lower]!;
    }

    return normalized;
  }
}
