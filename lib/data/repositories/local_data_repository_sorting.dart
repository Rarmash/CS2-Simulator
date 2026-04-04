part of 'local_data_repository.dart';

int _compareByReleaseDateAsc(String? a, String? b) {
  final left = a ?? '9999-99-99';
  final right = b ?? '9999-99-99';
  return left.compareTo(right);
}

int _compareCaseByReleaseDateAsc(CaseDto a, CaseDto b) {
  final byDate = _compareByReleaseDateAsc(a.releaseDate, b.releaseDate);
  if (byDate != 0) return byDate;
  return a.name.compareTo(b.name);
}

int _compareNamedReleaseDateAsc(dynamic a, dynamic b) {
  final byDate = _compareByReleaseDateAsc(
    a.releaseDate as String?,
    b.releaseDate as String?,
  );
  if (byDate != 0) return byDate;
  return (a.name as String).compareTo(b.name as String);
}

int _compareOperationCollectionAsc(
  OperationCollectionDto a,
  OperationCollectionDto b,
) {
  final byOperation = a.operationName.compareTo(b.operationName);
  if (byOperation != 0) return byOperation;

  final byDate = _compareByReleaseDateAsc(a.releaseDate, b.releaseDate);
  if (byDate != 0) return byDate;

  return a.name.compareTo(b.name);
}

int _compareCollectibleCollectionAsc(CaseDto a, CaseDto b) {
  final sourceA = a.sourceType ?? '';
  final sourceB = b.sourceType ?? '';
  final bySource = sourceA.compareTo(sourceB);
  if (bySource != 0) return bySource;

  final byDate = _compareByReleaseDateAsc(a.releaseDate, b.releaseDate);
  if (byDate != 0) return byDate;

  return a.name.compareTo(b.name);
}

int _rarityOrder(SkinDto skin) {
  if (skin.isSpecialItem) return 7;

  switch (skin.rarity) {
    case 'CONSUMER':
      return 0;
    case 'INDUSTRIAL':
      return 1;
    case 'MIL_SPEC':
      return 2;
    case 'RESTRICTED':
      return 3;
    case 'CLASSIFIED':
      return 4;
    case 'COVERT':
      return 5;
    case 'CONTRABAND':
      return 6;
    case 'EXTRAORDINARY':
      return 7;
    default:
      return 999;
  }
}

int _stickerRarityOrder(StickerDto sticker) {
  switch (sticker.rarity) {
    case 'HIGH_GRADE':
      return 0;
    case 'REMARKABLE':
      return 1;
    case 'EXOTIC':
      return 2;
    case 'EXTRAORDINARY':
      return 3;
    case 'CONTRABAND':
      return 4;
    default:
      return 999;
  }
}

int _pinRarityOrder(PinDto pin) {
  switch (pin.rarity) {
    case 'HIGH_GRADE':
      return 0;
    case 'REMARKABLE':
      return 1;
    case 'EXOTIC':
      return 2;
    case 'EXTRAORDINARY':
      return 3;
    default:
      return 999;
  }
}

int _musicKitRarityOrder(MusicKitDto musicKit) {
  switch (musicKit.rarity) {
    case 'HIGH_GRADE':
      return 0;
    default:
      return 999;
  }
}

int _agentRarityOrder(AgentDto agent) {
  switch (agent.rarity) {
    case 'DISTINGUISHED':
      return 0;
    case 'EXCEPTIONAL':
      return 1;
    case 'SUPERIOR':
      return 2;
    case 'MASTER':
      return 3;
    default:
      return 99;
  }
}

int _graffitiRarityOrder(GraffitiDto graffiti) {
  switch (graffiti.rarity) {
    case 'BASE_GRADE':
      return 0;
    case 'HIGH_GRADE':
      return 1;
    case 'REMARKABLE':
      return 2;
    case 'EXOTIC':
      return 3;
    default:
      return 99;
  }
}

int _patchRarityOrder(PatchDto patch) {
  switch (patch.rarity) {
    case 'HIGH_GRADE':
      return 0;
    case 'REMARKABLE':
      return 1;
    case 'EXOTIC':
      return 2;
    default:
      return 99;
  }
}

int _charmRarityOrder(CharmDto charm) {
  switch (charm.rarity) {
    case 'HIGH_GRADE':
      return 0;
    case 'REMARKABLE':
      return 1;
    case 'EXOTIC':
      return 2;
    case 'EXTRAORDINARY':
      return 3;
    default:
      return 99;
  }
}
