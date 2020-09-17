class ZonedDateTime {
  static const String ISO8601_FORMAT_LOCAL_WITHOUT_US =
      'yyyy-MM-ddTHH:mm:ss.mmm';
  static const String ISO8601_FORMAT_LOCAL_WITH_US =
      'yyyy-MM-ddTHH:mm:ss.mmmuuu';
  static const String DATETIME_FORMAT_LOCAL = 'yyyy/MM/dd HH:mm:ss';

  final Duration timeZoneOffset;
  final DateTime dateTime;
  // As dateTime.toString() is not stable against timezone change, it is
  // necessary to convert and store the string representation as early as
  // possible. Here we only store the local part since timeZoneOffset formatting
  // is stable and we will need different variants of the timezone format.
  final String _iso8601StringLocal;

  const ZonedDateTime._(
      this.timeZoneOffset, this.dateTime, this._iso8601StringLocal);

  factory ZonedDateTime.now() {
    final dateTime = DateTime.now();
    final timeZoneOffset = dateTime.timeZoneOffset;
    var string = _validateAndFixIso8601StringLocal(
        dateTime.toIso8601String(), dateTime, timeZoneOffset);

    return ZonedDateTime._(timeZoneOffset, dateTime, string);
  }

  String toIso8601String({withColon = false}) {
    return '$_iso8601StringLocal${formatTimeZoneOffset(timeZoneOffset, withColon: withColon)}';
  }

  factory ZonedDateTime.fromIso8601String(String iso8601String) {
    final dateTime = DateTime.parse(iso8601String);
    final tzStartIndex = dateTime.microsecond == 0
        ? ISO8601_FORMAT_LOCAL_WITHOUT_US.length
        : ISO8601_FORMAT_LOCAL_WITH_US.length;
    final timeZoneOffset = parseTimeZoneOffset(
        iso8601String.substring(tzStartIndex, iso8601String.length));
    final iso8601StringLocal = iso8601String.substring(0, tzStartIndex);
    return ZonedDateTime._(timeZoneOffset, dateTime, iso8601StringLocal);
  }

  String toString() {
    return _iso8601StringLocal
            .substring(0, DATETIME_FORMAT_LOCAL.length)
            .replaceAll('-', '/')
            .replaceFirst('T', ' ') +
        formatTimeZoneOffset(timeZoneOffset, withColon: false);
  }

  // Note: this is only a right inverse of toString(), because toString() lost some precision.
  factory ZonedDateTime.fromString(String string) {
    final stringLocalDateTime = string
        .substring(0, DATETIME_FORMAT_LOCAL.length)
        .replaceAll('/', '-')
        .replaceFirst(' ', 'T');
    final stringTimeZoneOffset =
        string.substring(string.length - 5, string.length);
    final iso8601String = '${stringLocalDateTime}.000${stringTimeZoneOffset}';
    return ZonedDateTime.fromIso8601String(iso8601String);
  }

  static String _validateAndFixIso8601StringLocal(
      String stringLocal, DateTime dateTime, Duration timeZoneOffset) {
    var stringTZ = '$stringLocal${formatTimeZoneOffset(timeZoneOffset)}';
    if (dateTime.toUtc() == DateTime.parse(stringTZ)) {
      return stringLocal;
    } else {
      // very rare case where the time zone changes immediately after calling DateTime.now()
      final dateTimeLocal = dateTime.toUtc().add(timeZoneOffset);
      final tzStartIndex = dateTime.microsecond == 0
          ? ISO8601_FORMAT_LOCAL_WITHOUT_US.length
          : ISO8601_FORMAT_LOCAL_WITH_US.length;
      return dateTimeLocal.toIso8601String().substring(0, tzStartIndex);
    }
  }

  // ISO8601 allows several variants for formatting timezone, where two of them
  // are ±hhmm and ±hh:mm. The Paco server uses ±hhmm, while SQLite uses ±hh:mm.
  // We need to support both of them here.

  static String formatTimeZoneOffset(Duration timeZoneOffset,
      {bool withColon = false}) {
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

    return withColon
        ? '$sign$twoDigitHours:$twoDigitMinutes'
        : '$sign$twoDigitHours$twoDigitMinutes';
  }

  static Duration parseTimeZoneOffset(String string) {
    final withColon = (string[3] == ':');
    final sign = string.substring(0, 1);
    final twoDigitHours = string.substring(1, 3);
    final twoDigitMinutes =
        withColon ? string.substring(4, 6) : string.substring(3, 5);

    final hours = int.parse(twoDigitHours);
    final minutes = int.parse(twoDigitMinutes);
    final duration = Duration(hours: hours, minutes: minutes);
    return sign == '-' ? -duration : duration;
  }

  static fromMillis(int millis) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
    final timeZoneOffset = dateTime.timeZoneOffset;
    var string = _validateAndFixIso8601StringLocal(
        dateTime.toIso8601String(), dateTime, timeZoneOffset);

    return ZonedDateTime._(timeZoneOffset, dateTime, string);
  }

  int toMillis() {
    return dateTime.millisecondsSinceEpoch;
  }
}
