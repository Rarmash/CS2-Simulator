import 'dart:convert';
import 'dart:io';

const _userAgent = 'CS2-Simulator tournament importer/0.11';
const _liquipediaApiBase = 'https://liquipedia.net/counterstrike/api.php';
const _liquipediaRawBase =
    'https://liquipedia.net/counterstrike/index.php?action=raw&title=';
const _liquipediaRenderBase =
    'https://liquipedia.net/counterstrike/index.php?action=render&title=';

const _pageTitleOverrides = <String, String>{
  'BLAST.tv Austin 2025': 'BLAST/Major/2025/Austin',
  'BLAST.tv Paris 2023': 'BLAST/Major/2023/Paris',
  'DreamHack Cluj-Napoca 2015': 'DreamHack/2015/Cluj-Napoca',
  'DreamHack Winter 2013': 'DreamHack/2013/Winter',
  'DreamHack Winter 2014': 'DreamHack/2014/Winter',
  'ELEAGUE Atlanta 2017': 'ELEAGUE/2017/Major',
  'ELEAGUE Boston 2018': 'ELEAGUE/2018/Major',
  'EMS One Katowice 2014': 'ESL/Major_Series_One/2014/Katowice',
  'ESL One Cologne 2014': 'ESL/One/2014/Cologne',
  'ESL One Cologne 2015': 'ESL/One/2015/Cologne',
  'ESL One Cologne 2016': 'ESL/One/2016/Cologne',
  'ESL One Katowice 2015': 'ESL/One/2015/Katowice',
  'FACEIT London 2018': 'FACEIT/2018/Major',
  'IEM Katowice 2019': 'Intel_Extreme_Masters/Season_XIII/World_Championship',
  'IEM Rio 2022': 'Intel_Extreme_Masters/2022/Rio',
  'MLG Columbus 2016': 'MLG/2016/Columbus',
  'PGL Antwerp 2022': 'PGL/2022/Antwerp',
  'PGL Copenhagen 2024': 'PGL/2024/Copenhagen',
  'PGL Kraków 2017': 'PGL/2017/Krakow',
  'PGL Stockholm 2021': 'PGL/2021/Stockholm',
  'Perfect World Shanghai 2024': 'Perfect_World/Major/2024/Shanghai',
  'StarLadder Berlin 2019': 'StarLadder/2019/Major',
  'StarLadder Budapest 2025': 'StarLadder/2025/Major',
};

