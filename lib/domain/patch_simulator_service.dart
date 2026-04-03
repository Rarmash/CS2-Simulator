import 'dart:math';

import '../data/models/patch_dto.dart';
import 'dropped_patch.dart';

class PatchSimulatorService {
  final Random _random = Random();

  DroppedPatch openContainer({required List<PatchDto> patches}) {
    if (patches.isEmpty) {
      throw Exception('No patches found for patch container');
    }

    final selected = _selectPatch(patches);
    return DroppedPatch(patch: selected);
  }

  PatchDto _selectPatch(List<PatchDto> patches) {
    final roll = _random.nextDouble();
    final rarity = switch (roll) {
      <= 0.7992327 => 'HIGH_GRADE',
      <= 0.9590792 => 'REMARKABLE',
      _ => 'EXOTIC',
    };

    final filtered = patches.where((p) => p.rarity == rarity).toList();
    final pool = filtered.isEmpty ? patches : filtered;
    return pool[_random.nextInt(pool.length)];
  }
}
