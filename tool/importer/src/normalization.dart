import 'dart:convert';
import 'dart:io';

import 'config.dart';

double safeFloat(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

List<String> sortNumericStr(Iterable<String> values) {
  final list = values.toList();
  list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  return list;
}

String? normalizeReleaseDateString(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return null;
  }

  final normalized = text.split('T').first.trim().replaceAll('/', '-');
  final parts = normalized.split('-');
  if (parts.length != 3) {
    return null;
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }

  return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

String canonicalName(String name) {
  var n = name.trim();
  for (final prefix in [
    'StatTrak™ ',
    'StatTrakв„ў ',
    'Souvenir ',
    '★ ',
    'в… ',
  ]) {
    n = n.replaceAll(prefix, '');
  }
  n = n.replaceAll(
    RegExp(
      r'\s+\((Factory New|Minimal Wear|Field-Tested|Well-Worn|Battle-Scarred)\)$',
    ),
    '',
  );
  return n.trim().toLowerCase();
}

String? normalizeCollectionName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return null;
  }
  final cleaned = name.trim();
  return collectionNameAliases[cleaned] ?? cleaned;
}

String normalizeNameKey(String? value) {
  var text = (value ?? '').trim().toLowerCase();
  text = text.replaceAll('blast.tv', 'blast tv');
  text = text.replaceAll('cs:go', 'csgo');
  text = text.replaceAll('cs2', 'cs 2');
  text = text.replaceAll('kraków', 'krakow');
  text = text.replaceAll('krakгіўw', 'krakow');
  text = text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String makeSafeSlug(String? value) {
  var text = (value ?? '').trim().toLowerCase();
  text = text.replaceAll('blast.tv', 'blast_tv');
  text = text.replaceAll('kraków', 'krakow');
  text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  text = text.replaceAll(RegExp(r'_+'), '_');
  text = text.replaceAll(RegExp(r'^_+|_+$'), '');
  return text.isEmpty ? 'unknown' : text;
}

List<String> tournamentNameCandidates(String? rawName) {
  final text = (rawName ?? '').trim();
  if (text.isEmpty) {
    return const [];
  }

  final candidates = <String>{normalizeNameKey(text)};

  final suffixYear = RegExp(r'^(.*?)(?:\s+)(\d{4})$').firstMatch(text);
  if (suffixYear != null) {
    final left = suffixYear.group(1)!.trim();
    final year = suffixYear.group(2)!.trim();
    candidates.add(normalizeNameKey('$year $left'));
  }

  final prefixYear = RegExp(r'^(\d{4})(?:\s+)(.*)$').firstMatch(text);
  if (prefixYear != null) {
    final year = prefixYear.group(1)!.trim();
    final right = prefixYear.group(2)!.trim();
    candidates.add(normalizeNameKey('$right $year'));
  }

  return candidates.where((item) => item.isNotEmpty).toList();
}

String? inferTournamentNameFromSouvenirPackage(String crateName) {
  final name = crateName.trim();
  if (!name.toLowerCase().endsWith('souvenir package')) {
    return null;
  }

  final base = name
      .replaceAll(RegExp(r'\s+souvenir package$', caseSensitive: false), '')
      .trim();
  if (base.isEmpty) {
    return null;
  }

  final knownSuffixes = [...mapSuffixes]
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final suffix in knownSuffixes) {
    if (base.toLowerCase().endsWith(' ${suffix.toLowerCase()}')) {
      return base.substring(0, base.length - suffix.length - 1).trim();
    }
  }

  final parts = base.split(RegExp(r'\s+'));
  if (parts.length >= 3) {
    return parts.sublist(0, parts.length - 1).join(' ').trim();
  }

  return base;
}

String? inferTournamentContainerDate(String crateName) {
  final name = crateName.trim();
  final normalized = normalizeNameKey(name);
  final known = tournamentContainerStartDates.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final tournamentName in known) {
    final normalizedTournamentName = normalizeNameKey(tournamentName);
    if (name.startsWith('$tournamentName ') ||
        name == tournamentName ||
        normalized.contains(normalizedTournamentName)) {
      return tournamentContainerStartDates[tournamentName];
    }
  }

  return null;
}

