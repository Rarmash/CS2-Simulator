import 'dart:math';

import '../data/models/charm_dto.dart';
import 'dropped_charm.dart';

class CharmCollectionSimulatorService {
  final Random _random = Random();

  DroppedCharm openCollection({required List<CharmDto> charms}) {
    if (charms.isEmpty) {
      throw Exception('No charms found for charm collection');
    }

    return DroppedCharm(charm: _selectCharm(charms));
  }

  CharmDto _selectCharm(List<CharmDto> charms) {
    final roll = _random.nextDouble();
    final rarity = switch (roll) {
      <= 0.7992327 => 'HIGH_GRADE',
      <= 0.9590792 => 'REMARKABLE',
      <= 0.9910475 => 'EXTRAORDINARY',
      _ => 'EXOTIC',
    };

    final filtered = charms.where((charm) => charm.rarity == rarity).toList();
    final pool = filtered.isEmpty ? charms : filtered;
    return pool[_random.nextInt(pool.length)];
  }
}
