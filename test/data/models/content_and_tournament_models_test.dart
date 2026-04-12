import 'package:cs2_simulator/data/models/container_content_dto.dart';
import 'package:cs2_simulator/data/models/music_kit_content_dto.dart';
import 'package:cs2_simulator/data/models/sticker_content_dto.dart';
import 'package:cs2_simulator/data/models/tournament_dto.dart';
import 'package:cs2_simulator/data/models/tournament_metadata_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('content DTOs', () {
    test('parse ids and legacy music kit content payloads', () {
      final containerContent = ContainerContentDto.fromJson({
        'containerId': '100',
        'skinIds': ['1', '2'],
      });
      final stickerContent = StickerContentDto.fromJson({
        'containerId': '200',
        'stickerIds': ['3', '4'],
      });
      final musicKitContent = MusicKitContentDto.fromJson({
        'containerId': '300',
        'musicKitIds': ['5', '6'],
      });

      expect(containerContent.skinIds, ['1', '2']);
      expect(stickerContent.stickerIds, ['3', '4']);
      expect(musicKitContent.items.length, 2);
      expect(musicKitContent.items.first.hasRegular, isTrue);
      expect(musicKitContent.items.first.hasStatTrak, isFalse);
    });

    test('parse structured music kit content entries', () {
      final musicKitContent = MusicKitContentDto.fromJson({
        'containerId': '301',
        'items': [
          {'musicKitId': '7', 'hasRegular': true, 'hasStatTrak': false},
          {'musicKitId': '8', 'hasRegular': false, 'hasStatTrak': true},
        ],
      });

      expect(musicKitContent.items.first.musicKitId, '7');
      expect(musicKitContent.items.last.hasStatTrak, isTrue);
    });
  });

  group('tournament DTOs', () {
    test('infers year and era from tournament name', () {
      const csGo = TournamentDto(
        name: 'DreamHack Winter 2014',
        imagePath: 'assets/tournament_logos/dhw2014.png',
        releaseDate: '2014-11-27',
        startDate: '2014-11-27',
        endDate: '2014-11-29',
        organizer: 'DreamHack',
        souvenirPackageCount: 1,
        stickerContainerCount: 0,
      );
      const cs2 = TournamentDto(
        name: 'PGL Copenhagen 2024',
        imagePath: 'assets/tournament_logos/pgl2024.png',
        releaseDate: '2024-03-17',
        startDate: '2024-03-17',
        endDate: '2024-03-31',
        organizer: 'PGL',
        souvenirPackageCount: 1,
        stickerContainerCount: 2,
      );

      expect(csGo.year, 2014);
      expect(csGo.eraLabel, 'CS:GO Era');
      expect(cs2.year, 2024);
      expect(cs2.eraLabel, 'CS2 Era');
    });

    test('parses tournament metadata, rosters, and stage dates', () {
      final metadata = TournamentMetadataDto.fromJson({
        'name': 'BLAST.tv Austin 2025',
        'winner': 'Team Vitality',
        'tournamentLogo': 'assets/tournament_logos/austin2025.png',
        'startDate': '2025-06-03',
        'endDate': '2025-06-22',
        'placements': [
          {
            'place': '1st',
            'team': 'Team Vitality',
            'teamLogo': 'assets/tournament_logos/team_vitality.png',
          },
        ],
        'teamRosters': [
          {
            'team': 'Team Vitality',
            'teamLogo': 'assets/tournament_logos/team_vitality.png',
            'players': ['apEX', 'ZywOo', '', 'flameZ'],
          },
        ],
        'stageDates': [
          {
            'phase': 'Playoffs',
            'startDate': '2025-06-19',
            'endDate': '2025-06-22',
          },
        ],
        'playoffMatches': [
          {
            'round': 'Grand Final',
            'team1': 'Team Vitality',
            'team2': 'The MongolZ',
            'score1': '2',
            'score2': '1',
          },
        ],
      });

      expect(metadata.placements.single.team, 'Team Vitality');
      expect(metadata.teamRosters.single.players, ['apEX', 'ZywOo', 'flameZ']);
      expect(metadata.stageDates.single.phase, 'Playoffs');
      expect(metadata.playoffMatches.single.round, 'Grand Final');
    });
  });
}
