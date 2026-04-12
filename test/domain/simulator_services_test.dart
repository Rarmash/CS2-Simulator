import 'package:cs2_simulator/domain/agent_collection_simulator_service.dart';
import 'package:cs2_simulator/domain/charm_collection_simulator_service.dart';
import 'package:cs2_simulator/domain/container_simulator_service.dart';
import 'package:cs2_simulator/domain/graffiti_simulator_service.dart';
import 'package:cs2_simulator/domain/music_kit_simulator_service.dart';
import 'package:cs2_simulator/domain/operation_collection_simulator_service.dart';
import 'package:cs2_simulator/domain/patch_simulator_service.dart';
import 'package:cs2_simulator/domain/pin_simulator_service.dart';
import 'package:cs2_simulator/domain/reward_collection_simulator_service.dart';
import 'package:cs2_simulator/domain/sticker_simulator_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_data_builders.dart';

void main() {
  group('Opening simulator services', () {
    test('ContainerSimulatorService throws for invalid inputs', () {
      final service = ContainerSimulatorService();

      expect(
        () => service.openCase(
          skins: const [],
          containerDto: buildContainer(id: '1'),
        ),
        throwsException,
      );

      expect(
        () => service.openCase(
          skins: [buildSkin(id: '10')],
          containerDto: buildContainer(id: '2', type: 'TERMINAL'),
        ),
        throwsException,
      );
    });

    test('xray package reveals the guaranteed first skin', () {
      final service = ContainerSimulatorService();
      final first = buildSkin(id: '11', floatTop: 0.05, floatBottom: 0.07);
      final second = buildSkin(id: '12');

      final drop = service.openCase(
        skins: [first, second],
        containerDto: buildContainer(id: '3', type: 'XRAY_PACKAGE'),
      );

      expect(drop.skin.id, '11');
      expect(drop.isStatTrak, isFalse);
      expect(drop.isSouvenir, isFalse);
    });

    test('terminal offers build requested number of offers', () {
      final service = ContainerSimulatorService();
      final offers = service.buildTerminalOffers(
        skins: [
          buildSkin(id: '13', rarity: 'MIL_SPEC'),
          buildSkin(id: '14', rarity: 'RESTRICTED'),
        ],
        count: 3,
      );

      expect(offers, hasLength(3));
      expect(offers.first.offerIndex, 1);
      expect(offers.last.offerIndex, 3);
    });

    test(
      'sticker simulator throws on empty input and returns provided sticker',
      () {
        final service = StickerSimulatorService();
        expect(
          () => service.openContainer(stickers: const []),
          throwsException,
        );

        final sticker = buildSticker(id: '21');
        final drop = service.openContainer(stickers: [sticker]);
        expect(drop.sticker.id, '21');
      },
    );

    test(
      'music kit simulator throws on empty input and returns provided kit',
      () {
        final service = MusicKitSimulatorService();
        expect(
          () => service.openContainer(musicKits: const []),
          throwsException,
        );

        final kit = buildMusicKit(id: '31');
        final drop = service.openContainer(musicKits: [kit]);
        expect(drop.musicKit.id, '31');
      },
    );

    test('pin simulator throws on empty input and returns provided pin', () {
      final service = PinSimulatorService();
      expect(() => service.openContainer(pins: const []), throwsException);

      final pin = buildPin(id: '41');
      final drop = service.openContainer(pins: [pin]);
      expect(drop.pin.id, '41');
    });

    test(
      'graffiti simulator throws on empty input and returns provided graffiti',
      () {
        final service = GraffitiSimulatorService();
        expect(
          () => service.openContainer(graffiti: const []),
          throwsException,
        );

        final graffiti = buildGraffiti(id: '51');
        final drop = service.openContainer(graffiti: [graffiti]);
        expect(drop.graffiti.id, '51');
      },
    );

    test(
      'patch simulator throws on empty input and returns provided patch',
      () {
        final service = PatchSimulatorService();
        expect(() => service.openContainer(patches: const []), throwsException);

        final patch = buildPatch(id: '61');
        final drop = service.openContainer(patches: [patch]);
        expect(drop.patch.id, '61');
      },
    );

    test('reward and operation collection simulators reject empty pools', () {
      expect(
        () => RewardCollectionSimulatorService().openRewardCollection(
          skins: const [],
          collection: buildContainer(id: '71', type: 'REWARD_COLLECTION'),
        ),
        throwsException,
      );

      expect(
        () => OperationCollectionSimulatorService().openCollection(
          skins: const [],
          collection: buildContainer(id: '72', type: 'OPERATION_COLLECTION'),
        ),
        throwsException,
      );
    });

    test(
      'agent and charm simulators reject empty pools and return entries',
      () {
        expect(
          () => AgentCollectionSimulatorService().openCollection(
            agents: const [],
            collection: buildContainer(id: '81', type: 'AGENT_COLLECTION'),
          ),
          throwsException,
        );
        expect(
          () => CharmCollectionSimulatorService().openCollection(
            charms: const [],
          ),
          throwsException,
        );

        final agentDrop = AgentCollectionSimulatorService().openCollection(
          agents: [buildAgent(id: '82')],
          collection: buildContainer(id: '82', type: 'AGENT_COLLECTION'),
        );
        final charmDrop = CharmCollectionSimulatorService().openCollection(
          charms: [buildCharm(id: '83')],
        );

        expect(agentDrop.agent.id, '82');
        expect(charmDrop.charm.id, '83');
      },
    );
  });
}
