import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/importer/src/io_utils.dart';

void main() {
  late Directory temp;
  late HttpServer server;
  late IoUtils io;
  late Uint8List source;
  late String mime;
  late img.Image original;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('sticker_optimization_test_');
    source = await File(
      'test/tool/fixtures/sticker_lossless.webp',
    ).readAsBytes();
    original = img.decodeWebP(source)!;
    mime = 'image/webp';
    io = IoUtils();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.parse(mime);
      request.response.add(source);
      await request.response.close();
    });
  });

  tearDown(() async {
    io.close();
    await server.close(force: true);
    await temp.delete(recursive: true);
  });

  for (final extension in ['webp', 'png']) {
    test(
      'optimizes $extension stickers without resizing or changing alpha',
      () async {
        if (extension == 'png') {
          source = img.encodePng(original);
          mime = 'image/png';
        }
        final path = '${temp.path}/sticker';
        final result = await io.downloadOptimizedAsset(
          'http://${server.address.address}:${server.port}/source.$extension',
          path,
          optimizeSticker: true,
        );
        expect(result, '.webp');
        final bytes = await File('$path.webp').readAsBytes();
        expect(bytes.length, lessThan(source.length ~/ 2));
        final output = img.decodeWebP(bytes)!;
        expect(output.width, original.width);
        expect(output.height, original.height);
        for (var y = 0; y < original.height; y++) {
          for (var x = 0; x < original.width; x++) {
            if (original.getPixel(x, y).a != output.getPixel(x, y).a) {
              fail('Alpha changed at $x,$y');
            }
          }
        }
        // A regular import must not recompress an already prepared sticker.
        await io.downloadOptimizedAsset(
          'http://${server.address.address}:${server.port}/source.$extension',
          path,
          optimizeSticker: true,
        );
        expect(await File('$path.webp').readAsBytes(), bytes);
      },
    );
  }

  test('keeps non-sticker WebP assets byte-identical', () async {
    final path = '${temp.path}/other';
    await io.downloadOptimizedAsset(
      'http://${server.address.address}:${server.port}/source.webp',
      path,
    );
    expect(await File('$path.webp').readAsBytes(), source);
  });
}