Future<void> main() async {
  final client = HttpClient()
    ..userAgent = _userAgent
    ..autoUncompress = true;

  final containersFile = File('assets/data/containers.json');
  final metadataFile = File('assets/data/tournament_metadata.json');

  if (!containersFile.existsSync()) {
    stderr.writeln('assets/data/containers.json not found.');
    exit(1);
  }

  final containers =
      (jsonDecode(await containersFile.readAsString()) as List<dynamic>)
          .whereType<Map>()
          .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
          .toList();

  final existingMetadata = metadataFile.existsSync()
      ? (jsonDecode(await metadataFile.readAsString()) as List<dynamic>)
            .whereType<Map>()
            .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
            .toList()
      : <Map<String, dynamic>>[];

  final existingByName = {
    for (final entry in existingMetadata)
      _canonicalTournamentName((entry['name'] ?? '').toString()): entry,
  };

  final tournamentNames =
      containers
          .map((entry) => (entry['tournamentName'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .map(_canonicalTournamentName)
          .toSet()
          .toList()
        ..sort();

  final results = <Map<String, dynamic>>[];

  for (final tournamentName in tournamentNames) {
    stdout.writeln('Importing tournament metadata: $tournamentName');

    final existing = existingByName[tournamentName];
    try {
      final pageTitle = await _resolvePageTitle(client, tournamentName);
      final rawPage = await _fetchPage(client, 'raw', pageTitle);
      final renderedPage = await _fetchPage(client, 'render', pageTitle);
      final tournamentLogo = await _materializeTournamentLogo(
        client,
        tournamentName,
        await _extractPreferredTournamentLogo(client, rawPage, renderedPage) ??
            (existing?['tournamentLogo'] as String?),
      );
      final tournamentDates = _parseStartEndDates(renderedPage);
      final stagePages = _stagePagesForTournament(pageTitle, tournamentName);

      final importedPlacements = _parsePlacementsFromRenderedHtml(renderedPage);
      final placements = _hasValidPlacements(importedPlacements)
          ? importedPlacements
          : _readExistingPlacements(existing);
      final winner = _readWinner(placements, existing);
      final playoffMatches = _parsePlayoffMatchesFromRenderedHtml(
        _playoffPageTitle(pageTitle, tournamentName) == pageTitle
            ? renderedPage
            : await _fetchPage(
                client,
                'render',
                _playoffPageTitle(pageTitle, tournamentName),
              ),
      );
      await _materializeTeamLogos(client, placements, playoffMatches);
      final teamRosters = _parseTeamRostersFromRawPage(rawPage, placements);
      final stageDates = <Map<String, String>>[];
      for (final stagePage in stagePages) {
        try {
          final stageRawPage = await _fetchPage(
            client,
            'raw',
            stagePage.pageTitle,
          );
          final stageRange = _parseHiddenDataBoxDates(stageRawPage);
          if ((stageRange.$1 ?? '').isEmpty && (stageRange.$2 ?? '').isEmpty) {
            continue;
          }
          stageDates.add({
            'phase': stagePage.phase,
            if ((stageRange.$1 ?? '').isNotEmpty) 'startDate': stageRange.$1!,
            if ((stageRange.$2 ?? '').isNotEmpty) 'endDate': stageRange.$2!,
          });
        } catch (_) {
          // Keep partial metadata if a stage page is missing or shaped differently.
        }
      }

      results.add({
        'name': tournamentName,
        'winner': winner,
        if ((tournamentLogo ?? '').isNotEmpty) 'tournamentLogo': tournamentLogo,
        if ((tournamentDates.$1 ?? '').isNotEmpty)
          'startDate': tournamentDates.$1,
        if ((tournamentDates.$2 ?? '').isNotEmpty)
          'endDate': tournamentDates.$2,
        'placements': placements,
        'teamRosters': teamRosters,
        'stageDates': stageDates,
        'playoffMatches': playoffMatches,
      });
    } catch (error) {
      stdout.writeln('  [WARN] $tournamentName: $error');
      if (existing != null) {
        results.add(existing);
      } else {
        results.add({
          'name': tournamentName,
          'winner': '',
          'tournamentLogo': existing?['tournamentLogo'],
          'startDate': null,
          'endDate': null,
          'placements': const <Map<String, String>>[],
          'teamRosters': const <Map<String, dynamic>>[],
          'stageDates': const <Map<String, String>>[],
          'playoffMatches': const <Map<String, String>>[],
        });
      }
    }
  }

  final encoder = const JsonEncoder.withIndent('  ');
  await metadataFile.writeAsString('${encoder.convert(results)}\n');
  stdout.writeln('Tournament metadata written: ${results.length} tournaments');
}

Future<String> _resolvePageTitle(
  HttpClient client,
  String tournamentName,
) async {
  final override = _pageTitleOverrides[tournamentName];
  if (override != null) {
    return override;
  }

  final yearMatch = RegExp(r'(20\d{2})').firstMatch(tournamentName);
  final year = yearMatch?.group(1);
  final query = Uri.encodeQueryComponent('$tournamentName Counter-Strike');
  final uri = Uri.parse(
    '$_liquipediaApiBase?action=query&list=search&srsearch=$query&format=json',
  );
  final json = await _fetchJson(client, uri);
  final search = ((json['query'] as Map?)?['search'] as List?) ?? const [];

  for (final result in search.whereType<Map>()) {
    final title = result['title']?.toString() ?? '';
    if (title.isEmpty) {
      continue;
    }
    if (year != null && !title.contains(year)) {
      continue;
    }
    if (title.contains('/')) {
      return title;
    }
  }

  throw StateError('No Liquipedia page found for $tournamentName');
}

Future<String> _fetchPage(
  HttpClient client,
  String mode,
  String pageTitle,
) async {
  final base = mode == 'render' ? _liquipediaRenderBase : _liquipediaRawBase;
  final accept = mode == 'render' ? 'text/html' : 'text/plain';
  final uri = Uri.parse('$base${Uri.encodeQueryComponent(pageTitle)}');
  final request = await client.getUrl(uri);
  request.headers.set(HttpHeaders.acceptHeader, accept);
  final response = await request.close();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('HTTP ${response.statusCode}', uri: uri);
  }
  return utf8.decoder.bind(response).join();
}

Future<Map<String, dynamic>> _fetchJson(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  request.headers.set(HttpHeaders.acceptHeader, 'application/json');
  request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
  final response = await request.close();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('HTTP ${response.statusCode}', uri: uri);
  }
  final body = await utf8.decoder.bind(response).join();
  return (jsonDecode(body) as Map).cast<String, dynamic>();
}

List<Map<String, String>> _parsePlacementsFromRenderedHtml(
  String renderedPage,
) {
  final section = _extractHtmlSection(renderedPage, 'Prize_Pool');
  if (section == null || section.isEmpty) {
    return const [];
  }

  final tableIndex = section.indexOf('prizepooltable-placement');
  if (tableIndex < 0) {
    return const [];
  }

  final placeCells = RegExp(
    r'<div class="csstable-widget-cell prizepooltable-place"[^>]*>(.*?)</div>',
    dotAll: true,
  ).allMatches(section.substring(tableIndex)).toList();

  final placements = <Map<String, String>>[];
  final tableHtml = section.substring(tableIndex);

  for (var index = 0; index < placeCells.length; index++) {
    final current = placeCells[index];
    final nextStart = index + 1 < placeCells.length
        ? placeCells[index + 1].start
        : tableHtml.length;
    final chunk = tableHtml.substring(current.start, nextStart);

    final place = _normalizePlace(_cleanHtmlText(current.group(1)!));
    if (place.isEmpty) {
      continue;
    }

    final teams = _parseTeamBlocks(chunk);

    for (final teamEntry in teams) {
      final team = teamEntry.$1;
      final logo = teamEntry.$2;
      if (team.isEmpty) {
        continue;
      }
      placements.add({
        'place': place,
        'team': team,
        if ((logo ?? '').isNotEmpty) 'teamLogo': logo!,
      });
    }
  }

  return placements;
}

List<Map<String, dynamic>> _parseTeamRostersFromRawPage(
  String rawPage,
  List<Map<String, String>> placements,
) {
  final start = rawPage.indexOf('==Participants==');
  if (start < 0) {
    return const [];
  }

  final afterStart = rawPage.substring(start);
  final resultsIndex = afterStart.indexOf('\n==Results==');
  final section = resultsIndex < 0
      ? afterStart
      : afterStart.substring(0, resultsIndex);

  final rosterBlocks = _extractTemplateBlocks(section, '{{TeamCard');
  if (rosterBlocks.isEmpty) {
    return const [];
  }

  final placementLogoByTeam = <String, String?>{
    for (final placement in placements)
      placement['team']!: placement['teamLogo'],
  };
  final rosters = <Map<String, dynamic>>[];
  final seenTeams = <String>{};

  for (final block in rosterBlocks) {
    final team = _extractTemplateField(block, 'team')?.trim() ?? '';
    if (team.isEmpty || !seenTeams.add(team)) {
      continue;
    }

    final players = <String>[];
    for (var i = 1; i <= 5; i++) {
      final player = _extractTemplateField(block, 'p$i')?.trim() ?? '';
      if (player.isEmpty) continue;
      players.add(_cleanWikiValue(player));
    }

    if (players.isEmpty) {
      continue;
    }

    rosters.add({
      'team': _cleanWikiValue(team),
      if ((placementLogoByTeam[_cleanWikiValue(team)] ?? '').isNotEmpty)
        'teamLogo': placementLogoByTeam[_cleanWikiValue(team)],
      'players': players,
    });
  }

  return rosters;
}

(String?, String?) _parseStartEndDates(String renderedPage) {
  final startDate = _extractInfoboxValue(renderedPage, 'Start Date:');
  final endDate = _extractInfoboxValue(renderedPage, 'End Date:');
  return (startDate, endDate);
}

(String?, String?) _parseHiddenDataBoxDates(String rawPage) {
  final sdate = _extractTemplateField(rawPage, 'sdate');
  final edate = _extractTemplateField(rawPage, 'edate');
  return (sdate, edate);
}

List<_StagePageRef> _stagePagesForTournament(
  String basePageTitle,
  String tournamentName,
) {
  final phases = _allowedStagePhases(tournamentName);
  return phases
      .map(
        (phase) =>
            _StagePageRef(pageTitle: '$basePageTitle/$phase', phase: phase),
      )
      .toList();
}

String _playoffPageTitle(String basePageTitle, String tournamentName) {
  if (_preBostonMajors.contains(tournamentName)) {
    return basePageTitle;
  }

  if (_classicStageMajors.contains(tournamentName)) {
    return '$basePageTitle/Champions Stage';
  }

  if (tournamentName == 'PGL Copenhagen 2024' ||
      tournamentName == 'Perfect World Shanghai 2024') {
    return '$basePageTitle/Playoff Stage';
  }

  return '$basePageTitle/Playoffs';
}

List<Map<String, String>> _parsePlayoffMatchesFromRenderedHtml(
  String renderedPage,
) {
  final bracketIndex = renderedPage.indexOf('brkts-bracket-wrapper');
  if (bracketIndex < 0) {
    return const [];
  }

  final section = renderedPage.substring(bracketIndex);
  final headers =
      RegExp(
            r'<div class="brkts-header brkts-header-div"[^>]*>([^<]+)<div class="brkts-header-option">',
            dotAll: true,
          )
          .allMatches(section)
          .map((match) => _cleanHtmlText(match.group(1) ?? ''))
          .where((text) => text.isNotEmpty)
          .toList();

  const matchMarker = '<div class="brkts-match brkts-match-popup-wrapper';
  final parts = section.split(matchMarker);
  final matchParts = parts.skip(1).map((part) => '$matchMarker$part').toList();
  if (headers.isEmpty || matchParts.isEmpty) {
    return const [];
  }

  final roundOrder = _buildBracketRoundOrder(headers.length);

  final results = <Map<String, String>>[];
  for (var i = 0; i < matchParts.length; i++) {
    final block = matchParts[i];
    final roundIndex = i < roundOrder.length
        ? roundOrder[i]
        : headers.length - 1;
    final round = headers[roundIndex];
    final teams = _parseBracketTeams(block);
    final scores =
        RegExp(
          r'<div class="brkts-opponent-score-inner">(.*?)</div>',
          dotAll: true,
        ).allMatches(block).take(2).map((match) {
          final value = _cleanHtmlText(match.group(1) ?? '');
          return value;
        }).toList();
    final dateMatch = RegExp(
      r'<span class="timer-object[^"]*"[^>]*>(.*?)</span>',
      dotAll: true,
    ).firstMatch(block);
    final date = _cleanHtmlText(dateMatch?.group(1) ?? '');

    if (teams.length < 2) {
      continue;
    }

    results.add({
      'round': round,
      'team1': teams[0].$1,
      'team2': teams[1].$1,
      if ((teams[0].$2 ?? '').isNotEmpty) 'team1Logo': teams[0].$2!,
      if ((teams[1].$2 ?? '').isNotEmpty) 'team2Logo': teams[1].$2!,
      if (scores.isNotEmpty) 'score1': scores[0],
      if (scores.length > 1) 'score2': scores[1],
      if (date.isNotEmpty) 'date': date,
    });
  }

  return results;
}

List<int> _buildBracketRoundOrder(int roundCount) {
  final order = <int>[];

  void walk(int depth) {
    if (depth >= roundCount) {
      return;
    }
    if (depth == 0) {
      order.add(0);
      return;
    }
    walk(depth - 1);
    walk(depth - 1);
    order.add(depth);
  }

  walk(roundCount - 1);
  return order;
}

String? _extractInfoboxValue(String renderedPage, String label) {
  final pattern = RegExp(
    RegExp.escape(label) + r'</div><div style="width:50%">(.*?)</div>',
    dotAll: true,
  );
  final match = pattern.firstMatch(renderedPage);
  if (match == null) {
    return null;
  }
  final cleaned = _cleanHtmlText(match.group(1) ?? '');
  return cleaned.isEmpty ? null : cleaned;
}

Future<String?> _extractPreferredTournamentLogo(
  HttpClient client,
  String rawPage,
  String renderedPage,
) async {
  final renderedFileImages = _extractRenderedFileImageMap(renderedPage);
  final preferredFileNames = <String>[
    if ((_extractTemplateField(rawPage, 'icon') ?? '').isNotEmpty)
      _extractTemplateField(rawPage, 'icon')!,
    if ((_extractTemplateField(rawPage, 'icondarkmode') ?? '').isNotEmpty)
      _extractTemplateField(rawPage, 'icondarkmode')!,
    if ((_extractTemplateField(rawPage, 'image') ?? '').isNotEmpty)
      _extractTemplateField(rawPage, 'image')!,
    if ((_extractTemplateField(rawPage, 'imagedark') ?? '').isNotEmpty)
      _extractTemplateField(rawPage, 'imagedark')!,
  ];

  for (final fileName in preferredFileNames) {
    final normalized = fileName.trim().replaceAll('_', ' ');
    final fileUrl = await _fetchLiquipediaFileUrl(client, normalized);
    if ((fileUrl ?? '').isNotEmpty) {
      return fileUrl;
    }
    final resolved = renderedFileImages[normalized];
    if ((resolved ?? '').isNotEmpty) {
      return resolved;
    }
  }

  return null;
}

Future<String?> _fetchLiquipediaFileUrl(
  HttpClient client,
  String fileName,
) async {
  if (fileName.isEmpty) {
    return null;
  }

  final title = Uri.encodeQueryComponent('File:$fileName');
  final uri = Uri.parse(
    '$_liquipediaApiBase?action=query&titles=$title&prop=imageinfo&iiprop=url&format=json',
  );

  try {
    final json = await _fetchJson(client, uri);
    final pages = ((json['query'] as Map?)?['pages'] as Map?) ?? const {};
    for (final page in pages.values) {
      if (page is! Map) {
        continue;
      }
      final imageInfo = page['imageinfo'];
      if (imageInfo is! List || imageInfo.isEmpty || imageInfo.first is! Map) {
        continue;
      }
      final url = (imageInfo.first as Map)['url']?.toString().trim();
      if ((url ?? '').isNotEmpty) {
        return url;
      }
    }
  } catch (_) {
    return null;
  }

  return null;
}

Map<String, String> _extractRenderedFileImageMap(String renderedPage) {
  final result = <String, String>{};
  final matches = RegExp(
    r'<a href="/counterstrike/File:([^"]+)"[^>]* class="image"><img alt="" src="([^"]+)"',
    dotAll: true,
  ).allMatches(renderedPage);

  for (final match in matches) {
    final fileName = Uri.decodeComponent(
      (match.group(1) ?? '').trim(),
    ).replaceAll('_', ' ');
    final src = (match.group(2) ?? '').trim();
    if (fileName.isEmpty || src.isEmpty) {
      continue;
    }
    result.putIfAbsent(fileName, () => _resolveLiquipediaAssetUrl(src));
  }

  return result;
}

String? _extractTemplateField(String rawPage, String fieldName) {
  final match = RegExp(
    r'^\|' + RegExp.escape(fieldName) + r'\s*=\s*(.+?)\s*$',
    multiLine: true,
  ).firstMatch(rawPage);
  if (match == null) {
    return null;
  }
  final value = match.group(1)?.trim();
  return (value == null || value.isEmpty) ? null : value;
}

List<String> _extractTemplateBlocks(String source, String templateStart) {
  final blocks = <String>[];
  var searchIndex = 0;

  while (true) {
    final start = source.indexOf(templateStart, searchIndex);
    if (start < 0) break;

    var depth = 0;
    var end = start;
    while (end < source.length - 1) {
      final pair = source.substring(end, end + 2);
      if (pair == '{{') {
        depth += 1;
        end += 2;
        continue;
      }
      if (pair == '}}') {
        depth -= 1;
        end += 2;
        if (depth <= 0) {
          blocks.add(source.substring(start, end));
          break;
        }
        continue;
      }
      end += 1;
    }

    searchIndex = end;
  }

  return blocks;
}

String? _extractHtmlSection(String html, String sectionId) {
  final headingMatch = RegExp(
    '<h[23] id="$sectionId">.*?</h[23]>',
    dotAll: true,
  ).firstMatch(html);
  if (headingMatch == null) {
    return null;
  }

  final start = headingMatch.end;
  final remaining = html.substring(start);
  final nextHeading = RegExp(
    r'<div class="mw-heading mw-heading[23]">',
  ).firstMatch(remaining);
  final end = nextHeading == null ? html.length : start + nextHeading.start;
  return html.substring(start, end);
}

List<Map<String, String>> _readExistingPlacements(
  Map<String, dynamic>? existing,
) {
  final raw = existing?['placements'];
  if (raw is! List) {
    return const [];
  }

  return raw
      .whereType<Map>()
      .map(
        (entry) => {
          'place': (entry['place'] ?? '').toString(),
          'team': (entry['team'] ?? '').toString(),
          if ((entry['teamLogo'] ?? '').toString().isNotEmpty)
            'teamLogo': (entry['teamLogo'] ?? '').toString(),
        },
      )
      .where((entry) => entry['place']!.isNotEmpty && entry['team']!.isNotEmpty)
      .toList();
}

String _readWinner(
  List<Map<String, String>> placements,
  Map<String, dynamic>? existing,
) {
  final fromPlacements = placements.firstWhere(
    (entry) => entry['place'] == '1st',
    orElse: () => const {'team': ''},
  )['team'];

  if (fromPlacements != null && fromPlacements.isNotEmpty) {
    return fromPlacements;
  }

  return (existing?['winner'] ?? '').toString();
}

bool _hasValidPlacements(List<Map<String, String>> placements) {
  if (placements.isEmpty) {
    return false;
  }
  return placements.any((entry) => entry['place'] == '1st');
}

String _normalizePlace(String rawPlace) {
  final cleaned = rawPlace
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) {
    return '';
  }

  final rangeMatch = RegExp(
    r'^(\d+)(?:st|nd|rd|th)?\s*-\s*(\d+)(?:st|nd|rd|th)?$',
  ).firstMatch(cleaned);
  if (rangeMatch != null) {
    final start = int.parse(rangeMatch.group(1)!);
    final end = int.parse(rangeMatch.group(2)!);
    return '${_ordinal(start)}-${_ordinal(end)}';
  }

  final singleMatch = RegExp(r'^(\d+)(?:st|nd|rd|th)?$').firstMatch(cleaned);
  if (singleMatch != null) {
    return _ordinal(int.parse(singleMatch.group(1)!));
  }

  return '';
}

