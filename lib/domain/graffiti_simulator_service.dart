import 'dart:math';

import '../data/models/graffiti_dto.dart';
import 'dropped_graffiti.dart';

class GraffitiSimulatorService {
  final Random _random = Random();

  DroppedGraffiti openContainer({required List<GraffitiDto> graffiti}) {
    if (graffiti.isEmpty) {
      throw Exception('No graffiti found for graffiti box');
    }

    final selected = _selectGraffiti(graffiti);
    return DroppedGraffiti(graffiti: selected);
  }

  GraffitiDto _selectGraffiti(List<GraffitiDto> graffiti) {
    final roll = _random.nextDouble();
    final rarity = roll <= 0.7992327
        ? 'BASE_GRADE'
        : roll <= 0.9590792
        ? 'HIGH_GRADE'
        : roll <= 0.990
        ? 'REMARKABLE'
        : 'EXOTIC';

    final filtered = graffiti.where((g) => g.rarity == rarity).toList();
    final pool = filtered.isEmpty ? graffiti : filtered;
    return pool[_random.nextInt(pool.length)];
  }
}
