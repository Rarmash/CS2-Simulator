import 'dart:async';

import 'package:flutter/material.dart';

class HoldToConfirmButton extends StatefulWidget {
  final String label;
  final Duration duration;
  final FutureOr<void> Function() onCompleted;
  final bool isPrimary;

  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.duration,
    required this.onCompleted,
    required this.isPrimary,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _triggered = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed && !_triggered && !_busy) {
          _triggered = true;
          _busy = true;
          try {
            await widget.onCompleted();
          } finally {
            if (mounted) {
              _controller.reset();
              _triggered = false;
              _busy = false;
            }
          }
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_busy) {
      return;
    }
    _triggered = false;
    _controller.forward(from: 0);
  }

  void _cancelHold() {
    if (_busy) {
      return;
    }
    if (_controller.isAnimating || _controller.value > 0) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.isPrimary
        ? ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          )
        : OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          );

    final child = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _controller.value,
                    child: Container(
                      color: widget.isPrimary
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_busy) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(_busy ? 'PROCESSING...' : widget.label),
              ],
            ),
          ],
        );
      },
    );

    final button = widget.isPrimary
        ? ElevatedButton(
            onPressed: _busy ? null : () {},
            style: baseStyle,
            child: child,
          )
        : OutlinedButton(
            onPressed: _busy ? null : () {},
            style: baseStyle,
            child: child,
          );

    return Listener(
      onPointerDown: (_) => _startHold(),
      onPointerUp: (_) => _cancelHold(),
      onPointerCancel: (_) => _cancelHold(),
      child: button,
    );
  }
}
