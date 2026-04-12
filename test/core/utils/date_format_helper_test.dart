import 'package:cs2_simulator/core/utils/date_format_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateFormatHelper', () {
    test('formats release date', () {
      expect(DateFormatHelper.formatReleaseDate('2025-06-22'), '22 Jun 2025');
    });

    test('returns null for empty date', () {
      expect(DateFormatHelper.formatReleaseDate(null), isNull);
      expect(DateFormatHelper.formatReleaseDate(''), isNull);
    });

    test('keeps unknown formats unchanged', () {
      expect(DateFormatHelper.formatReleaseDate('June 2025'), 'June 2025');
    });

    test('formats date range and collapses identical dates', () {
      expect(
        DateFormatHelper.formatDateRange('2025-06-03', '2025-06-22'),
        '03 Jun 2025 - 22 Jun 2025',
      );
      expect(
        DateFormatHelper.formatDateRange('2025-06-03', '2025-06-03'),
        '03 Jun 2025',
      );
    });
  });
}
