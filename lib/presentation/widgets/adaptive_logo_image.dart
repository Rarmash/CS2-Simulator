import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdaptiveLogoImage extends StatelessWidget {
  final String logoPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const AdaptiveLogoImage({
    super.key,
    required this.logoPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  static bool shouldUseAdaptiveTint(String path) {
    final normalized = path.toLowerCase();
    return normalized.startsWith('assets/tournament_logos/');
  }

  bool get _isSvg => logoPath.toLowerCase().endsWith('.svg');

  bool _shouldLightenForTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark &&
        shouldUseAdaptiveTint(logoPath);
  }

  Widget _buildImage(BuildContext context, Widget fallbackWidget) {
    if (_isSvg) {
      return SvgPicture.asset(
        logoPath,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) => SizedBox(
          width: width,
          height: height,
          child: Center(child: fallbackWidget),
        ),
      );
    }

    return Image.asset(
      logoPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => fallbackWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallbackWidget =
        fallback ??
        Icon(Icons.image_not_supported_outlined, size: width ?? height ?? 24);
    final image = _buildImage(context, fallbackWidget);

    if (!_shouldLightenForTheme(context)) {
      return image;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: image,
    );
  }
}
