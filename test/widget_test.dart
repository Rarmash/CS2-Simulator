import 'package:cs2_simulator/data/models/container_dto.dart';
import 'package:cs2_simulator/data/models/sticker_dto.dart';
import 'package:cs2_simulator/data/models/tournament_metadata_dto.dart';
import 'package:cs2_simulator/data/repositories/local_data_repository.dart';
import 'package:cs2_simulator/presentation/screens/sticker_glossary_screen.dart';
import 'package:cs2_simulator/presentation/screens/tournament_details_screen.dart';
import 'package:cs2_simulator/presentation/widgets/glossary_filter_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:cs2_simulator/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets('App starts and shows the home screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));

    await tester.pumpWidget(const Cs2SimulatorApp());
    await tester.pumpAndSettle();

    expect(find.text('CS2 Simulator'), findsOneWidget);
    expect(find.text('Open Containers'), findsOneWidget);
    expect(find.text('Trade-Up'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
  for (final (name, count) in [
    ('IEM Cologne 2026', 1371),
    ('PGL Singapore 2026', 772),
  ]) {
    testWidgets('opens and filters the $name sticker catalog', (tester) async {
      tester.view.physicalSize = const Size(360, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openMajor(tester, name);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Browse Stickers'));
      await tester.pumpAndSettle();

      expect(find.text('$name Stickers'), findsOneWidget);
      expect(find.text('$count stickers'), findsOneWidget);
      await _select(tester, 'Category', 'Teams & Event');
      final teamCount = name.startsWith('IEM') ? 231 : 132;
      expect(find.text('$teamCount stickers'), findsOneWidget);
      await _select(tester, 'Category', 'Autographs');
      if (name.startsWith('IEM')) {
        await _select(tester, 'Series', 'Ranked Series');
        await _select(tester, 'Effect', 'Paper');
        expect(find.text('No stickers found.'), findsOneWidget);
        await _select(tester, 'Effect', 'Foil');
      } else {
        expect(find.text('Series'), findsNothing);
        await _select(tester, 'Effect', 'Paper');
      }
      expect(find.text('160 stickers'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ZywOo');
      await tester.pumpAndSettle();
      expect(find.text('1 sticker'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keeps capsule sources on the Paris Major details', (
    tester,
  ) async {
    await _openMajor(tester, 'BLAST.tv Paris 2023');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Sticker and Autograph Capsules ('),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(StickerGlossaryScreen), findsNothing);
    expect(find.text('Browse Stickers'), findsNothing);
    expect(
      find.textContaining('Sticker and Autograph Capsules ('),
      findsOneWidget,
    );
    expect(
      find.text('No sticker sources found for this tournament.'),
      findsNothing,
    );
  });
}

Future<void> _select(WidgetTester tester, String label, String option) async {
  await tester.tap(
    find.byWidgetPredicate(
      (widget) => widget is GlossaryFilterDropdown && widget.label == label,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).hitTestable().last);
  await tester.pumpAndSettle();
}

Future<void> _openMajor(WidgetTester tester, String name) async {
  final data = await tester.runAsync(() async {
    final repository = LocalDataRepository();
    return (
      (await repository.loadTournaments()).firstWhere(
        (item) => item.name == name,
      ),
      _PreloadedRepository(
        stickers: await repository.loadStickers(),
        metadata: await repository.loadTournamentMetadataByName(name),
        souvenirs: await repository.loadSouvenirPackagesForTournament(name),
        capsules: await repository.loadStickerContainersForTournament(name),
      ),
    );
  });
  final (tournament, repository) = data!;
  await tester.pumpWidget(
    MaterialApp(
      home: TournamentDetailsScreen(
        repository: repository,
        tournament: tournament,
      ),
    ),
  );
}

class _PreloadedRepository extends LocalDataRepository {
  final List<StickerDto> stickers;
  final TournamentMetadataDto? metadata;
  final List<ContainerDto> souvenirs;
  final List<ContainerDto> capsules;

  _PreloadedRepository({
    required this.stickers,
    required this.metadata,
    required this.souvenirs,
    required this.capsules,
  });

  @override
  Future<List<StickerDto>> loadStickers() async => stickers;

  @override
  Future<TournamentMetadataDto?> loadTournamentMetadataByName(
    String name,
  ) async => metadata;

  @override
  Future<List<ContainerDto>> loadSouvenirPackagesForTournament(
    String name,
  ) async => souvenirs;

  @override
  Future<List<ContainerDto>> loadStickerContainersForTournament(
    String name,
  ) async => capsules;
}
