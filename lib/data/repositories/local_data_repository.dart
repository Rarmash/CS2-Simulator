import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/case_content_dto.dart';
import '../models/case_dto.dart';
import '../models/operation_collection_content_dto.dart';
import '../models/operation_collection_dto.dart';
import '../models/reward_collection_content_dto.dart';
import '../models/reward_collection_dto.dart';
import '../models/skin_dto.dart';

class LocalDataRepository {
  Future<List<CaseDto>> loadCases() async {
    final raw = await rootBundle.loadString('assets/data/cases.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final cases =
    list.map((e) => CaseDto.fromJson(e as Map<String, dynamic>)).toList();

    cases.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return cases;
  }

  Future<List<SkinDto>> loadSkins() async {
    final raw = await rootBundle.loadString('assets/data/skins.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => SkinDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CaseContentDto>> loadCaseContents() async {
    final raw = await rootBundle.loadString('assets/data/case_contents.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CaseContentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RewardCollectionDto>> loadRewardCollections() async {
    final raw =
    await rootBundle.loadString('assets/data/reward_collections.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final items = list
        .map((e) => RewardCollectionDto.fromJson(e as Map<String, dynamic>))
        .toList();

    items.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<List<RewardCollectionContentDto>> loadRewardCollectionContents() async {
    final raw =
    await rootBundle.loadString('assets/data/reward_collection_contents.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) => RewardCollectionContentDto.fromJson(e as Map<String, dynamic>),
    )
        .toList();
  }

  Future<List<OperationCollectionDto>> loadOperationCollections() async {
    final raw =
    await rootBundle.loadString('assets/data/operation_collections.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final items = list
        .map((e) => OperationCollectionDto.fromJson(e as Map<String, dynamic>))
        .toList();

    items.sort((a, b) {
      final byOperation = a.operationName.compareTo(b.operationName);
      if (byOperation != 0) return byOperation;

      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;

      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<List<OperationCollectionContentDto>>
  loadOperationCollectionContents() async {
    final raw = await rootBundle
        .loadString('assets/data/operation_collection_contents.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) =>
          OperationCollectionContentDto.fromJson(e as Map<String, dynamic>),
    )
        .toList();
  }

  Future<Map<String, List<String>>> loadCaseToSkinIds() async {
    final caseContents = await loadCaseContents();
    return {
      for (final entry in caseContents)
        entry.caseId: List<String>.from(entry.skinIds),
    };
  }

  Future<Map<String, List<String>>> loadRewardCollectionToSkinIds() async {
    final contents = await loadRewardCollectionContents();
    return {
      for (final entry in contents)
        entry.rewardCollectionId: List<String>.from(entry.skinIds),
    };
  }

  Future<Map<String, List<String>>> loadOperationCollectionToSkinIds() async {
    final contents = await loadOperationCollectionContents();
    return {
      for (final entry in contents)
        entry.operationCollectionId: List<String>.from(entry.skinIds),
    };
  }

  Future<List<SkinDto>> loadSkinsForCase(String caseId) async {
    final skins = await loadSkins();
    final contents = await loadCaseContents();
    final content = contents.firstWhere((c) => c.caseId == caseId);
    final ids = content.skinIds.toSet();

    final result = skins.where((s) => ids.contains(s.id)).toList();

    result.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  Future<List<SkinDto>> loadSkinsForRewardCollection(
      String rewardCollectionId,
      ) async {
    final skins = await loadSkins();
    final contents = await loadRewardCollectionContents();
    final content = contents.firstWhere(
          (c) => c.rewardCollectionId == rewardCollectionId,
    );
    final ids = content.skinIds.toSet();

    final result = skins
        .where((s) => ids.contains(s.id) && !s.isSpecialItem)
        .toList();

    result.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  Future<List<SkinDto>> loadSkinsForOperationCollection(
      String operationCollectionId,
      ) async {
    final skins = await loadSkins();
    final contents = await loadOperationCollectionContents();
    final content = contents.firstWhere(
          (c) => c.operationCollectionId == operationCollectionId,
    );
    final ids = content.skinIds.toSet();

    final result = skins
        .where((s) => ids.contains(s.id) && !s.isSpecialItem)
        .toList();

    result.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return result;
  }

  int _rarityOrder(SkinDto skin) {
    if (skin.isSpecialItem) return 6;

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
      case 'CONTRABAND':
        return 5;
      case 'EXTRAORDINARY':
        return 6;
      default:
        return 999;
    }
  }
}