String _ordinal(int value) {
  final remainder100 = value % 100;
  if (remainder100 >= 11 && remainder100 <= 13) {
    return '${value}th';
  }

  switch (value % 10) {
    case 1:
      return '${value}st';
    case 2:
      return '${value}nd';
    case 3:
      return '${value}rd';
    default:
      return '${value}th';
  }
}

String _cleanHtmlText(String input) {
  var value = input;
  value = value.replaceAll(RegExp(r'<[^>]+>'), ' ');
  value = value
      .replaceAll('&#160;', ' ')
      .replaceAll('&#45;', '-')
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&ndash;', '-')
      .replaceAll('&mdash;', '-');
  value = value.replaceAll(RegExp(r'\s+'), ' ');
  return value.trim();
}

String _cleanWikiValue(String input) {
  var value = input.trim();
  value = value.replaceAll(RegExp(r'\s*\|[A-Za-z0-9_]+\s*=.*$'), '');
  value = value.replaceAll(RegExp(r'<ref[^>]*>.*?</ref>', dotAll: true), '');
  value = value.replaceAll(RegExp(r'<[^>]+>'), ' ');
  value = value.replaceAll(RegExp(r'\[\[(?:[^|\]]+\|)?([^\]]+)\]\]'), r'$1');
  value = value.replaceAll(RegExp(r'\{\{player\|([^|}]+).*?\}\}'), r'$1');
  value = value.replaceAll(RegExp(r'\{\{!.*?\}\}'), '');
  value = value.replaceAll("'''", '');
  value = value.replaceAll("''", '');
  value = value.replaceAll('&nbsp;', ' ');
  value = value.replaceAll(RegExp(r'\s+'), ' ');
  return value.trim();
}

