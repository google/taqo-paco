class ZonedDateTime {
  static const String ISO8601_FORMAT_LOCAL = 'yyyy-MM-ddTHH:mm:ss.mmmuuu';
  static const String DATETIME_FORMAT_LOCAL = 'yyyy/MM/dd HH:mm:ss';

  final Duration timeZoneOffset;
  final DateTime dateTime;
  final String _iso8601String;

  const ZonedDateTime._(
      this.timeZoneOffset, this.dateTime, this._iso8601String);

  factory ZonedDateTime.now() {
    final dateTime = DateTime.now();
    final timeZoneOffset = dateTime.timeZoneOffset;
    var string = _validateAndFixIso8601String(
        '${dateTime.toIso8601String()}${formatTimeZoneOffset(timeZoneOffset)}',
        dateTime,
        timeZoneOffset);

    return ZonedDateTime._(timeZoneOffset, dateTime, string);
  }

  String toIso8601String() {
    return _iso8601String;
  }

  factory ZonedDateTime.fromIso8601String(String iso8601String) {
    final dateTime = DateTime.parse(iso8601String);
    final timeZoneOffset = parseTimeZoneOffset(iso8601String.substring(
        iso8601String.length - 5, iso8601String.length));
    return ZonedDateTime._(timeZoneOffset, dateTime, iso8601String);
  }

  String toString() {
    return _iso8601String
            .substring(0, DATETIME_FORMAT_LOCAL.length)
            .replaceAll('-', '/')
            .replaceFirst('T', ' ') +
        _iso8601String.substring(
            ISO8601_FORMAT_LOCAL.length, _iso8601String.length);
  }

  // Note: this is only a right inverse of toString(), because toString() lost some precision.
  factory ZonedDateTime.fromString(String string) {
    final stringLocalDateTime = string
        .substring(0, DATETIME_FORMAT_LOCAL.length)
        .replaceAll('/', '-')
        .replaceFirst(' ', 'T');
    final stringTimeZoneOffset =
        string.substring(string.length - 5, string.length);
    final iso8601String =
        '${stringLocalDateTime}.000000${stringTimeZoneOffset}';
    return ZonedDateTime.fromIso8601String(iso8601String);
  }

  static String _validateAndFixIso8601String(
      String string, DateTime dateTime, Duration timeZoneOffset) {
    if (dateTime.toUtc() == DateTime.parse(string)) {
      return string;
    } else {
      // very rare case where the time zone changes immediately after calling DateTime.now()
      final dateTimeLocal = dateTime.toUtc().add(timeZoneOffset);
      return '${dateTimeLocal.toIso8601String().substring(0, ISO8601_FORMAT_LOCAL.length)}${formatTimeZoneOffset(timeZoneOffset)}';
    }
  }

  static String formatTimeZoneOffset(Duration timeZoneOffset) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return '0$n';
    }

    String sign;
    if (timeZoneOffset.inMilliseconds < 0) {
      sign = '-';
      timeZoneOffset = -timeZoneOffset;
    } else {
      sign = '+';
    }
    String twoDigitHours = twoDigits(timeZoneOffset.inHours);
    String twoDigitMinutes =
        twoDigits(timeZoneOffset.inMinutes.remainder(Duration.minutesPerHour));

    return '$sign$twoDigitHours$twoDigitMinutes';
  }

  static Duration parseTimeZoneOffset(String string) {
    final sign = string.substring(0, 1);
    final twoDigitHours = string.substring(1, 3);
    final twoDigitMinutes = string.substring(3, 5);

    final hours = int.parse(twoDigitHours);
    final minutes = int.parse(twoDigitMinutes);
    final duration = Duration(hours: hours, minutes: minutes);
    return sign == '-' ? -duration : duration;
  }
}
