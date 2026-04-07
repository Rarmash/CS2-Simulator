class TournamentPlayerAppearanceDto {
  final String playerName;
  final String? teamName;
  final String? teamLogo;
  final String? place;
  final String tournamentName;
  final String tournamentImagePath;
  final String? startDate;
  final String? endDate;
  final int autographCount;
  final List<String> effects;
  final String? sampleStickerImage;

  const TournamentPlayerAppearanceDto({
    required this.playerName,
    required this.teamName,
    required this.teamLogo,
    required this.place,
    required this.tournamentName,
    required this.tournamentImagePath,
    required this.startDate,
    required this.endDate,
    required this.autographCount,
    required this.effects,
    required this.sampleStickerImage,
  });
}

class TournamentPlayerSummaryDto {
  final String playerName;
  final int tournamentCount;
  final int autographCount;
  final int titleCount;
  final String? bestPlace;
  final String? latestTournamentName;
  final String? latestTournamentImagePath;
  final String? latestStartDate;
  final String? latestTeamName;
  final String? latestTeamLogo;
  final String? sampleStickerImage;

  const TournamentPlayerSummaryDto({
    required this.playerName,
    required this.tournamentCount,
    required this.autographCount,
    required this.titleCount,
    required this.bestPlace,
    required this.latestTournamentName,
    required this.latestTournamentImagePath,
    required this.latestStartDate,
    required this.latestTeamName,
    required this.latestTeamLogo,
    required this.sampleStickerImage,
  });
}
