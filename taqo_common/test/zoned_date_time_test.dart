import 'package:test/test.dart';

import 'package:taqo_common/util/zoned_date_time.dart';

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

    test('formatTimeZoneOffset() for withColon=true', () {
      expect(
          ZonedDateTime.formatTimeZoneOffset(Duration(hours: 8, minutes: 45),
              withColon: true),
          equals('+08:45'));
      expect(
          ZonedDateTime.formatTimeZoneOffset(Duration(hours: -9, minutes: -30),
              withColon: true),
          equals('-09:30'));
    });
  });

  group('parseTimeZoneOffset()', () {
    test('parseTimeZoneOffset() without colon', () {
      expect(ZonedDateTime.parseTimeZoneOffset('+0845'),
          equals(Duration(hours: 8, minutes: 45)));
      expect(ZonedDateTime.parseTimeZoneOffset('-0930'),
          equals(Duration(hours: -9, minutes: -30)));
    });

    test('parseTimeZoneOffset() with colon', () {
      expect(ZonedDateTime.parseTimeZoneOffset('+08:45'),
          equals(Duration(hours: 8, minutes: 45)));
      expect(ZonedDateTime.parseTimeZoneOffset('-09:30'),
          equals(Duration(hours: -9, minutes: -30)));
    });
  });

  group('ZonedDateTime.fromIso8601String()', () {
    test(
        'ZonedDateTime.fromIso8601String() is the inverse of ZonedDateTime.toIso8601String()',
        () {
      const stringDateTime = '2019-11-11T12:34:56.789012-0930';
      const stringDateTimeTZColon = '2019-11-11T12:34:56.789012-09:30';
      expect(
          ZonedDateTime.fromIso8601String(stringDateTime)
              .toIso8601String(withColon: false),
          equals(stringDateTime));
      expect(
          ZonedDateTime.fromIso8601String(stringDateTimeTZColon)
              .toIso8601String(withColon: true),
          equals(stringDateTimeTZColon));
      const stringDateTimeNoUs = '2019-11-11T12:34:56.789-0930';
      const stringDateTimeTZColonNoUS = '2019-11-11T12:34:56.789-09:30';
      expect(
          ZonedDateTime.fromIso8601String(stringDateTimeNoUs)
              .toIso8601String(withColon: false),
          equals(stringDateTimeNoUs));
      expect(
          ZonedDateTime.fromIso8601String(stringDateTimeTZColonNoUS)
              .toIso8601String(withColon: true),
          equals(stringDateTimeTZColonNoUS));
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

  group('ZonedDateTime.fromInt()', () {
    test(
      'fromInt parses an int representing millisSinceEpoch and produces an object in local timezone',
        () {
        int millis = 1517875586000;
        expect(ZonedDateTime.fromMillis(millis).dateTime.millisecondsSinceEpoch
            , equals(millis));
        }
    );
  });
}