List<(String, String?)> _parseTeamBlocks(String htmlChunk) {
  final blocks = RegExp(
    r'<div class="block-team">(.*?)</div>\s*</div>',
    dotAll: true,
  ).allMatches(htmlChunk);

  final teams = <(String, String?)>[];
  for (final block in blocks) {
    final inner = block.group(1) ?? '';
    final nameMatch = RegExp(
      r'<span class="name"[^>]*>\s*<a [^>]*>(.*?)</a>\s*</span>',
      dotAll: true,
    ).firstMatch(inner);
    final name = _cleanHtmlText(nameMatch?.group(1) ?? '');
    if (name.isEmpty) {
      continue;
    }
    teams.add((name, _extractPreferredTeamLogo(inner)));
  }

  return teams;
}

List<(String, String?)> _parseBracketTeams(String htmlChunk) {
  final entries = RegExp(
    r'<div class="brkts-opponent-entry[^"]*"[^>]*aria-label="([^"]+)"[^>]*>(.*?)</div>\s*</div>',
    dotAll: true,
  ).allMatches(htmlChunk);

  final teams = <(String, String?)>[];
  for (final entry in entries.take(2)) {
    final name = _cleanHtmlText(entry.group(1) ?? '');
    if (name.isEmpty) {
      continue;
    }
    teams.add((name, _extractPreferredTeamLogo(entry.group(2) ?? '')));
  }
  return teams;
}

