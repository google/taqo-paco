import 'package:intl/intl.dart';
import 'package:test/test.dart';

import 'package:taqo_client/util/zoned_date_time.dart';

void main() {
  group('formatTimeZoneOffset()', () {
    test('formatTimeZoneOffset() format DateTime.timeZoneOffset as ±hhmm', () {
      expect(ZonedDateTime.formatTimeZoneOffset(Duration(hours: 0)),
          equals('+0000'));
      expect(ZonedDateTime.formatTimeZoneOffset(Duration(hours: 8)),
          equals('+0800'));
      expect(ZonedDateTime.formatTimeZoneOffset(Duration(hours: -7)),
          equals('-0700'));
      expect(
          ZonedDateTime.formatTimeZoneOffset(Duration(hours: 4, minutes: 30)),
          equals('+0430'));
      expect(
          ZonedDateTime.formatTimeZoneOffset(Duration(hours: -9, minutes: -30)),
          equals('-0930'));
      expect(
          ZonedDateTime.formatTimeZoneOffset(Duration(hours: 8, minutes: 45)),
          equals('+0845'));
    });

    test('formatTimeZoneOffset() for unexpected input', () {
      expect(
          ZonedDateTime.formatTimeZoneOffset(
              Duration(hours: 8, minutes: 45, seconds: 59)),
          equals('+0845'));
    });
  });

  group('ZonedDateTime.fromIso8601String()', () {
    test(
        'ZonedDateTime.fromIso8601String() is the inverse of ZonedDateTime.toIso8601String()',
        () {
      const stringDateTime = '2019-11-11T12:34:56.789012-0930';
      expect(ZonedDateTime.fromIso8601String(stringDateTime).toIso8601String(),
          equals(stringDateTime));
    });
  });

  group('ZonedDateTime.fromString()', () {
    test(
        'ZonedDateTime.fromString() is the right inverse of ZonedDateTime.toString()',
        () {
      const stringDateTime = '2019/11/11 12:34:56-0930';
      expect(ZonedDateTime.fromString(stringDateTime).toString(),
          equals(stringDateTime));
    });
  });
}
