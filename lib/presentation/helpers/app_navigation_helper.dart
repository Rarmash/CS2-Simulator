import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/models/case_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../screens/case_open_screen.dart';
import '../screens/graffiti_box_open_screen.dart';
import '../screens/music_kit_box_open_screen.dart';
import '../screens/patch_container_open_screen.dart';
import '../screens/pin_container_open_screen.dart';
import '../screens/sticker_container_open_screen.dart';

class AppNavigationHelper {
  const AppNavigationHelper._();

  static Future<T?> pushScreen<T>(BuildContext context, Widget screen) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static Widget buildContainerOpenScreen({
    required CaseDto caseDto,
    required LocalDataRepository repository,
    SettingsController? settingsController,
  }) {
    if (caseDto.isStickerCapsule || caseDto.isStickerCollection) {
      return StickerContainerOpenScreen(
        caseDto: caseDto,
        repository: repository,
      );
    }
    if (caseDto.isPinCapsule) {
      return PinContainerOpenScreen(
        caseDto: caseDto,
        repository: repository,
      );
    }
    if (caseDto.isMusicKitBox) {
      return MusicKitBoxOpenScreen(
        caseDto: caseDto,
        repository: repository,
      );
    }
    if (caseDto.isGraffitiBox) {
      return GraffitiBoxOpenScreen(
        caseDto: caseDto,
        repository: repository,
      );
    }
    if (caseDto.isPatchPack) {
      return PatchContainerOpenScreen(
        caseDto: caseDto,
        repository: repository,
      );
    }

    assert(
      settingsController != null || !caseDto.isRegularCase,
      'settingsController is required for regular case screens.',
    );

    return CaseOpenScreen(
      caseDto: caseDto,
      repository: repository,
      settingsController: settingsController!,
    );
  }
}
