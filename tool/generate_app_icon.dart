import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() async {
  final root = Directory.current;
  final casesFile = File('${root.path}/assets/data/cases.json');

  if (!casesFile.existsSync()) {
    stderr.writeln('cases.json not found: ${casesFile.path}');
    exit(1);
  }

  final raw = await casesFile.readAsString();
  final decodedJson = jsonDecode(raw);

  if (decodedJson is! List) {
    stderr.writeln('cases.json must contain a JSON array');
    exit(1);
  }

  final containers = decodedJson
      .whereType<Map>()
      .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
      .toList();

  final eligibleContainers = containers.where((c) {
    final type = (c['type'] as String?) ?? '';
    return type != 'SOUVENIR_PACKAGE';
  }).toList();

  if (eligibleContainers.isEmpty) {
    stderr.writeln('No eligible containers found in cases.json');
    exit(1);
  }

  eligibleContainers.sort((a, b) {
    final ad = (a['releaseDate'] as String?) ?? '0000-00-00';
    final bd = (b['releaseDate'] as String?) ?? '0000-00-00';
    final byDate = ad.compareTo(bd);
    if (byDate != 0) return byDate;

    final an = (a['name'] as String?) ?? '';
    final bn = (b['name'] as String?) ?? '';
    return an.compareTo(bn);
  });

  final latestContainer = eligibleContainers.last;
  final imageRel = (latestContainer['caseImage'] as String?)?.trim();

  if (imageRel == null || imageRel.isEmpty) {
    stderr.writeln('Latest eligible container has no caseImage');
    exit(1);
  }

  final sourceFile = File('${root.path}/$imageRel');
  if (!sourceFile.existsSync()) {
    stderr.writeln('Container image not found: ${sourceFile.path}');
    exit(1);
  }

  final bytes = await sourceFile.readAsBytes();
  final sourceImage = img.decodeImage(bytes);
  if (sourceImage == null) {
    stderr.writeln('Failed to decode image: ${sourceFile.path}');
    exit(1);
  }

  final croppedSource = _trimSolidBackground(sourceImage);

  const canvasSize = 1024;
  final outDir = Directory('${root.path}/assets/app_icon');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // 1) Standard icon for iOS / macOS / Windows / Linux / Web
  final standardCanvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(
    standardCanvas,
    color: img.ColorRgba8(0, 0, 0, 0),
  );

  final standardFitted = _resizeToFit(
    croppedSource,
    maxWidth: 900,
    maxHeight: 900,
  );

  img.compositeImage(
    standardCanvas,
    standardFitted,
    dstX: ((canvasSize - standardFitted.width) / 2).round(),
    dstY: ((canvasSize - standardFitted.height) / 2).round(),
  );

  await File('${outDir.path}/latest_case.png')
      .writeAsBytes(img.encodePng(standardCanvas));

  // 2) Android adaptive foreground
  final foregroundCanvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(
    foregroundCanvas,
    color: img.ColorRgba8(0, 0, 0, 0),
  );

  // Держим в safe zone, без клиппинга
  final foregroundFitted = _resizeToFit(
    croppedSource,
    maxWidth: 760,
    maxHeight: 760,
  );

  img.compositeImage(
    foregroundCanvas,
    foregroundFitted,
    dstX: ((canvasSize - foregroundFitted.width) / 2).round(),
    dstY: ((canvasSize - foregroundFitted.height) / 2).round(),
  );

  await File('${outDir.path}/latest_case_foreground.png')
      .writeAsBytes(img.encodePng(foregroundCanvas));

  // 3) Android monochrome themed icon
  final monoSource = img.copyResize(
    croppedSource,
    width: foregroundFitted.width,
    height: foregroundFitted.height,
    interpolation: img.Interpolation.average,
  );
  final monoConverted = _toMonochromeAlphaMask(monoSource);

  final monoCanvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(
    monoCanvas,
    color: img.ColorRgba8(0, 0, 0, 0),
  );
  img.compositeImage(
    monoCanvas,
    monoConverted,
    dstX: ((canvasSize - monoConverted.width) / 2).round(),
    dstY: ((canvasSize - monoConverted.height) / 2).round(),
  );

  await File('${outDir.path}/latest_case_monochrome.png')
      .writeAsBytes(img.encodePng(monoCanvas));

  // 4) iOS dark transparent icon
  final iosDarkCanvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(
    iosDarkCanvas,
    color: img.ColorRgba8(0, 0, 0, 0),
  );

  final iosDarkFitted = _resizeToFit(
    croppedSource,
    maxWidth: 900,
    maxHeight: 900,
  );

  img.compositeImage(
    iosDarkCanvas,
    iosDarkFitted,
    dstX: ((canvasSize - iosDarkFitted.width) / 2).round(),
    dstY: ((canvasSize - iosDarkFitted.height) / 2).round(),
  );

  await File('${outDir.path}/latest_case_ios_dark.png')
      .writeAsBytes(img.encodePng(iosDarkCanvas));

  // 5) iOS tinted grayscale icon
  final tintedCanvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(
    tintedCanvas,
    color: img.ColorRgba8(0, 0, 0, 0),
  );

  final tintedSource = img.copyResize(
    croppedSource,
    width: iosDarkFitted.width,
    height: iosDarkFitted.height,
    interpolation: img.Interpolation.average,
  );
  final tintedGray = _toGrayscalePreserveAlpha(tintedSource);

  img.compositeImage(
    tintedCanvas,
    tintedGray,
    dstX: ((canvasSize - tintedGray.width) / 2).round(),
    dstY: ((canvasSize - tintedGray.height) / 2).round(),
  );

  await File('${outDir.path}/latest_case_ios_tinted.png')
      .writeAsBytes(img.encodePng(tintedCanvas));

  // 6) Transparent Android background
  final transparentBg = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(
    transparentBg,
    color: img.ColorRgba8(0, 0, 0, 0),
  );

  await File('${outDir.path}/transparent_bg.png')
      .writeAsBytes(img.encodePng(transparentBg));

  stdout.writeln('Latest eligible container: ${latestContainer['name']}');
  stdout.writeln('Type: ${latestContainer['type']}');
  stdout.writeln('Generated: assets/app_icon/latest_case.png');
  stdout.writeln('Generated: assets/app_icon/latest_case_foreground.png');
  stdout.writeln('Generated: assets/app_icon/latest_case_monochrome.png');
  stdout.writeln('Generated: assets/app_icon/latest_case_ios_dark.png');
  stdout.writeln('Generated: assets/app_icon/latest_case_ios_tinted.png');
  stdout.writeln('Generated: assets/app_icon/transparent_bg.png');
}

