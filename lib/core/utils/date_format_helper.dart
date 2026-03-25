class DateFormatHelper {
  static String? formatReleaseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final parts = raw.split('-');
    if (parts.length != 3) return raw;

    const months = {
      '01': 'Jan',
      '02': 'Feb',
      '03': 'Mar',
      '04': 'Apr',
      '05': 'May',
      '06': 'Jun',
      '07': 'Jul',
      '08': 'Aug',
      '09': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec',
    };

    final year = parts[0];
    final month = months[parts[1]] ?? parts[1];
    final day = parts[2];

    return '$day $month $year';
  }
}