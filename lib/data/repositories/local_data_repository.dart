import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/case_content_dto.dart';
import '../models/case_dto.dart';
import '../models/skin_dto.dart';

class LocalDataRepository {
  Future<List<CaseDto>> loadCases() async {
    final raw = await rootBundle.loadString('assets/data/cases.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final cases =
    list.map((e) => CaseDto.fromJson(e as Map<String, dynamic>)).toList();

    cases.sort((a, b) {
      final ad = a.releaseDate ?? '9999/99/99';
      final bd = b.releaseDate ?? '9999/99/99';
      return ad.compareTo(bd);
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

  Future<Map<String, List<String>>> loadCaseToSkinIds() async {
    final caseContents = await loadCaseContents();
    return {
      for (final entry in caseContents) entry.caseId: List<String>.from(entry.skinIds),
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

  int _rarityOrder(SkinDto skin) {
    if (skin.isSpecialItem) return 6; // ножи/перчи после красных пушек

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