List<String> expandTournamentNameVariants(String? name) {
  if (name == null || name.isEmpty) {
    return const [];
  }

  final variants = <String>[name];
  final alias = tournamentNameAliases[name];
  if (alias != null && !variants.contains(alias)) {
    variants.add(alias);
  }

  for (final entry in tournamentNameAliases.entries) {
    if (entry.value == name && !variants.contains(entry.key)) {
      variants.add(entry.key);
    }
  }

  return variants;
}

(String, String) splitItemAndSkin(String fullName) {
  var name = fullName.trim();
  for (final prefix in ['★ ', 'в… ']) {
    if (name.startsWith(prefix)) {
      name = name.substring(prefix.length).trim();
      break;
    }
  }

  final index = name.indexOf(' | ');
  if (index != -1) {
    return (name.substring(0, index).trim(), name.substring(index + 3).trim());
  }

  return (name.trim(), 'Vanilla');
}

(String, String, String) inferItemKindAndId(String baseItemName) {
  if (glovesIdMap.containsKey(baseItemName)) {
    return ('GLOVES', glovesIdMap[baseItemName]!, 'GLOVES');
  }

  if (knifeIdMap.containsKey(baseItemName)) {
    return ('KNIFE', knifeIdMap[baseItemName]!, 'KNIFE');
  }

  if (weaponIdMap.containsKey(baseItemName)) {
    return (
      'WEAPON',
      weaponIdMap[baseItemName]!,
      inferWeaponTypeFromWeaponName(baseItemName),
    );
  }

  throw StateError('Unknown item base name: $baseItemName');
}

String inferWeaponTypeFromWeaponName(String name) {
  const pistols = {
    'CZ75-Auto',
    'Desert Eagle',
    'Dual Berettas',
    'Five-SeveN',
    'Glock-18',
    'P2000',
    'P250',
    'R8 Revolver',
    'Tec-9',
    'USP-S',
    'Zeus x27',
  };
  const smgs = {'MAC-10', 'MP5-SD', 'MP7', 'MP9', 'PP-Bizon', 'P90', 'UMP-45'};
  const shotguns = {'MAG-7', 'Nova', 'Sawed-Off', 'XM1014'};
  const machineGuns = {'M249', 'Negev'};
  const rifles = {
    'FAMAS',
    'Galil AR',
    'M4A4',
    'M4A1-S',
    'AK-47',
    'AUG',
    'SG 553',
  };
  const snipers = {'SSG 08', 'AWP', 'SCAR-20', 'G3SG1'};

  if (pistols.contains(name)) {
    return name == 'Zeus x27' ? 'EQUIPMENT' : 'PISTOL';
  }
  if (smgs.contains(name)) {
    return 'SMG';
  }
  if (shotguns.contains(name)) {
    return 'SHOTGUN';
  }
  if (machineGuns.contains(name)) {
    return 'MACHINE_GUN';
  }
  if (rifles.contains(name)) {
    return 'RIFLE';
  }
  if (snipers.contains(name)) {
    return 'SNIPER_RIFLE';
  }

  throw StateError('Cannot infer weapon type for: $name');
}

bool isSupportedContainer(Map<String, dynamic> crate) {
  final crateType = (crate['type'] ?? '').toString().trim();
  final crateName = (crate['name'] ?? '').toString().trim();
  final lowerName = crateName.toLowerCase();
  final lowerType = crateType.toLowerCase();

  if (containerTypeOverrides.containsKey(crateName)) {
    return true;
  }
  if (crateType == 'Case') {
    return true;
  }
  if (crateType == 'Souvenir Package') {
    return true;
  }
  if (lowerName.contains('souvenir package')) {
    return true;
  }
  if (lowerName.contains('collection package')) {
    return true;
  }
  if (crateType == 'Pins' || lowerType.contains('pins')) {
    return true;
  }
  if (crateType == 'Graffiti' || lowerType.contains('graffiti')) {
    return true;
  }
  if (crateType == 'Patch Capsule' || lowerType.contains('patch capsule')) {
    return true;
  }
  if (lowerName.contains('patch') || lowerType.contains('patch')) {
    return false;
  }
  if (crateType == 'Music Kit Box' || lowerType.contains('music kit box')) {
    return true;
  }
  if (lowerName.contains('capsule')) {
    return true;
  }
  if (lowerName.contains('terminal') || lowerType.contains('terminal')) {
    return true;
  }
  if (lowerName.contains('x-ray') || lowerName.contains('xray')) {
    return true;
  }

  return false;
}

