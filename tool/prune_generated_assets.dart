import 'dart:convert';
import 'dart:io';

final _root = Directory.current;

Future<void> main() async {
  final referenced = <String>{};

  void collectFromJsonArray(String relativePath, List<String> imageKeys) {
    final file = File('${_root.path}/$relativePath');
    if (!file.existsSync()) {
      return;
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) {
      return;
    }
    for (final item in decoded.whereType<Map>()) {
      for (final key in imageKeys) {
        final value = item[key];
        if (value is String && value.trim().isNotEmpty) {
          referenced.add(_normalize(value));
        }
      }
    }
  }

  collectFromJsonArray('assets/data/containers.json', [
    'containerImage',
    'tournamentLogo',
  ]);
  collectFromJsonArray('assets/data/skins.json', ['skinImage']);
  collectFromJsonArray('assets/data/stickers.json', ['stickerImage']);
  collectFromJsonArray('assets/data/pins.json', ['pinImage']);
  collectFromJsonArray('assets/data/music_kits.json', ['musicKitImage']);

  final dirs = <String>[
    'assets/containers',
    'assets/skins',
    'assets/stickers',
    'assets/pins',
    'assets/music_kits',
    'assets/tournament_logos',
  ];

  var deleted = 0;
  var freedBytes = 0;

  for (final dirPath in dirs) {
    final dir = Directory('${_root.path}/$dirPath');
    if (!dir.existsSync()) {
      continue;
    }
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final relative = _relative(entity.path);
      if (referenced.contains(relative)) {
        continue;
      }
      freedBytes += await entity.length();
      await entity.delete();
      deleted += 1;
      stdout.writeln('Deleted $relative');
    }
  }

  stdout.writeln('Deleted files: $deleted');
  stdout.writeln(
    'Freed MB: ${(freedBytes / (1024 * 1024)).toStringAsFixed(2)}',
  );
}

String _normalize(String path) => path.replaceAll('\\', '/').trim();

String _relative(String absolutePath) {
  final rootPath = _normalize(_root.path);
  final normalized = _normalize(absolutePath);
  if (normalized.startsWith('$rootPath/')) {
    return normalized.substring(rootPath.length + 1);
  }
  return normalized;
}
