import 'backend.dart';
import 'dart_backend.dart';
import 'io_utils.dart';

class CsDataImporter {
  CsDataImporter({IoUtils? ioUtils, CompressionMode? compressionMode})
    : _compressionMode =
          compressionMode ?? ioUtils?.compressionMode ?? CompressionMode.fast,
      _io =
          ioUtils ??
          IoUtils(compressionMode: compressionMode ?? CompressionMode.fast);

  final IoUtils _io;
  final CompressionMode _compressionMode;

  Future<void> run() async {
    _io.printInfo('Starting Dart importer entrypoint...');
    _io.printInfo('Compression mode: ${_labelForMode(_compressionMode)}');
    final backend = _buildBackend();
    await backend.run();
  }

  ImporterBackend _buildBackend() {
    return DartImporterBackend(_io);
  }

  String _labelForMode(CompressionMode mode) {
    return switch (mode) {
      CompressionMode.fast => 'fast',
      CompressionMode.maxCompress => 'max-compress',
    };
  }
}
