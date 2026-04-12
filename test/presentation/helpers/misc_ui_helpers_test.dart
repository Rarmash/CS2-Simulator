import 'package:cs2_simulator/data/models/music_kit_group_dto.dart';
import 'package:cs2_simulator/presentation/helpers/agent_ui_helper.dart';
import 'package:cs2_simulator/presentation/helpers/charm_ui_helper.dart';
import 'package:cs2_simulator/presentation/helpers/graffiti_ui_helper.dart';
import 'package:cs2_simulator/presentation/helpers/music_kit_ui_helper.dart';
import 'package:cs2_simulator/presentation/helpers/patch_ui_helper.dart';
import 'package:cs2_simulator/presentation/helpers/pin_ui_helper.dart';
import 'package:cs2_simulator/presentation/helpers/responsive_grid_helper.dart';
import 'package:cs2_simulator/presentation/helpers/source_color_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_data_builders.dart';

void main() {
  group('SourceColorHelper', () {
    test('returns expected reward and operation colors', () {
      expect(
        SourceColorHelper.rewardSourceColor(isArmory: true),
        Colors.deepPurpleAccent,
      );
      expect(
        SourceColorHelper.rewardSourceColor(isArmory: false),
        Colors.amber,
      );
      expect(SourceColorHelper.operationColor('BRAVO'), Colors.greenAccent);
      expect(SourceColorHelper.operationColor('UNKNOWN'), Colors.blueGrey);
    });

    test('maps container and collectible source types to colors', () {
      expect(
        SourceColorHelper.containerTypeColor('PATCH_PACK'),
        Colors.pinkAccent,
      );
      expect(
        SourceColorHelper.containerTypeColor('CHARM_COLLECTION'),
        Colors.deepOrangeAccent,
      );
      expect(
        SourceColorHelper.collectibleSourceColor('ARMORY_REWARD', null),
        Colors.deepPurpleAccent,
      );
      expect(
        SourceColorHelper.collectibleSourceColor('GENERAL', null),
        Colors.blueGrey,
      );
      expect(
        SourceColorHelper.collectibleSourceColor('UNKNOWN', null),
        Colors.white24,
      );
    });
  });

  group('MusicKitUiHelper', () {
    test('formats mixed-variant music kits with StatTrak text', () {
      final musicKit = buildMusicKit(
        id: '1',
        hasRegular: true,
        hasStatTrak: true,
        collection: 'Masterminds 2',
      );

      expect(MusicKitUiHelper.typeLabel(musicKit), 'Music Kit / StatTrak™');
      expect(
        MusicKitUiHelper.secondaryText(musicKit),
        'Music Kit / StatTrak™ | Both variants | Masterminds 2',
      );
    });

    test('formats grouped music kit secondary text', () {
      final group = MusicKitGroupDto.fromVariants([
        buildMusicKit(
          id: '1',
          name: 'Austin Wintory, The Devil Went Clubbing In Georgia',
          collection: 'Masterminds 2',
          hasRegular: true,
          hasStatTrak: false,
        ),
        buildMusicKit(
          id: '2',
          name: 'Austin Wintory, The Devil Went Clubbing In Georgia',
          collection: 'Masterminds 2',
          hasRegular: false,
          hasStatTrak: true,
        ),
      ]);

      expect(
        MusicKitUiHelper.groupedSecondaryText(group),
        'Austin Wintory | Music Kit / StatTrak™ | Both variants | Masterminds 2',
      );
    });
  });

  group('Collectible UI helpers', () {
    test('returns readable labels and secondary text', () {
      expect(
        PinUiHelper.rarityLabel(buildPin(id: '1', rarity: 'EXTRAORDINARY')),
        'Extraordinary',
      );
      expect(
        PinUiHelper.secondaryText(
          buildPin(id: '2', rarity: 'GENUINE', collection: null),
        ),
        'Genuine Pin',
      );
      expect(
        AgentUiHelper.secondaryText(
          buildAgent(id: '3', team: 'COUNTER-TERRORIST'),
        ),
        'CT Side',
      );
      expect(
        CharmUiHelper.secondaryText(buildCharm(id: '4', collection: null)),
        'Charm',
      );
      expect(
        GraffitiUiHelper.secondaryText(
          buildGraffiti(id: '5', collection: null),
        ),
        'Graffiti',
      );
      expect(
        PatchUiHelper.secondaryText(buildPatch(id: '6', collection: null)),
        'Patch',
      );
    });

    test('returns expected rarity colors for collectible helpers', () {
      expect(
        PinUiHelper.rarityColor(buildPin(id: '1', rarity: 'EXTRAORDINARY')),
        const Color(0xFFEB4B4B),
      );
      expect(
        AgentUiHelper.rarityColor(buildAgent(id: '2', rarity: 'MASTER')),
        const Color(0xFFEB4B4B),
      );
      expect(
        CharmUiHelper.rarityColor(buildCharm(id: '3', rarity: 'EXOTIC')),
        const Color(0xFFD32CE6),
      );
      expect(
        GraffitiUiHelper.rarityColor(
          buildGraffiti(id: '4', rarity: 'BASE_GRADE'),
        ),
        const Color(0xFFB0C3D9),
      );
      expect(
        PatchUiHelper.rarityColor(buildPatch(id: '5', rarity: 'REMARKABLE')),
        const Color(0xFF8847FF),
      );
    });
  });

  group('ResponsiveGridHelper', () {
    test('uses expected breakpoints for list layout', () {
      expect(ResponsiveGridHelper.listCrossAxisCount(500), 1);
      expect(ResponsiveGridHelper.listCrossAxisCount(800), 2);
      expect(ResponsiveGridHelper.listCrossAxisCount(1200), 3);
      expect(ResponsiveGridHelper.listCrossAxisCount(1600), 4);

      expect(ResponsiveGridHelper.listChildAspectRatio(500), 2.25);
      expect(ResponsiveGridHelper.listChildAspectRatio(800), 1.35);
      expect(ResponsiveGridHelper.listChildAspectRatio(1200), 1.45);
    });

    test('uses expected breakpoints for skin and trade grids', () {
      expect(ResponsiveGridHelper.skinGridCrossAxisCount(550), 2);
      expect(ResponsiveGridHelper.skinGridCrossAxisCount(650), 3);
      expect(ResponsiveGridHelper.skinGridCrossAxisCount(950), 4);
      expect(ResponsiveGridHelper.skinGridCrossAxisCount(1250), 5);
      expect(ResponsiveGridHelper.skinGridCrossAxisCount(1600), 6);

      expect(ResponsiveGridHelper.skinGridChildAspectRatio(550), 0.7);
      expect(ResponsiveGridHelper.skinGridChildAspectRatio(650), 0.74);
      expect(ResponsiveGridHelper.skinGridChildAspectRatio(950), 0.78);
      expect(ResponsiveGridHelper.skinGridChildAspectRatio(1250), 0.82);

      expect(ResponsiveGridHelper.tradeGridCrossAxisCount(500), 3);
      expect(ResponsiveGridHelper.tradeGridCrossAxisCount(700), 4);
      expect(ResponsiveGridHelper.tradeGridCrossAxisCount(900), 5);
      expect(ResponsiveGridHelper.tradeGridCrossAxisCount(1200), 6);
      expect(ResponsiveGridHelper.tradeGridCrossAxisCount(1500), 7);
    });
  });
}