String? _extractPreferredTeamLogo(String htmlChunk) {
  final imageMatches = RegExp(
    r'<img[^>]+src="([^"]+)"',
    dotAll: true,
  ).allMatches(htmlChunk);

  String? fallback;
  for (final match in imageMatches) {
    final raw = match.group(1) ?? '';
    if (raw.isEmpty) {
      continue;
    }
    final resolved = _resolveLiquipediaAssetUrl(raw);
    fallback ??= resolved;
    if (raw.contains('allmode') || raw.contains('lightmode')) {
      return resolved;
    }
  }

  return fallback;
}

String _resolveLiquipediaAssetUrl(String rawUrl) {
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  if (rawUrl.startsWith('//')) {
    return 'https:$rawUrl';
  }
  if (rawUrl.startsWith('/')) {
    return 'https://liquipedia.net$rawUrl';
  }
  return 'https://liquipedia.net/$rawUrl';
}

Future<void> _materializeTeamLogos(
  HttpClient client,
  List<Map<String, String>> placements,
  List<Map<String, String>> playoffMatches,
) async {
  final logoDir = Directory('assets/tournament_logos');
  if (!logoDir.existsSync()) {
    await logoDir.create(recursive: true);
  }

  Future<String?> localize(String? value, String teamName) async {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('assets/')) {
      return value;
    }

    final uri = Uri.parse(value);
    final extension = _detectImageExtension(value);
    final fileName =
        '${_slugify(teamName)}_${_slugify(uri.pathSegments.last)}$extension';
    final file = File('${logoDir.path}/$fileName');
    if (!file.existsSync()) {
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final bytes = await response.fold<List<int>>(
            <int>[],
            (acc, data) => acc..addAll(data),
          );
          await file.writeAsBytes(bytes);
        }
      } catch (_) {
        return value;
      }
    }
    return 'assets/tournament_logos/$fileName';
  }

  for (final placement in placements) {
    if ((placement['teamLogo'] ?? '').isNotEmpty) {
      placement['teamLogo'] =
          await localize(placement['teamLogo'], placement['team'] ?? '') ??
          placement['teamLogo']!;
    }
  }

  for (final match in playoffMatches) {
    if ((match['team1Logo'] ?? '').isNotEmpty) {
      match['team1Logo'] =
          await localize(match['team1Logo'], match['team1'] ?? '') ??
          match['team1Logo']!;
    }
    if ((match['team2Logo'] ?? '').isNotEmpty) {
      match['team2Logo'] =
          await localize(match['team2Logo'], match['team2'] ?? '') ??
          match['team2Logo']!;
    }
  }
}

