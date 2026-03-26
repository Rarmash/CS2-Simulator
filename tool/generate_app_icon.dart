import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() async {
  final root = Directory.current;

  final casesFile = File('${root.path}/assets/data/cases.json');
  final rewardCollectionsFile =
  File('${root.path}/assets/data/reward_collections.json');
  final operationCollectionsFile =
  File('${root.path}/assets/data/operation_collections.json');

  if (!casesFile.existsSync()) {
    stderr.writeln('cases.json not found: ${casesFile.path}');
    exit(1);
  }

  final cases = _readJsonList(await casesFile.readAsString(), 'cases.json');
  final rewardCollections = rewardCollectionsFile.existsSync()
      ? _readJsonList(
    await rewardCollectionsFile.readAsString(),
    'reward_collections.json',
  )
      : <Map<String, dynamic>>[];
  final operationCollections = operationCollectionsFile.existsSync()
      ? _readJsonList(
    await operationCollectionsFile.readAsString(),
    'operation_collections.json',
  )
      : <Map<String, dynamic>>[];

  final candidates = <_IconCandidate>[];

  for (final item in cases) {
    final name = (item['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) continue;

    final type = (item['type'] as String?)?.trim() ?? 'CASE';

    String? imageRel;
    switch (type) {
      case 'SOUVENIR_PACKAGE':
        final tournamentLogo = (item['tournamentLogo'] as String?)?.trim();
        imageRel = (tournamentLogo != null && tournamentLogo.isNotEmpty)
            ? tournamentLogo
            : (item['caseImage'] as String?)?.trim();
        break;

      default:
        imageRel = (item['caseImage'] as String?)?.trim();
        break;
    }

    if (imageRel == null || imageRel.isEmpty) continue;

    candidates.add(
      _IconCandidate(
        name: name,
        kind: 'CONTAINER',
        sourceType: type,
        releaseDate: (item['releaseDate'] as String?)?.trim(),
        imageRelPath: imageRel,
      ),
    );
  }

  for (final item in rewardCollections) {
    final name = (item['name'] as String?)?.trim() ?? '';
    final imageRel = (item['image'] as String?)?.trim() ?? '';
    if (name.isEmpty || imageRel.isEmpty) continue;

    candidates.add(
      _IconCandidate(
        name: name,
        kind: 'REWARD_COLLECTION',
        sourceType: (item['sourceType'] as String?)?.trim() ?? 'REWARD_COLLECTION',
        releaseDate: (item['releaseDate'] as String?)?.trim(),
        imageRelPath: imageRel,
      ),
    );
  }

  for (final item in operationCollections) {
    final name = (item['name'] as String?)?.trim() ?? '';
    final imageRel = (item['image'] as String?)?.trim() ?? '';
    if (name.isEmpty || imageRel.isEmpty) continue;

    candidates.add(
      _IconCandidate(
        name: name,
        kind: 'OPERATION_COLLECTION',
        sourceType: (item['operationId'] as String?)?.trim() ?? 'OPERATION_COLLECTION',
        releaseDate: (item['releaseDate'] as String?)?.trim(),
        imageRelPath: imageRel,
      ),
    );
  }

  if (candidates.isEmpty) {
    stderr.writeln('No icon candidates found.');
    exit(1);
  }

  candidates.sort((a, b) {
    final ad = a.releaseDate ?? '0000-00-00';
    final bd = b.releaseDate ?? '0000-00-00';
    final byDate = ad.compareTo(bd);
    if (byDate != 0) return byDate;
    return a.name.compareTo(b.name);
  });

  final latest = candidates.last;

  final sourceFile = File('${root.path}/${latest.imageRelPath}');
  if (!sourceFile.existsSync()) {
    stderr.writeln('Icon source image not found: ${sourceFile.path}');
    exit(1);
  }

  final bytes = await sourceFile.readAsBytes();
  final sourceImage = img.decodeImage(bytes);
  if (sourceImage == null) {
    stderr.writeln('Failed to decode image: ${sourceFile.path}');
    exit(1);
  }

  final croppedSource = _trimTransparentOrSolidBackground(sourceImage);

  const canvasSize = 1024;
  final outDir = Directory('${root.path}/assets/app_icon');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

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

  final foregroundCanvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(
    foregroundCanvas,
    color: img.ColorRgba8(0, 0, 0, 0),
  );

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

  stdout.writeln('Latest item: ${latest.name}');
  stdout.writeln('Kind: ${latest.kind}');
  stdout.writeln('Source type: ${latest.sourceType}');
  stdout.writeln('Selected image: ${latest.imageRelPath}');
  stdout.writeln('Generated: assets/app_icon/latest_case.png');
  stdout.writeln('Generated: assets/app_icon/latest_case_foreground.png');
  stdout.writeln('Generated: assets/app_icon/latest_case_monochrome.png');
  stdout.writeln('Generated: assets/app_icon/latest_case_ios_dark.png');
  stdout.writeln('Generated: assets/app_icon/latest_case_ios_tinted.png');
  stdout.writeln('Generated: assets/app_icon/transparent_bg.png');
}

class _IconCandidate {
  final String name;
  final String kind;
  final String sourceType;
  final String? releaseDate;
  final String imageRelPath;

  const _IconCandidate({
    required this.name,
    required this.kind,
    required this.sourceType,
    required this.releaseDate,
    required this.imageRelPath,
  });
}

List<Map<String, dynamic>> _readJsonList(String raw, String debugName) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    stderr.writeln('$debugName must contain a JSON array');
    exit(1);
  }

  return decoded
      .whereType<Map>()
      .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
      .toList();
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

img.Image _trimTransparentOrSolidBackground(img.Image source) {
  final transparentBounds = _findOpaqueBounds(source);
  if (transparentBounds != null) {
    return _cropWithPadding(source, transparentBounds);
  }

  return _trimSolidBackground(source);
}

_Rect? _findOpaqueBounds(img.Image source) {
  int minX = source.width;
  int minY = source.height;
  int maxX = -1;
  int maxY = -1;

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final p = source.getPixel(x, y);
      if (p.a.toInt() > 8) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < minX || maxY < minY) {
    return null;
  }

  return _Rect(minX, minY, maxX, maxY);
}

img.Image _cropWithPadding(img.Image source, _Rect rect) {
  const padding = 6;

  final minX = (rect.minX - padding).clamp(0, source.width - 1);
  final minY = (rect.minY - padding).clamp(0, source.height - 1);
  final maxX = (rect.maxX + padding).clamp(0, source.width - 1);
  final maxY = (rect.maxY + padding).clamp(0, source.height - 1);

  return img.copyCrop(
    source,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

class _Rect {
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  const _Rect(this.minX, this.minY, this.maxX, this.maxY);
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

  return _cropWithPadding(source, _Rect(minX, minY, maxX, maxY));
}

(int, int, int) _averageCornerColor(img.Image source) {
  final corners = [
    source.getPixel(0, 0),
    source.getPixel(source.width - 1, 0),
    source.getPixel(0, source.height - 1),
    source.getPixel(source.width - 1, source.height - 1),
  ];

  final r =
      corners.map((p) => p.r.toInt()).reduce((a, b) => a + b) ~/ corners.length;
  final g =
      corners.map((p) => p.g.toInt()).reduce((a, b) => a + b) ~/ corners.length;
  final b =
      corners.map((p) => p.b.toInt()).reduce((a, b) => a + b) ~/ corners.length;

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