String inferContainerType(String? crateName, String? crateType) {
  final name = (crateName ?? '').trim();
  final type = (crateType ?? '').trim();

  if (containerTypeOverrides.containsKey(name)) {
    return containerTypeOverrides[name]!;
  }

  final lowerName = name.toLowerCase();
  final lowerType = type.toLowerCase();

  if (lowerName.contains('terminal') || lowerType.contains('terminal')) {
    return 'TERMINAL';
  }
  if (lowerName.contains('x-ray') || lowerName.contains('xray')) {
    return 'XRAY_PACKAGE';
  }
  if (lowerName.contains('souvenir package') ||
      lowerType.contains('souvenir package')) {
    return 'SOUVENIR_PACKAGE';
  }
  if (lowerName.contains('collection package') ||
      lowerType.contains('collection package')) {
    return 'COLLECTION_PACKAGE';
  }
  if (type == 'Pins' || lowerType.contains('pins')) {
    return 'PIN_CAPSULE';
  }
  if (type == 'Graffiti' || lowerType.contains('graffiti')) {
    return 'GRAFFITI_BOX';
  }
  if (lowerName.endsWith('patch collection')) {
    return 'PATCH_COLLECTION';
  }
  if (lowerName.endsWith('patch pack')) {
    return 'PATCH_PACK';
  }
  if (type == 'Patch Capsule' || lowerType.contains('patch capsule')) {
    return 'PATCH_PACK';
  }
  if (type == 'Music Kit Box' || lowerType.contains('music kit box')) {
    return 'MUSIC_KIT_BOX';
  }
  if (lowerName.endsWith('sticker collection')) {
    return 'STICKER_COLLECTION';
  }
  if (lowerName.contains('capsule')) {
    return 'STICKER_CAPSULE';
  }

  return 'CASE';
}

