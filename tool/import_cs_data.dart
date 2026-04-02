import 'dart:io';

import 'importer/src/importer.dart';
import 'importer/src/io_utils.dart';

Future<void> main(List<String> args) async {
  final compressionMode = _parseCompressionMode(args);
  final importer = CsDataImporter(compressionMode: compressionMode);
  await importer.run();
}

CompressionMode _parseCompressionMode(List<String> args) {
  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      stdout.writeln('Usage: dart run tool/import_cs_data.dart [options]');
      stdout.writeln('');
      stdout.writeln('Options:');
      stdout.writeln(
        '  --compression=fast|max-compress   Set asset compression mode (default: fast)',
      );
      stdout.writeln(
        '  --max-compress                    Shortcut for --compression=max-compress',
      );
      exit(0);
    }

    if (arg == '--max-compress') {
      return CompressionMode.maxCompress;
    }

    if (arg.startsWith('--compression=')) {
      final value = arg.substring('--compression='.length).trim();
      return switch (value) {
        'fast' => CompressionMode.fast,
        'max-compress' => CompressionMode.maxCompress,
        _ => _failInvalidCompressionMode(value),
      };
    }
  }

  return CompressionMode.fast;
}

Never _failInvalidCompressionMode(String value) {
  stderr.writeln(
    'Unsupported compression mode: $value. Use fast or max-compress.',
  );
  exit(64);
}
