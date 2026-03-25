class ResponsiveGridHelper {
  static int listCrossAxisCount(double width) {
    if (width >= 1500) return 4;
    if (width >= 1100) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  static double listChildAspectRatio(double width) {
    if (width >= 1100) return 1.45;
    if (width >= 700) return 1.35;
    return 2.25;
  }

  static int skinGridCrossAxisCount(double width) {
    if (width >= 1500) return 6;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  static double skinGridChildAspectRatio(double width) {
    if (width >= 1200) return 0.82;
    if (width >= 900) return 0.78;
    if (width >= 600) return 0.74;
    return 0.7;
  }

  static int tradeGridCrossAxisCount(double width) {
    if (width > 1400) return 7;
    if (width > 1100) return 6;
    if (width > 800) return 5;
    if (width > 600) return 4;
    return 3;
  }
}