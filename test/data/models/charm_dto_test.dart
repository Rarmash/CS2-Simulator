import 'package:cs2_simulator/data/models/charm_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = <String, dynamic>{
    'id': '123',
    'name': 'Charm',
    'charmImage': 'assets/charms/123.png',
    'rarity': 'HIGH_GRADE',
    'collection': null,
  };

  test('legacy charms remain readable without highlight metadata', () {
    final charm = CharmDto.fromJson(base);
    expect(charm.id, '123');
    expect(charm.video, isNull);
    expect(charm.thumbnail, isNull);
    expect(charm.description, isNull);
    expect(charm.map, isNull);
    expect(charm.stage, isNull);
    expect(charm.player, isNull);
  });

  test('highlight metadata is read from the catalog', () {
    final charm = CharmDto.fromJson({
      ...base,
      'video': 'https://example.com/video.webm',
      'thumbnail': 'https://example.com/image.webp',
      'description': 'A highlight',
      'map': 'de_dust2',
      'stage': 'Final',
      'player': 'player',
    });
    expect(charm.video, 'https://example.com/video.webm');
    expect(charm.thumbnail, 'https://example.com/image.webp');
    expect(charm.description, 'A highlight');
    expect(charm.map, 'de_dust2');
    expect(charm.stage, 'Final');
    expect(charm.player, 'player');
  });
}
