import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/models/container_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../screens/agent_collection_open_screen.dart';
import '../screens/container_open_screen.dart';
import '../screens/charm_collection_open_screen.dart';
import '../screens/graffiti_box_open_screen.dart';
import '../screens/music_kit_box_open_screen.dart';
import '../screens/operation_collection_open_screen.dart';
import '../screens/patch_container_open_screen.dart';
import '../screens/pin_container_open_screen.dart';
import '../screens/reward_collection_open_screen.dart';
import '../screens/sticker_container_open_screen.dart';
import '../screens/terminal_open_screen.dart';

class AppNavigationHelper {
  const AppNavigationHelper._();

  static Future<T?> pushScreen<T>(BuildContext context, Widget screen) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static Widget buildContainerOpenScreen({
    required ContainerDto containerDto,
    required LocalDataRepository repository,
    SettingsController? settingsController,
  }) {
    if (containerDto.isStickerCapsule || containerDto.isStickerCollection) {
      return StickerContainerOpenScreen(
        containerDto: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isPinCapsule) {
      return PinContainerOpenScreen(
        containerDto: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isMusicKitBox) {
      return MusicKitBoxOpenScreen(
        containerDto: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isGraffitiBox) {
      return GraffitiBoxOpenScreen(
        containerDto: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isPatchPack) {
      return PatchContainerOpenScreen(
        containerDto: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isCharmCollection) {
      return CharmCollectionOpenScreen(
        collection: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isAgentCollection) {
      return AgentCollectionOpenScreen(
        collection: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isRewardCollection) {
      return RewardCollectionOpenScreen(
        collection: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isOperationCollection) {
      return OperationCollectionOpenScreen(
        collection: containerDto,
        repository: repository,
      );
    }
    if (containerDto.isTerminal) {
      return TerminalOpenScreen(
        containerDto: containerDto,
        repository: repository,
      );
    }

    assert(
      settingsController != null || !containerDto.isRegularCase,
      'settingsController is required for regular case screens.',
    );

    return ContainerOpenScreen(
      containerDto: containerDto,
      repository: repository,
      settingsController: settingsController,
    );
  }
}