Future<String?> _materializeTournamentLogo(
  HttpClient client,
  String tournamentName,
  String? logoValue,
) async {
  if (logoValue == null || logoValue.isEmpty) {
    return null;
  }
  if (logoValue.startsWith('assets/')) {
    return logoValue;
  }

  final logoDir = Directory('assets/tournament_logos');
  if (!logoDir.existsSync()) {
    await logoDir.create(recursive: true);
  }

  final uri = Uri.parse(logoValue);
  final extension = _detectImageExtension(logoValue);
  final slug = _slugify(tournamentName);
  for (final ext in ['.png', '.svg', '.webp', '.jpg']) {
    final candidate = File('${logoDir.path}/$slug$ext');
    if (candidate.existsSync()) {
      await candidate.delete();
    }
  }

  final fileName = '$slug$extension';
  final file = File('${logoDir.path}/$fileName');
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final bytes = await response.fold<List<int>>(
        <int>[],
        (acc, data) => acc..addAll(data),
      );
      await file.writeAsBytes(bytes);
    } else {
      return logoValue;
    }
  } catch (_) {
    return logoValue;
  }
  return 'assets/tournament_logos/$fileName';
}

String _detectImageExtension(String url) {
  final lower = Uri.parse(url).path.toLowerCase();
  if (lower.endsWith('.svg')) return '.svg';
  if (lower.endsWith('.webp')) return '.webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return '.jpg';
  return '.png';
}

