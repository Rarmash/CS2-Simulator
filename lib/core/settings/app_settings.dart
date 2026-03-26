class AppSettings {
  final bool xrayOpeningEnabled;

  const AppSettings({
    this.xrayOpeningEnabled = false,
  });

  AppSettings copyWith({
    bool? xrayOpeningEnabled,
  }) {
    return AppSettings(
      xrayOpeningEnabled: xrayOpeningEnabled ?? this.xrayOpeningEnabled,
    );
  }
}