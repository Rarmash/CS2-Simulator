import 'dart:math';

import '../data/models/music_kit_dto.dart';
import 'dropped_music_kit.dart';

class MusicKitSimulatorService {
  final Random _random = Random();

  DroppedMusicKit openContainer({required List<MusicKitDto> musicKits}) {
    if (musicKits.isEmpty) {
      throw Exception('No music kits found for container');
    }

    final selectedMusicKit = musicKits[_random.nextInt(musicKits.length)];
    return DroppedMusicKit(musicKit: selectedMusicKit);
  }
}
