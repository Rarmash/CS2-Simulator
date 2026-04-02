import 'dart:convert';
import 'dart:io';

import 'config.dart';

enum CompressionMode { fast, maxCompress }

class IoUtils {
  IoUtils({this.compressionMode = CompressionMode.fast});

  final HttpClient _client = HttpClient()
    ..userAgent = 'cs2-simulator-parser/0.9';
  final CompressionMode compressionMode;
  String? _cwebpBinaryPath;
  Directory? _webpTempDir;

  void printInfo(String message) {
    stdout.writeln(message);
  }

  Never fail(String message, {int exitCode = 1}) {
    stderr.writeln(message);
    exit(exitCode);
  }

  Future<dynamic> fetchJson(String url) async {
    final request = await _client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(
      const Duration(seconds: timeoutSeconds),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'HTTP ${response.statusCode} for $url',
        uri: Uri.parse(url),
      );
    }
    final raw = await utf8.decoder.bind(response).join();
    return jsonDecode(raw);
  }

  Future<void> ensureDirs() async {
    for (final dir in [
      assetsDir,
      dataDir,
      casesDir,
      skinsDir,
      stickersDir,
      pinsDir,
      musicKitsDir,
      agentsDir,
      graffitiDir,
      patchesDir,
      rewardCollectionsDir,
      operationCollectionsDir,
      agentCollectionsDir,
      tournamentLogosDir,
    ]) {
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    }
  }

  Future<void> resetCollectibleOutputs() async {
    for (final file in [
      File('${dataDir.path}/stickers.json'),
      File('${dataDir.path}/sticker_contents.json'),
      File('${dataDir.path}/pins.json'),
      File('${dataDir.path}/pin_contents.json'),
      File('${dataDir.path}/music_kits.json'),
      File('${dataDir.path}/music_kit_contents.json'),
      File('${dataDir.path}/agents.json'),
      File('${dataDir.path}/agent_collections.json'),
      File('${dataDir.path}/agent_collection_contents.json'),
      File('${dataDir.path}/graffiti.json'),
      File('${dataDir.path}/graffiti_contents.json'),
      File('${dataDir.path}/patches.json'),
      File('${dataDir.path}/patch_contents.json'),
    ]) {
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  List<Map<String, dynamic>> loadJsonList(File file) {
    if (!file.existsSync()) {
      return <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  dynamic loadJsonAny(File file) {
    if (!file.existsSync()) {
      return null;
    }
    return jsonDecode(file.readAsStringSync());
  }

  Future<void> writeJson(File file, Object? data) async {
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(data)}\n');
  }

  String detectImageExtension(String url, {String? contentType}) {
    final lowerContentType = (contentType ?? '').toLowerCase();
    if (lowerContentType.contains('image/svg+xml')) {
      return '.svg';
    }
    if (lowerContentType.contains('image/png')) {
      return '.png';
    }
    if (lowerContentType.contains('image/webp')) {
      return '.webp';
    }
    if (lowerContentType.contains('image/jpeg') ||
        lowerContentType.contains('image/jpg')) {
      return '.jpg';
    }

    final lowerPath = Uri.parse(url).path.toLowerCase();
    if (lowerPath.endsWith('.svg')) {
      return '.svg';
    }
    if (lowerPath.endsWith('.png')) {
      return '.png';
    }
    if (lowerPath.endsWith('.webp')) {
      return '.webp';
    }
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return '.jpg';
    }

    return '.png';
  }

  Future<void> downloadFile(String url, File file) async {
    if (url.isEmpty || file.existsSync()) {
      return;
    }

    try {
      final request = await _client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: timeoutSeconds),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        stderr.writeln(
          '[WARN] failed to download $url -> ${file.path}: HTTP ${response.statusCode}',
        );
        return;
      }
      await file.parent.create(recursive: true);
      await response.pipe(file.openWrite());
    } catch (exc) {
      stderr.writeln('[WARN] failed to download $url -> ${file.path}: $exc');
    }
  }

  Future<String?> downloadFileWithRealExtension(
    String url,
    String pathWithoutExt,
  ) async {
    if (url.isEmpty) {
      return null;
    }

    try {
      final request = await _client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: timeoutSeconds),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        stderr.writeln(
          '[WARN] failed to download $url -> $pathWithoutExt: HTTP ${response.statusCode}',
        );
        return null;
      }

      final bytes = await response.fold<List<int>>(
        <int>[],
        (acc, data) => acc..addAll(data),
      );
      final ext = detectImageExtension(
        url,
        contentType: response.headers.contentType?.mimeType,
      );
      final file = File('$pathWithoutExt$ext');
      if (file.existsSync()) {
        return ext;
      }

      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return ext;
    } catch (exc) {
      stderr.writeln('[WARN] failed to download $url -> $pathWithoutExt: $exc');
      return null;
    }
  }

  Future<String?> downloadOptimizedAsset(
    String url,
    String pathWithoutExt,
  ) async {
    if (url.isEmpty) {
      return null;
    }

    try {
      final request = await _client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: timeoutSeconds),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        stderr.writeln(
          '[WARN] failed to download $url -> $pathWithoutExt: HTTP ${response.statusCode}',
        );
        return null;
      }

      final bytes = await response.fold<List<int>>(
        <int>[],
        (acc, data) => acc..addAll(data),
      );
      final sourceExt = detectImageExtension(
        url,
        contentType: response.headers.contentType?.mimeType,
      );

      if (sourceExt == '.svg') {
        final svgFile = File('$pathWithoutExt.svg');
        if (!svgFile.existsSync()) {
          await svgFile.parent.create(recursive: true);
          await svgFile.writeAsBytes(bytes);
        }
        return '.svg';
      }

      if (sourceExt == '.webp') {
        final webpFile = File('$pathWithoutExt.webp');
        if (!webpFile.existsSync()) {
          await webpFile.parent.create(recursive: true);
          await webpFile.writeAsBytes(bytes);
        }
        return '.webp';
      }

      if (sourceExt == '.png') {
        final webpFile = File('$pathWithoutExt.webp');
        if (webpFile.existsSync()) {
          return '.webp';
        }

        final cwebpPath = await _resolveCwebpBinaryPath();
        if (cwebpPath != null) {
          final tempDir = await _resolveWebpTempDir();
          final inputFile = File(
            '${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}.png',
          );
          try {
            await inputFile.writeAsBytes(bytes);
            await webpFile.parent.create(recursive: true);
            final result = await Process.run(cwebpPath, [
              '-lossless',
              '-z',
              compressionMode == CompressionMode.maxCompress ? '9' : '6',
              '-mt',
              '-exact',
              inputFile.path,
              '-o',
              webpFile.path,
            ]);
            if (result.exitCode == 0 && webpFile.existsSync()) {
              return '.webp';
            }
            stderr.writeln(
              '[WARN] cwebp failed for $url -> $pathWithoutExt: ${result.stderr}',
            );
          } finally {
            if (inputFile.existsSync()) {
              await inputFile.delete();
            }
          }
        }
      }

      final file = File('$pathWithoutExt$sourceExt');
      if (!file.existsSync()) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
      }
      return sourceExt;
    } catch (exc) {
      stderr.writeln('[WARN] failed to download $url -> $pathWithoutExt: $exc');
      return null;
    }
  }

  Future<String?> _resolveCwebpBinaryPath() async {
    if (_cwebpBinaryPath != null) {
      return _cwebpBinaryPath;
    }

    final packageConfigFile = File(
      '${outRoot.path}/.dart_tool/package_config.json',
    );
    if (!packageConfigFile.existsSync()) {
      return null;
    }

    try {
      final decoded = jsonDecode(await packageConfigFile.readAsString());
      if (decoded is! Map || decoded['packages'] is! List) {
        return null;
      }

      final packages = decoded['packages'] as List;
      for (final item in packages) {
        if (item is! Map) {
          continue;
        }
        if (item['name']?.toString() != 'webp') {
          continue;
        }

        final rootUriRaw = item['rootUri']?.toString();
        if (rootUriRaw == null || rootUriRaw.isEmpty) {
          return null;
        }

        final packageRoot = _resolvePackageRoot(
          packageConfigFile.parent,
          rootUriRaw,
        );
        if (packageRoot == null) {
          return null;
        }

        final binaryPath = _binaryPathForPlatform(packageRoot.path);
        if (binaryPath != null && File(binaryPath).existsSync()) {
          _cwebpBinaryPath = binaryPath;
          return _cwebpBinaryPath;
        }
      }
    } catch (exc) {
      stderr.writeln('[WARN] failed to resolve cwebp binary: $exc');
    }

    return null;
  }

  Directory? _resolvePackageRoot(Directory baseDir, String rootUriRaw) {
    final uri = Uri.parse(rootUriRaw);
    if (uri.scheme == 'file') {
      return Directory.fromUri(uri);
    }
    final resolved = baseDir.uri.resolveUri(uri);
    return Directory.fromUri(resolved);
  }

  String? _binaryPathForPlatform(String packageRootPath) {
    if (Platform.isWindows) {
      return '$packageRootPath\\windows-x64\\cwebp.exe';
    }
    if (Platform.isMacOS) {
      return '$packageRootPath\\mac-x86-64\\cwebp';
    }
    if (Platform.isLinux) {
      return '$packageRootPath\\linux-x86-64\\cwebp';
    }
    return null;
  }

  Future<Directory> _resolveWebpTempDir() async {
    final dir = _webpTempDir;
    if (dir != null && dir.existsSync()) {
      return dir;
    }

    final created = await Directory.systemTemp.createTemp('cs2_webp_');
    _webpTempDir = created;
    return created;
  }
}
