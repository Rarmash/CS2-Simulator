import 'package:flutter/material.dart';

class SourceColorHelper {
  static Color rewardSourceColor({
    required bool isArmory,
  }) {
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
      case 'TERMINAL':
        return Colors.deepPurpleAccent;
      case 'XRAY_PACKAGE':
        return Colors.greenAccent;
      case 'CASE':
      default:
        return Colors.blueAccent;
    }
  }
}