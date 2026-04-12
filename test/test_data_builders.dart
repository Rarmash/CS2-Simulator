import 'package:cs2_simulator/data/models/skin_dto.dart';
import 'package:cs2_simulator/data/models/sticker_dto.dart';
import 'package:cs2_simulator/data/models/pin_dto.dart';
import 'package:cs2_simulator/data/models/music_kit_dto.dart';
import 'package:cs2_simulator/data/models/graffiti_dto.dart';
import 'package:cs2_simulator/data/models/patch_dto.dart';
import 'package:cs2_simulator/data/models/charm_dto.dart';
import 'package:cs2_simulator/data/models/agent_dto.dart';
import 'package:cs2_simulator/data/models/container_dto.dart';

SkinDto buildSkin({
  required String id,
  String name = 'Test Finish',
  String rarity = 'MIL_SPEC',
  String weaponType = 'RIFLE',
  String itemKind = 'WEAPON',
  String itemId = 'AK_47',
  double floatTop = 0.0,
  double floatBottom = 1.0,
  String? collection = 'Test Collection',
  String? finishCatalogName,
  String? variantName,
  String? phase,
  String? apiPaintIndex,
}) {
  return SkinDto(
    id: id,
    name: name,
    skinImage: 'assets/skins/$id.png',
    floatTop: floatTop,
    floatBottom: floatBottom,
    rarity: rarity,
    weaponType: weaponType,
    itemKind: itemKind,
    itemId: itemId,
    collection: collection,
    finishCatalogName: finishCatalogName,
    variantName: variantName,
    phase: phase,
    apiPaintIndex: apiPaintIndex,
    collectionSourceType: null,
    collectionSourceId: null,
    isRewardCollection: false,
    operationCollectionIds: const [],
    isOperationCollection: false,
  );
}

StickerDto buildSticker({
  required String id,
  String name = 'Test Sticker',
  String rarity = 'HIGH_GRADE',
  String stickerType = 'STICKER',
  String effect = 'OTHER',
  String? collection = 'Test Collection',
  String? tournament,
}) {
  return StickerDto(
    id: id,
    name: name,
    stickerImage: 'assets/stickers/$id.png',
    rarity: rarity,
    stickerType: stickerType,
    effect: effect,
    collection: collection,
    tournament: tournament,
  );
}

PinDto buildPin({
  required String id,
  String name = 'Test Pin',
  String rarity = 'HIGH_GRADE',
  String? collection = 'Test Pins',
}) {
  return PinDto(
    id: id,
    name: name,
    pinImage: 'assets/pins/$id.png',
    rarity: rarity,
    collection: collection,
  );
}

MusicKitDto buildMusicKit({
  required String id,
  String name = 'Artist, Track',
  String rarity = 'HIGH_GRADE',
  String? collection = 'Test Music Kits',
  bool hasRegular = true,
  bool hasStatTrak = false,
}) {
  return MusicKitDto(
    id: id,
    name: name,
    musicKitImage: 'assets/music_kits/$id.png',
    rarity: rarity,
    collection: collection,
    hasRegular: hasRegular,
    hasStatTrak: hasStatTrak,
  );
}

GraffitiDto buildGraffiti({
  required String id,
  String name = 'Test Graffiti',
  String rarity = 'BASE_GRADE',
  String? collection = 'Test Graffiti',
}) {
  return GraffitiDto(
    id: id,
    name: name,
    graffitiImage: 'assets/graffiti/$id.png',
    rarity: rarity,
    collection: collection,
  );
}

PatchDto buildPatch({
  required String id,
  String name = 'Test Patch',
  String rarity = 'HIGH_GRADE',
  String? collection = 'Test Patches',
}) {
  return PatchDto(
    id: id,
    name: name,
    patchImage: 'assets/patches/$id.png',
    rarity: rarity,
    collection: collection,
  );
}

CharmDto buildCharm({
  required String id,
  String name = 'Test Charm',
  String rarity = 'HIGH_GRADE',
  String? collection = 'Test Charms',
}) {
  return CharmDto(
    id: id,
    name: name,
    charmImage: 'assets/charms/$id.png',
    rarity: rarity,
    collection: collection,
  );
}

AgentDto buildAgent({
  required String id,
  String name = 'Test Agent',
  String rarity = 'DISTINGUISHED',
  String? collection = 'Test Agents',
  String team = 'CT',
}) {
  return AgentDto(
    id: id,
    name: name,
    agentImage: 'assets/agents/$id.png',
    rarity: rarity,
    collection: collection,
    team: team,
  );
}

ContainerDto buildContainer({
  required String id,
  String name = 'Test Container',
  String type = 'CASE',
  String? sourceType,
  String? sourceId,
  String? sourceName,
  String? currency,
  int? cost,
}) {
  return ContainerDto(
    id: id,
    name: name,
    containerImage: 'assets/containers/$id.png',
    releaseDate: '2025-01-01',
    type: type,
    sourceType: sourceType,
    sourceId: sourceId,
    sourceName: sourceName,
    tournamentName: null,
    tournamentLogo: null,
    currency: currency,
    cost: cost,
  );
}