img.Image _resizeToFit(
    img.Image source, {
      required int maxWidth,
      required int maxHeight,
    }) {
  final widthRatio = maxWidth / source.width;
  final heightRatio = maxHeight / source.height;
  final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

  final targetWidth = (source.width * ratio).round().clamp(1, maxWidth);
  final targetHeight = (source.height * ratio).round().clamp(1, maxHeight);

  return img.copyResize(
    source,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.average,
  );
}

img.Image _trimSolidBackground(img.Image source) {
  final bg = _averageCornerColor(source);
  const tolerance = 22;

  int minX = source.width;
  int minY = source.height;
  int maxX = -1;
  int maxY = -1;

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final p = source.getPixel(x, y);

      final isBg = _isCloseColor(
        p.r.toInt(),
        p.g.toInt(),
        p.b.toInt(),
        bg.$1,
        bg.$2,
        bg.$3,
        tolerance,
      );

      if (!isBg) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < minX || maxY < minY) {
    return source;
  }

  const padding = 6;
  minX = (minX - padding).clamp(0, source.width - 1);
  minY = (minY - padding).clamp(0, source.height - 1);
  maxX = (maxX + padding).clamp(0, source.width - 1);
  maxY = (maxY + padding).clamp(0, source.height - 1);

  final width = maxX - minX + 1;
  final height = maxY - minY + 1;

  return img.copyCrop(
    source,
    x: minX,
    y: minY,
    width: width,
    height: height,
  );
}

(int, int, int) _averageCornerColor(img.Image source) {
  final corners = [
    source.getPixel(0, 0),
    source.getPixel(source.width - 1, 0),
    source.getPixel(0, source.height - 1),
    source.getPixel(source.width - 1, source.height - 1),
  ];

  final r = corners.map((p) => p.r.toInt()).reduce((a, b) => a + b) ~/ corners.length;
  final g = corners.map((p) => p.g.toInt()).reduce((a, b) => a + b) ~/ corners.length;
  final b = corners.map((p) => p.b.toInt()).reduce((a, b) => a + b) ~/ corners.length;

  return (r, g, b);
}

bool _isCloseColor(
    int r1,
    int g1,
    int b1,
    int r2,
    int g2,
    int b2,
    int tolerance,
    ) {
  return (r1 - r2).abs() <= tolerance &&
      (g1 - g2).abs() <= tolerance &&
      (b1 - b2).abs() <= tolerance;
}

img.Image _toMonochromeAlphaMask(img.Image source) {
  final out = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final a = pixel.a.toInt();

      if (a == 0) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      final luminance = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b)
          .round()
          .clamp(0, 255);

      final value = luminance > 16 ? 255 : 0;
      out.setPixelRgba(x, y, value, value, value, a);
    }
  }

  return out;
}

img.Image _toGrayscalePreserveAlpha(img.Image source) {
  final out = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final a = pixel.a.toInt();

      if (a == 0) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      final gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b)
          .round()
          .clamp(0, 255);

      out.setPixelRgba(x, y, gray, gray, gray, a);
    }
  }

  return out;
}