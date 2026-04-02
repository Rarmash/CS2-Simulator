import 'package:flutter/material.dart';

class SourceColorHelper {
  static Color rewardSourceColor({required bool isArmory}) {
    return isArmory ? Colors.deepPurpleAccent : Colors.amber;
  }

  static Color operationColor(String operationId) {
    switch (operationId) {
      case 'SHATTERED_WEB':
        return Colors.deepPurpleAccent;
      case 'BLOODHOUND':
        return Colors.redAccent;
      case 'BREAKOUT':
        return Colors.lightBlueAccent;
      case 'PHOENIX':
        return Colors.orangeAccent;
      case 'BRAVO':
        return Colors.greenAccent;
      case 'PAYBACK':
        return Colors.blueAccent;
      default:
        return Colors.blueGrey;
    }
  }

  static Color containerTypeColor(String type) {
    switch (type) {
      case 'SOUVENIR_PACKAGE':
        return Colors.amber;
      case 'COLLECTION_PACKAGE':
        return Colors.lightBlueAccent;
      case 'STICKER_CAPSULE':
        return Colors.orangeAccent;
      case 'STICKER_COLLECTION':
        return Colors.tealAccent;
      case 'PIN_CAPSULE':
        return Colors.cyanAccent;
      case 'MUSIC_KIT_BOX':
        return Colors.greenAccent;
      case 'GRAFFITI_BOX':
        return Colors.lightGreenAccent;
      case 'PATCH_PACK':
        return Colors.pinkAccent;
      case 'PATCH_COLLECTION':
        return Colors.pinkAccent;
      case 'TERMINAL':
        return Colors.deepPurpleAccent;
      case 'XRAY_PACKAGE':
        return Colors.greenAccent;
      case 'CASE':
      default:
        return Colors.blueAccent;
    }
  }

  static Color collectibleSourceColor(String? sourceType, String? sourceId) {
    switch (sourceType) {
      case 'OPERATION_REWARD':
        return rewardSourceColor(isArmory: false);
      case 'ARMORY_REWARD':
        return rewardSourceColor(isArmory: true);
      case 'LEGACY_OPERATION':
        return operationColor(sourceId ?? '');
      case 'GENERAL':
        return Colors.blueGrey;
      default:
        return Colors.white24;
    }
  }
}