String _slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _canonicalTournamentName(String rawTournamentName) {
  final repaired = rawTournamentName
      .replaceAll('ELEAGUE Major Boston 2018', 'ELEAGUE Boston 2018')
      .replaceAll('KrakР“С–w', 'Kraków')
      .replaceAll('KrakГіw', 'Kraków')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  if (repaired.isEmpty) {
    return repaired;
  }

  final yearPrefix = RegExp(r'^(20\d{2}) (.+)$').firstMatch(repaired);
  if (yearPrefix != null) {
    final year = yearPrefix.group(1)!;
    final rest = yearPrefix.group(2)!;
    return '$rest $year';
  }

  return repaired;
}

class _StagePageRef {
  final String pageTitle;
  final String phase;

  const _StagePageRef({required this.pageTitle, required this.phase});
}

Set<String> _allowedStagePhases(String tournamentName) {
  if (_preBostonMajors.contains(tournamentName)) {
    return const {};
  }

  if (_classicStageMajors.contains(tournamentName)) {
    return const {'Challengers Stage', 'Legends Stage', 'Champions Stage'};
  }

  if (tournamentName == 'PGL Copenhagen 2024' ||
      tournamentName == 'Perfect World Shanghai 2024') {
    return const {'Opening Stage', 'Elimination Stage', 'Playoff Stage'};
  }

  return const {'Stage 1', 'Stage 2', 'Stage 3', 'Playoffs'};
}

const _preBostonMajors = <String>{
  'DreamHack Winter 2013',
  'EMS One Katowice 2014',
  'ESL One Cologne 2014',
  'DreamHack Winter 2014',
  'ESL One Katowice 2015',
  'ESL One Cologne 2015',
  'DreamHack Cluj-Napoca 2015',
  'MLG Columbus 2016',
  'ESL One Cologne 2016',
  'ELEAGUE Atlanta 2017',
  'PGL Kraków 2017',
};

const _classicStageMajors = <String>{
  'ELEAGUE Boston 2018',
  'ELEAGUE Major Boston 2018',
  'FACEIT London 2018',
  'IEM Katowice 2019',
  'StarLadder Berlin 2019',
  'PGL Stockholm 2021',
  'PGL Antwerp 2022',
  'IEM Rio 2022',
  'BLAST.tv Paris 2023',
};
