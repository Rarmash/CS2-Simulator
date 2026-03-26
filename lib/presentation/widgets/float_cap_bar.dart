import 'dart:math' as math;

import 'package:flutter/material.dart';

class FloatCapBar extends StatelessWidget {
  final double minFloat;
  final double maxFloat;
  final double barHeight;

  const FloatCapBar({
    super.key,
    required this.minFloat,
    required this.maxFloat,
    this.barHeight = 34,
  });

  static const List<_WearBand> _bands = [
    _WearBand('FN', 0.00, 0.07, Color(0xFF727881)),
    _WearBand('MW', 0.07, 0.15, Color(0xFF656B74)),
    _WearBand('FT', 0.15, 0.38, Color(0xFF575D66)),
    _WearBand('WW', 0.38, 0.45, Color(0xFF474D56)),
    _WearBand('BS', 0.45, 1.00, Color(0xFF3B4048)),
  ];

  @override
  Widget build(BuildContext context) {
    final safeMin = minFloat.clamp(0.0, 1.0);
    final safeMax = maxFloat.clamp(0.0, 1.0);
    final start = math.min(safeMin, safeMax);
    final end = math.max(safeMin, safeMax);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final startX = width * start;
        final endX = width * end;

        return SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: _labelLeft(startX, width),
                child: _FloatTopLabel(value: start),
              ),
              Positioned(
                top: 0,
                left: _labelLeft(endX, width),
                child: _FloatTopLabel(value: end),
              ),
              Positioned(
                top: 22,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Positioned(
                            left: startX - 5,
                            top: 0,
                            child: const _PointerTriangle(),
                          ),
                          Positioned(
                            left: endX - 5,
                            top: 0,
                            child: const _PointerTriangle(),
                          ),
                          Positioned(
                            left: startX,
                            right: width - endX,
                            top: 2,
                            child: Container(
                              height: 3,
                              color: const Color(0xFFFF5A4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3138),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: Row(
                        children: _bands.map((band) {
                          return Expanded(
                            flex: ((band.end - band.start) * 1000).round(),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: band.color,
                                border: const Border(
                                  right: BorderSide(
                                    color: Colors.black26,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                band.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _labelLeft(double pointX, double totalWidth) {
    const labelWidth = 42.0;
    final raw = pointX - (labelWidth / 2);
    return raw.clamp(0.0, math.max(0.0, totalWidth - labelWidth));
  }
}

class _FloatTopLabel extends StatelessWidget {
  final double value;

  const _FloatTopLabel({
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Text(
        value.toStringAsFixed(2),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _PointerTriangle extends StatelessWidget {
  const _PointerTriangle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(10, 8),
      painter: _TrianglePainter(),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF5A4F)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WearBand {
  final String label;
  final double start;
  final double end;
  final Color color;

  const _WearBand(this.label, this.start, this.end, this.color);
}