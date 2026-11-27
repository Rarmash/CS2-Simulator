import 'package:cs2_simulator/presentation/widgets/glossary_filter_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fits a long selection in a narrow glossary filter', (
    tester,
  ) async {
    const longLabel = 'Missing Link Community Charm Collection';
    String? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              child: GlossaryFilterDropdown(
                label: 'Source',
                value: 'community',
                options: const [
                  GlossaryFilterOption('all', 'All sources'),
                  GlossaryFilterOption('community', longLabel),
                ],
                onChanged: (value) => selectedValue = value,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(GlossaryFilterDropdown));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('All sources').hitTestable());
    await tester.pumpAndSettle();
    expect(selectedValue, 'all');
    expect(tester.takeException(), isNull);
  });
}
