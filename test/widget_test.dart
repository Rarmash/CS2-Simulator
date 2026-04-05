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
}
