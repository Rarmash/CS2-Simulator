import 'package:cs2_simulator/domain/dropped_agent.dart';
import 'package:cs2_simulator/domain/dropped_charm.dart';
import 'package:cs2_simulator/domain/dropped_graffiti.dart';
import 'package:cs2_simulator/domain/dropped_music_kit.dart';
import 'package:cs2_simulator/domain/dropped_patch.dart';
import 'package:cs2_simulator/domain/dropped_pin.dart';
import 'package:cs2_simulator/domain/dropped_sticker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_data_builders.dart';

void main() {
  test('dropped collectible wrappers preserve their underlying dto', () {
    final sticker = DroppedSticker(sticker: buildSticker(id: '1'));
    final musicKit = DroppedMusicKit(musicKit: buildMusicKit(id: '2'));
    final pin = DroppedPin(pin: buildPin(id: '3'));
    final agent = DroppedAgent(agent: buildAgent(id: '4'));
    final graffiti = DroppedGraffiti(graffiti: buildGraffiti(id: '5'));
    final patch = DroppedPatch(patch: buildPatch(id: '6'));
    final charm = DroppedCharm(charm: buildCharm(id: '7'));

    expect(sticker.sticker.id, '1');
    expect(musicKit.musicKit.id, '2');
    expect(pin.pin.id, '3');
    expect(agent.agent.id, '4');
    expect(graffiti.graffiti.id, '5');
    expect(patch.patch.id, '6');
    expect(charm.charm.id, '7');
  });
}