int _crc32(String input) {
  var crc = 0xffffffff;
  for (final byte in utf8.encode(input)) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      final mask = -(crc & 1);
      crc = (crc >> 1) ^ (0xedb88320 & mask);
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

String makeStableNumericId(String sourceId, int prefix) {
  final digits = RegExp(
    r'\d+',
  ).allMatches(sourceId).map((match) => match.group(0)!).join();
  if (digits.isNotEmpty) {
    return BigInt.parse(digits).toString();
  }

  final value = _crc32(sourceId) % 100000000;
  return (prefix + value).toString();
}

String makeHashedNumericId(String sourceId, int prefix) {
  final value = _crc32(sourceId) % 100000000;
  return (prefix + value).toString();
}

String existingCaseKey(Map<String, dynamic> item) =>
    (item['name'] ?? '').toString().trim();

String fullSkinNameKey(String name) => canonicalName(name);

String rewardKeyFromItem(Map<String, dynamic> item) =>
    normalizeCollectionName((item['name'] ?? '').toString().trim()) ?? '';

String operationKey(String name, String operationId) =>
    '$operationId::${normalizeCollectionName(name) ?? name}';

(String, String, String, String) existingSkinKey(Map<String, dynamic> skin) => (
  (skin['itemKind'] ?? '').toString(),
  (skin['itemId'] ?? '').toString(),
  canonicalName((skin['name'] ?? '').toString()),
  canonicalName(((skin['phase'] ?? skin['variantName']) ?? '').toString()),
);

(String, String, String, String) existingStickerKey(
  Map<String, dynamic> sticker,
) => (
  canonicalName((sticker['name'] ?? '').toString()),
  (sticker['stickerType'] ?? '').toString().trim().toUpperCase(),
  (sticker['effect'] ?? '').toString().trim().toUpperCase(),
  canonicalName(
    ((sticker['collection'] ?? sticker['tournament']) ?? '').toString(),
  ),
);

(String, String) existingPinKey(Map<String, dynamic> pin) => (
  canonicalName((pin['name'] ?? '').toString()),
  canonicalName((pin['collection'] ?? '').toString()),
);

(String, String, bool) existingMusicKitKey(Map<String, dynamic> musicKit) => (
  canonicalName((musicKit['name'] ?? '').toString()),
  canonicalName((musicKit['collection'] ?? '').toString()),
  musicKit['isStatTrak'] == true,
);

(String, String, String) existingAgentKey(Map<String, dynamic> agent) => (
  canonicalName((agent['name'] ?? '').toString()),
  canonicalName((agent['collection'] ?? '').toString()),
  (agent['team'] ?? '').toString().trim().toUpperCase(),
);

(String, String) existingGraffitiKey(Map<String, dynamic> graffiti) => (
  canonicalName((graffiti['name'] ?? '').toString()),
  canonicalName((graffiti['collection'] ?? '').toString()),
);

(String, String) existingPatchKey(Map<String, dynamic> patch) => (
  canonicalName((patch['name'] ?? '').toString()),
  canonicalName((patch['collection'] ?? '').toString()),
);

(String?, String?) chooseCollectionNameAndImage(Map<String, dynamic> meta) {
  final collections = meta['collections'];
  if (collections is List &&
      collections.isNotEmpty &&
      collections.first is Map) {
    final first = (collections.first as Map).map(
      (k, v) => MapEntry(k.toString(), v),
    );
    final rawName = first['name'];
    final rawImage = first['image'];
    return (normalizeCollectionName(rawName?.toString()), rawImage?.toString());
  }

  return (null, null);
}

String? chooseImageUrl(Map<String, dynamic> meta) {
  final image = meta['image'];
  return image?.toString();
}

String normalizeStickerName(String name) {
  final normalized = name.trim();
  final index = normalized.indexOf(' | ');
  return index == -1 ? normalized : normalized.substring(index + 3).trim();
}

String inferStickerType(Map<String, dynamic> meta) {
  final rawType = (meta['type'] ?? '').toString().trim().toLowerCase();
  if (rawType == 'autograph') {
    return 'AUTOGRAPH';
  }
  if (rawType == 'event') {
    return 'EVENT';
  }
  return 'STICKER';
}

String inferStickerContainerType(String? crateName) {
  final name = (crateName ?? '').trim();
  if (containerTypeOverrides.containsKey(name)) {
    return containerTypeOverrides[name]!;
  }

  final lower = name.toLowerCase();
  if (lower.endsWith('sticker collection') || lower.endsWith('sticker pack')) {
    return 'STICKER_COLLECTION';
  }

  return 'STICKER_CAPSULE';
}

String? inferPinCollection(String? crateName) {
  var name = (crateName ?? '').trim();
  if (name.isEmpty) {
    return null;
  }

  final match = RegExp(
    r'^Collectible Pins Capsule Series (\d+)$',
  ).firstMatch(name);
  if (match != null) {
    return 'Series ${match.group(1)!}';
  }

  name = name.replaceAll(RegExp(r'\s+Collectible Pins Capsule$'), '').trim();
  name = name.replaceAll(RegExp(r'\s+Pins Capsule$'), '').trim();
  return name.isEmpty ? null : name;
}

bool shouldCreateGenuinePin({
  required String pinName,
  required String? pinCollection,
}) {
  final collection = (pinCollection ?? '').trim();
  if (collection == 'Series 1' ||
      collection == 'Series 2' ||
      collection == 'Series 3') {
    return true;
  }

  return collection == 'Half-Life: Alyx' && pinName.trim() == 'Alyx Pin';
}

String? inferMusicKitCollection(String? crateName) {
  var name = (crateName ?? '').trim();
  if (name.isEmpty) {
    return null;
  }

  for (final prefix in ['StatTrak™ ', 'StatTrakв„ў ']) {
    name = name.replaceAll(prefix, '');
  }
  name = name.replaceAll(RegExp(r'\s+Music Kit Box$'), '').trim();
  name = name.replaceAll(RegExp(r'\s+Box$'), '').trim();
  return name.isEmpty ? null : name;
}

String? inferGraffitiCollection(String? crateName) {
  var name = (crateName ?? '').trim();
  if (name.isEmpty) {
    return null;
  }
  name = name.replaceAll(RegExp(r'\s+Graffiti Box$'), '').trim();
  return name.isEmpty ? null : name;
}

String? inferPatchCollection(String? crateName) {
  var name = (crateName ?? '').trim();
  if (name.isEmpty) {
    return null;
  }
  name = name.replaceAll(RegExp(r'\s+Patch Pack$'), '').trim();
  name = name.replaceAll(RegExp(r'\s+Patch Collection$'), '').trim();
  return name.isEmpty ? null : name;
}

String normalizeGraffitiName(String name) {
  final normalized = name.trim();
  final index = normalized.indexOf(' | ');
  return index == -1 ? normalized : normalized.substring(index + 3).trim();
}

String normalizePatchName(String name) {
  return name.replaceFirst(RegExp(r'^Patch\s+\|\s+'), '').trim();
}

Map<String, String?> resolveAgentCollectionSource(String? collectionName) {
  final normalized = (collectionName ?? '').trim();
  final source = agentCollectionSourceOverrides[normalized] ?? const {};

  String? value(String key) {
    final raw = source[key];
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw.trim();
  }

  return {
    'operationId': value('operationId'),
    'operationName': value('operationName'),
    'releaseDate': value('releaseDate'),
  };
}

(String, bool) normalizeMusicKitName(String? name) {
  var normalized = (name ?? '').trim();
  final isStatTrak =
      normalized.startsWith('StatTrak™ ') ||
      normalized.startsWith('StatTrakв„ў ');

  if (normalized.startsWith('StatTrak™ ')) {
    normalized = normalized.substring('StatTrak™ '.length).trim();
  }
  if (normalized.startsWith('StatTrakв„ў ')) {
    normalized = normalized.substring('StatTrakв„ў '.length).trim();
  }
  if (normalized.startsWith('Music Kit | ')) {
    normalized = normalized.substring('Music Kit | '.length).trim();
  }

  normalized = switch (normalized) {
    'TWERL and Ekko & Sidetrack, Under Bright Lights' =>
      'TWERL, Ekko & Sidetrack, Under Bright Lights',
    _ => normalized,
  };

  return (normalized, isStatTrak);
}

Map<String, String?> resolveStickerCollectionSource(String? collectionName) {
  final normalized = (collectionName ?? '').trim();
  final source = stickerCollectionSourceOverrides[normalized] ?? const {};

  String? value(String key) {
    final raw = source[key];
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw.trim();
  }

  final sourceType = value('sourceType');
  final sourceId = value('sourceId');
  final sourceName = value('sourceName');

  return {
    'sourceType': sourceType,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'operationId': sourceId,
    'operationName': sourceName,
    'releaseDate': value('releaseDate'),
  };
}

Map<String, String?> resolvePatchCollectionSource(String? collectionName) {
  final normalized = (collectionName ?? '').trim();
  final source = patchCollectionSourceOverrides[normalized] ?? const {};

  String? value(String key) {
    final raw = source[key];
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw.trim();
  }

  return {
    'sourceType': value('sourceType'),
    'sourceId': value('sourceId'),
    'sourceName': value('sourceName'),
    'releaseDate': value('releaseDate'),
  };
}

String? getExplicitPhase(Map<String, dynamic> meta) {
  if (meta['phase'] != null) {
    return meta['phase'].toString();
  }

  final original = meta['original'];
  if (original is Map && original['phase'] != null) {
    return original['phase'].toString();
  }

  return null;
}

(String?, String?) extractPhaseAndVariant({
  required String fullSkinName,
  required String? patternName,
  required String? explicitPhase,
}) {
  final cleanedPattern = (patternName ?? '').trim();
  final cleanedPhase = (explicitPhase ?? '').trim();
  final cleanedFullName = fullSkinName.trim();

  if (cleanedPhase.isNotEmpty) {
    return (cleanedPhase, cleanedPhase);
  }
  if (cleanedPattern.isEmpty) {
    return (null, null);
  }
  if (canonicalName(cleanedFullName) == canonicalName(cleanedPattern)) {
    return (null, null);
  }

  final prefix = '$cleanedPattern ';
  if (cleanedFullName.startsWith(prefix)) {
    final suffix = cleanedFullName.substring(prefix.length).trim();
    if (suffix.isNotEmpty) {
      return (suffix, suffix);
    }
  }

  return (null, null);
}

Map<String, String> buildCollectionImageMap(
  List<Map<String, dynamic>> skinsData,
) {
  final result = <String, String>{};
  for (final skinMeta in skinsData) {
    final pair = chooseCollectionNameAndImage(skinMeta);
    if (pair.$1 != null && pair.$2 != null && !result.containsKey(pair.$1!)) {
      result[pair.$1!] = pair.$2!;
    }
  }
  return result;
}

Map<String, Map<String, String>> buildCollectionMetaMap(
  List<Map<String, dynamic>> collectionsData,
) {
  final result = <String, Map<String, String>>{};

  for (final collection in collectionsData) {
    final collectionName = normalizeCollectionName(
      (collection['name'] ?? '').toString().trim(),
    );
    final collectionImage = (collection['image'] ?? '').toString().trim();
    final crates = collection['crates'];

    if (collectionName == null || collectionImage.isEmpty || crates is! List) {
      continue;
    }

    for (final crate in crates) {
      if (crate is! Map) {
        continue;
      }
      final crateName = (crate['name'] ?? '').toString().trim();
      if (crateName.isEmpty) {
        continue;
      }
      result.putIfAbsent(
        crateName,
        () => {'name': collectionName, 'image': collectionImage},
      );
    }
  }

  return result;
}

Map<String, String> buildTournamentLogoMap(
  List<Map<String, dynamic>> stickersData,
) {
  final result = <String, String>{};

  for (final sticker in stickersData) {
    final tournament = sticker['tournament'];
    final image = (sticker['image'] ?? '').toString().trim();
    final stickerType = (sticker['type'] ?? '').toString().trim().toLowerCase();

    if (tournament is! Map || image.isEmpty || stickerType != 'event') {
      continue;
    }

    final tournamentName = (tournament['name'] ?? '').toString().trim();
    if (tournamentName.isEmpty) {
      continue;
    }

    for (final key in tournamentNameCandidates(tournamentName)) {
      result.putIfAbsent(key, () => image);
    }
  }

  return result;
}

String resolveContainerReleaseDate({
  required String crateName,
  required String containerType,
  Map<String, dynamic>? crateMeta,
  Object? existingReleaseDate,
}) {
  final explicit = containerReleaseDateOverrides[crateName];
  if (explicit != null) {
    return explicit;
  }

  final tournamentDate = inferTournamentContainerDate(crateName);
  if (tournamentDate != null) {
    return tournamentDate;
  }

  return normalizeReleaseDateString(existingReleaseDate) ?? '2000-01-01';
}

String? findExistingLogoPathBySlug(String logoSlug) {
  for (final ext in ['.png', '.svg', '.webp', '.jpg']) {
    final candidate = File('${tournamentLogosDir.path}/$logoSlug$ext');
    if (candidate.existsSync()) {
      return 'assets/tournament_logos/$logoSlug$ext';
    }
  }
  return null;
}

(String?, String?) resolveSouvenirLogoAndName(
  String crateName,
  Map<String, String> tournamentLogoByName,
) {
  final parsedName = inferTournamentNameFromSouvenirPackage(crateName);
  if (parsedName == null) {
    return (null, null);
  }

  for (final variant in expandTournamentNameVariants(parsedName)) {
    for (final key in tournamentNameCandidates(variant)) {
      final logoUrl = tournamentLogoByName[key];
      if (logoUrl != null) {
        return (variant, logoUrl);
      }
    }
  }

  return (parsedName, null);
}

List<Map<String, dynamic>> buildContents(
  Map<String, Set<String>> source,
  String idKey,
  String itemKey,
) {
  final out = source.entries
      .where((entry) => entry.value.isNotEmpty)
      .map(
        (entry) => <String, dynamic>{
          idKey: entry.key,
          itemKey: sortNumericStr(entry.value),
        },
      )
      .toList();
  out.sort(
    (a, b) => int.parse(
      a[idKey].toString(),
    ).compareTo(int.parse(b[idKey].toString())),
  );
  return out;
}

String suffixFromPath(String path) {
  final dot = path.lastIndexOf('.');
  return dot == -1 ? '.png' : path.substring(dot);
}

String basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final slash = normalized.lastIndexOf('/');
  return slash == -1 ? normalized : normalized.substring(slash + 1);
}
