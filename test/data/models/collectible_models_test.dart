import 'package:cs2_simulator/data/models/agent_dto.dart';
import 'package:cs2_simulator/data/models/charm_dto.dart';
import 'package:cs2_simulator/data/models/graffiti_dto.dart';
import 'package:cs2_simulator/data/models/patch_dto.dart';
import 'package:cs2_simulator/data/models/pin_dto.dart';
import 'package:cs2_simulator/data/models/sticker_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StickerDto', () {
    test('uses collection before tournament for source label', () {
      final sticker = StickerDto.fromJson({
        'id': '1',
        'name': 'Sticker | Test',
        'stickerImage': 'assets/stickers/1.webp',
        'rarity': 'HIGH_GRADE',
        'stickerType': 'AUTOGRAPH',
        'effect': 'OTHER',
        'collection': 'Capsule Collection',
        'tournament': 'PGL Copenhagen 2024',
      });

      expect(sticker.sourceLabel, 'Capsule Collection');
      expect(sticker.stickerTypeLabel, 'Autograph');
    });

    test('falls back to tournament and sticker type labels', () {
      final eventSticker = StickerDto.fromJson({
        'id': '2',
        'name': 'Sticker | Event',
        'stickerImage': 'assets/stickers/2.webp',
        'rarity': 'HIGH_GRADE',
        'stickerType': 'EVENT',
        'effect': 'OTHER',
        'tournament': 'BLAST.tv Paris 2023',
      });
      final plainSticker = StickerDto.fromJson({
        'id': '3',
        'name': 'Sticker | Plain',
        'stickerImage': 'assets/stickers/3.webp',
        'rarity': 'HIGH_GRADE',
        'stickerType': 'STICKER',
        'effect': 'OTHER',
      });

      expect(eventSticker.sourceLabel, 'BLAST.tv Paris 2023');
      expect(eventSticker.stickerTypeLabel, 'Event');
      expect(plainSticker.sourceLabel, 'Sticker');
    });
  });

  group('simple collectible DTO parsing', () {
    test('agent defaults unknown team when omitted', () {
      final agent = AgentDto.fromJson({
        'id': '10',
        'name': 'Agent',
        'agentImage': 'assets/agents/10.webp',
        'rarity': 'DISTINGUISHED',
      });

      expect(agent.team, 'UNKNOWN');
    });

    test('pin, graffiti, patch, and charm parse nullable collection', () {
      final pin = PinDto.fromJson({
        'id': '11',
        'name': 'Pin',
        'pinImage': 'assets/pins/11.webp',
        'rarity': 'HIGH_GRADE',
      });
      final graffiti = GraffitiDto.fromJson({
        'id': '12',
        'name': 'Graffiti',
        'graffitiImage': 'assets/graffiti/12.webp',
        'rarity': 'BASE_GRADE',
      });
      final patch = PatchDto.fromJson({
        'id': '13',
        'name': 'Patch',
        'patchImage': 'assets/patches/13.webp',
        'rarity': 'HIGH_GRADE',
      });
      final charm = CharmDto.fromJson({
        'id': '14',
        'name': 'Charm',
        'charmImage': 'assets/charms/14.webp',
        'rarity': 'HIGH_GRADE',
      });

      expect(pin.collection, isNull);
      expect(graffiti.collection, isNull);
      expect(patch.collection, isNull);
      expect(charm.collection, isNull);
    });
  });
}
