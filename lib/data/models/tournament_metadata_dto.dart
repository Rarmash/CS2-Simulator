class TournamentPlacementDto {
  final String place;
  final String team;
  final String? teamLogo;

  const TournamentPlacementDto({
    required this.place,
    required this.team,
    required this.teamLogo,
  });

  factory TournamentPlacementDto.fromJson(Map<String, dynamic> json) {
    return TournamentPlacementDto(
      place: json['place'] as String,
      team: json['team'] as String,
      teamLogo: json['teamLogo'] as String?,
    );
  }
}

class TournamentStageDateDto {
  final String phase;
  final String? startDate;
  final String? endDate;

  const TournamentStageDateDto({
    required this.phase,
    required this.startDate,
    required this.endDate,
  });

  factory TournamentStageDateDto.fromJson(Map<String, dynamic> json) {
    return TournamentStageDateDto(
      phase: json['phase'] as String,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
    );
  }
}

class TournamentPlayoffMatchDto {
  final String round;
  final String team1;
  final String team2;
  final String? team1Logo;
  final String? team2Logo;
  final String? score1;
  final String? score2;
  final String? date;

  const TournamentPlayoffMatchDto({
    required this.round,
    required this.team1,
    required this.team2,
    required this.team1Logo,
    required this.team2Logo,
    required this.score1,
    required this.score2,
    required this.date,
  });

  factory TournamentPlayoffMatchDto.fromJson(Map<String, dynamic> json) {
    return TournamentPlayoffMatchDto(
      round: json['round'] as String,
      team1: json['team1'] as String,
      team2: json['team2'] as String,
      team1Logo: json['team1Logo'] as String?,
      team2Logo: json['team2Logo'] as String?,
      score1: json['score1'] as String?,
      score2: json['score2'] as String?,
      date: json['date'] as String?,
    );
  }
}

class TournamentMetadataDto {
  final String name;
  final String winner;
  final String? startDate;
  final String? endDate;
  final List<TournamentPlacementDto> placements;
  final List<TournamentStageDateDto> stageDates;
  final List<TournamentPlayoffMatchDto> playoffMatches;

  const TournamentMetadataDto({
    required this.name,
    required this.winner,
    required this.startDate,
    required this.endDate,
    required this.placements,
    required this.stageDates,
    required this.playoffMatches,
  });

  factory TournamentMetadataDto.fromJson(Map<String, dynamic> json) {
    return TournamentMetadataDto(
      name: json['name'] as String,
      winner: json['winner'] as String,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      placements: (json['placements'] as List<dynamic>)
          .map(
            (entry) =>
                TournamentPlacementDto.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
      stageDates: (json['stageDates'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                TournamentStageDateDto.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
      playoffMatches: (json['playoffMatches'] as List<dynamic>? ?? const [])
          .map(
            (entry) => TournamentPlayoffMatchDto.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
