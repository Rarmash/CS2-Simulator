import 'package:flutter/foundation.dart';

import '../../data/models/skin_dto.dart';
import '../../domain/tradeup_service.dart';

class TradeUpController extends ChangeNotifier {
  final TradeUpService service;
  final List<TradeUpInputItem> selected = [];

  TradeUpResult? result;
  List<TradeUpChance> chances = [];
  String? tradeIssue;

  TradeUpController({TradeUpService? service})
    : service = service ?? TradeUpService();

  int maxSelectable() {
    if (selected.isEmpty) return 10;
    return selected.first.skin.rarity == 'COVERT' ? 5 : 10;
  }

  bool get canAddMore => selected.length < maxSelectable();

  bool get tradeReady {
    if (selected.isEmpty) return false;
    final rarity = selected.first.skin.rarity;
    if (rarity == 'COVERT') {
      return selected.length == 5;
    }
    return selected.length == 10;
  }

  bool get canExecuteTrade => tradeReady && tradeIssue == null;

  void add(
    SkinDto skin, {
    required List<SkinDto> allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    if (!canAddMore) return;
    if (selected.isNotEmpty && selected.first.skin.rarity != skin.rarity) {
      throw Exception('All selected skins must have the same rarity');
    }

    selected.add(
      TradeUpInputItem(
        skin: skin,
        floatValue: (skin.floatTop + skin.floatBottom) / 2,
      ),
    );
    result = null;
    _recalculate(
      allSkins: allSkins,
      skinIdToRegularCaseIds: skinIdToRegularCaseIds,
      regularCaseIdToSkinIds: regularCaseIdToSkinIds,
    );
    notifyListeners();
  }

  void updateItem(
    int index, {
    double? floatValue,
    TradeUpInputQuality? quality,
    required List<SkinDto> allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    selected[index] = selected[index].copyWith(
      floatValue: floatValue,
      quality: quality,
    );
    result = null;
    _recalculate(
      allSkins: allSkins,
      skinIdToRegularCaseIds: skinIdToRegularCaseIds,
      regularCaseIdToSkinIds: regularCaseIdToSkinIds,
    );
    notifyListeners();
  }

  void removeAt(
    int index, {
    required List<SkinDto> allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    selected.removeAt(index);
    result = null;
    _recalculate(
      allSkins: allSkins,
      skinIdToRegularCaseIds: skinIdToRegularCaseIds,
      regularCaseIdToSkinIds: regularCaseIdToSkinIds,
    );
    notifyListeners();
  }

  void clear() {
    selected.clear();
    result = null;
    chances = [];
    tradeIssue = null;
    notifyListeners();
  }

  void executeTrade({
    required List<SkinDto> allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    result = service.tradeUp(
      input: selected,
      allSkins: allSkins,
      skinIdToRegularCaseIds: skinIdToRegularCaseIds,
      regularCaseIdToSkinIds: regularCaseIdToSkinIds,
    );
    notifyListeners();
  }

  void _recalculate({
    required List<SkinDto> allSkins,
    required Map<String, List<String>> skinIdToRegularCaseIds,
    required Map<String, List<String>> regularCaseIdToSkinIds,
  }) {
    tradeIssue = service.validationIssue(
      input: selected,
      skinIdToRegularCaseIds: skinIdToRegularCaseIds,
    );

    if (tradeReady && tradeIssue == null) {
      chances = service.getTradeUpChances(
        input: selected,
        allSkins: allSkins,
        skinIdToRegularCaseIds: skinIdToRegularCaseIds,
        regularCaseIdToSkinIds: regularCaseIdToSkinIds,
      );
      if (chances.isEmpty) {
        tradeIssue = 'This selection cannot produce a valid trade-up result';
      }
    } else {
      chances = [];
    }
  }
}
