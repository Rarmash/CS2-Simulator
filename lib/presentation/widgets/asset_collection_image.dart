import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AssetCollectionImage extends StatelessWidget {
  final String assetPath;
  final double? height;
  final BoxFit fit;

  const AssetCollectionImage({
    super.key,
    required this.assetPath,
    this.height,
    this.fit = BoxFit.contain,
  });

  bool get _isSvg => assetPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return SvgPicture.asset(
        assetPath,
        height: height,
        fit: fit,
        placeholderBuilder: (_) => SizedBox(
          height: height,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Image.asset(
      assetPath,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
    );
  }
}