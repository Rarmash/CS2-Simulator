class TournamentDto {
  final String name;
  final String imagePath;
  final String? releaseDate;
  final String? startDate;
  final String? endDate;
  final String organizer;
  final int souvenirPackageCount;
  final int stickerContainerCount;

  const TournamentDto({
    required this.name,
    required this.imagePath,
    required this.releaseDate,
    required this.startDate,
    required this.endDate,
    required this.organizer,
    required this.souvenirPackageCount,
    required this.stickerContainerCount,
  });

  int? get year {
    final match = RegExp(r'(20\d{2}|201\d)').allMatches(name).lastOrNull;
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  bool get isCs2Era => (year ?? 0) >= 2023;

  String get eraLabel => isCs2Era ? 'CS2 Era' : 'CS:GO Era';
}

class TournamentTeamResultDto {
  final String teamName;
  final String? teamLogo;
  final String tournamentName;
  final String tournamentImagePath;
  final String organizer;
  final String place;
  final String? startDate;
  final String? endDate;

  const TournamentTeamResultDto({
    required this.teamName,
    required this.teamLogo,
    required this.tournamentName,
    required this.tournamentImagePath,
    required this.organizer,
    required this.place,
    required this.startDate,
    required this.endDate,
  });
}

class TournamentTeamSummaryDto {
  final String teamName;
  final String? teamLogo;
  final int tournamentCount;
  final int titleCount;
  final String? bestPlace;
  final String? latestTournamentName;
  final String? latestTournamentImagePath;
  final String? latestStartDate;

  const TournamentTeamSummaryDto({
    required this.teamName,
    required this.teamLogo,
    required this.tournamentCount,
    required this.titleCount,
    required this.bestPlace,
    required this.latestTournamentName,
    required this.latestTournamentImagePath,
    required this.latestStartDate,
  });
}
