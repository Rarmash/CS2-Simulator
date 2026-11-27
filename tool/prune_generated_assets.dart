import 'dart:convert';
import 'dart:io';

final _root = Directory.current;

Future<void> main() async {
  final referenced = <String>{};

  void collectImagePaths(Object? value, Set<String> imageKeys) {
    if (value is List) {
      for (final item in value) {
        collectImagePaths(item, imageKeys);
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        final imagePath = entry.value;
        if (imageKeys.contains(entry.key) &&
            imagePath is String &&
            imagePath.trim().isNotEmpty) {
          referenced.add(_normalize(imagePath));
        } else {
          collectImagePaths(imagePath, imageKeys);
        }
      }
    }
  }

  void collectFromJsonArray(String relativePath, List<String> imageKeys) {
    final file = File('${_root.path}/$relativePath');
    if (file.existsSync()) {
      collectImagePaths(jsonDecode(file.readAsStringSync()), imageKeys.toSet());
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

  collectFromJsonArray('assets/data/tournament_metadata.json', [
    'tournamentLogo',
    'teamLogo',
    'team1Logo',
    'team2Logo',
  ]);

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
