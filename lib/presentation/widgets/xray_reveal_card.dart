import 'package:flutter/material.dart';

import '../../domain/dropped_skin.dart';
import '../helpers/skin_ui_helper.dart';
import 'info_row.dart';

class XrayRevealCard extends StatefulWidget {
  final DroppedSkin drop;
  final VoidCallback onClaim;
  final VoidCallback onDestroy;

  const XrayRevealCard({
    super.key,
    required this.drop,
    required this.onClaim,
    required this.onDestroy,
  });

  @override
  State<XrayRevealCard> createState() => _XrayRevealCardState();
}

class _XrayRevealCardState extends State<XrayRevealCard>
    with SingleTickerProviderStateMixin {
  static const double _scanViewportHeight = 270;
  static const double _skinRenderHeight = 188;

  static const Duration _scanDuration = Duration(milliseconds: 5000);
  static const Duration _detailsFadeDuration = Duration(milliseconds: 280);

  late final AnimationController _controller;
  bool _scanCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _scanDuration,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _scanCompleted = true;
        });
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fullName() {
    final d = widget.drop;
    final statTrak = d.isStatTrak ? 'StatTrak™ ' : '';
    return '$statTrak${d.skin.itemDisplayName} | ${d.skin.name}';
  }

  Widget _buildFixedSkinImage() {
    return IgnorePointer(
      child: Center(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFF7EFFF0),
            BlendMode.modulate,
          ),
          child: Image.asset(
            widget.drop.skin.skinImage,
            fit: BoxFit.contain,
            height: _skinRenderHeight,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 72),
          ),
        ),
      ),
    );
  }

  Widget _buildScanViewport() {
    const xrayGlow = Color(0xFF78FFF0);
    const xrayBg = Color(0xFF041016);
    const xrayBg2 = Color(0xFF071A21);
    const maskColor = Color(0xFF051118);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value.clamp(0.0, 1.0);
        final scanY = _scanViewportHeight * progress;
        final unrevealedTop = scanY.clamp(0.0, _scanViewportHeight);
        final unrevealedHeight =
        (_scanViewportHeight - unrevealedTop).clamp(0.0, _scanViewportHeight);
        final lineTop = (scanY - 1).clamp(0.0, _scanViewportHeight - 2);

        return Container(
          height: _scanViewportHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: xrayGlow.withOpacity(0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: xrayGlow.withOpacity(0.16),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                xrayBg2,
                xrayBg,
              ],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(
                child: _XrayGridOverlay(),
              ),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.05,
                      colors: [
                        Colors.transparent,
                        xrayGlow.withOpacity(0.03),
                        Colors.black.withOpacity(0.18),
                      ],
                      stops: const [0.0, 0.72, 1.0],
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: _buildFixedSkinImage(),
              ),

              if (unrevealedHeight > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: unrevealedTop,
                  height: unrevealedHeight,
                  child: Container(
                    color: maskColor,
                  ),
                ),

              // Дополнительная маска-градиент около линии скана.
              Positioned(
                left: 0,
                right: 0,
                top: (lineTop - 42).clamp(0.0, _scanViewportHeight),
                child: IgnorePointer(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          xrayGlow.withOpacity(0.04),
                          xrayGlow.withOpacity(0.11),
                          xrayGlow.withOpacity(0.03),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 12,
                right: 12,
                top: lineTop,
                child: IgnorePointer(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: xrayGlow,
                      boxShadow: [
                        BoxShadow(
                          color: xrayGlow.withOpacity(0.95),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 28,
                right: 28,
                top: (lineTop + 6).clamp(0.0, _scanViewportHeight - 1),
                child: IgnorePointer(
                  child: Container(
                    height: 1,
                    color: xrayGlow.withOpacity(0.35),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: xrayGlow.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    _scanCompleted
                        ? 'SCAN COMPLETE'
                        : 'SCANNING ${(progress * 100).floor()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.6,
                      color: xrayGlow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: Opacity(
                  opacity: 0.72,
                  child: Text(
                    _scanCompleted ? 'ITEM VERIFIED' : 'XR-OPS ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.9,
                      color: xrayGlow.withOpacity(0.9),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: xrayGlow.withOpacity(0.65)),
                      bottom: BorderSide(color: xrayGlow.withOpacity(0.65)),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: xrayGlow.withOpacity(0.65)),
                      bottom: BorderSide(color: xrayGlow.withOpacity(0.65)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.drop.skin;
    final rarityColor = SkinUiHelper.rarityColor(skin);

    const xrayGlow = Color(0xFF78FFF0);
    const xrayPanel = Color(0xFF0B1A21);

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: xrayGlow,
          width: 1.15,
        ),
      ),
      color: xrayPanel,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'X-Ray Scan Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: xrayGlow,
              ),
            ),
            const SizedBox(height: 14),
            _buildScanViewport(),
            AnimatedSwitcher(
              duration: _detailsFadeDuration,
              child: !_scanCompleted
                  ? const Padding(
                key: ValueKey('scan_wait'),
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Running X-Ray scan...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              )
                  : Column(
                key: const ValueKey('scan_done'),
                children: [
                  const SizedBox(height: 16),
                  Text(
                    _fullName(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: rarityColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InfoRow(
                    title: 'Rarity',
                    value: SkinUiHelper.rarityLabel(skin),
                    valueColor: rarityColor,
                  ),
                  InfoRow(
                    title: 'Weapon type',
                    value: SkinUiHelper.weaponTypeLabel(skin.weaponType),
                  ),
                  InfoRow(
                    title: 'Float',
                    value: widget.drop.skinFloat?.toStringAsFixed(6) ?? '-',
                  ),
                  InfoRow(
                    title: 'Exterior',
                    value: widget.drop.exterior ?? '-',
                  ),
                  InfoRow(
                    title: 'StatTrak',
                    value: widget.drop.isStatTrak ? 'Yes' : 'No',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onDestroy,
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('DESTROY'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onClaim,
                          style: ElevatedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('CLAIM ITEM'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XrayGridOverlay extends StatelessWidget {
  const _XrayGridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _XrayGridPainter(),
    );
  }
}

class _XrayGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = const Color(0xFF78FFF0).withOpacity(0.05)
      ..strokeWidth = 1;

    final major = Paint()
      ..color = const Color(0xFF78FFF0).withOpacity(0.08)
      ..strokeWidth = 1;

    const minorStep = 24.0;
    const majorEvery = 4;

    int index = 0;
    for (double y = 0; y <= size.height; y += minorStep) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % majorEvery == 0 ? major : minor,
      );
      index++;
    }

    index = 0;
    for (double x = 0; x <= size.width; x += minorStep) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % majorEvery == 0 ? major : minor,
      );
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}