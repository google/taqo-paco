import 'package:test/test.dart';
import 'package:taqo_client/service/logging_service.dart';

void main() {
  group('Filtering old logs based on sorting filenames', () {
    const _MAX_LOG_FILES_COUNT = 3;
    test('Number of log files exceed limit', () {
      expect(
          LoggingService.filterOldLogFileNames([
            'fcc4d8/2020-01-11.log',
            'fcc4d8/2020-01-10.log',
            'fcc4d8/2020-01-14.log',
            'fcc4d8/2020-01-12.log',
            'fcc4d8/2020-01-09.log',
            'fcc4d8/2020-01-13.log'
          ], maxLogFilesCount: 3),
          equals([
            'fcc4d8/2020-01-09.log',
            'fcc4d8/2020-01-10.log',
            'fcc4d8/2020-01-11.log'
          ]));
    });
    test('Number of log files within limit', () {
      expect(
          LoggingService.filterOldLogFileNames([
            'fcc4d8/2020-01-14.log',
            'fcc4d8/2020-01-12.log',
            'fcc4d8/2020-01-13.log'
          ], maxLogFilesCount: 3),
          equals([]));
      expect(
          LoggingService.filterOldLogFileNames(
              ['fcc4d8/2020-01-14.log', 'fcc4d8/2020-01-13.log'],
              maxLogFilesCount: 3),
          equals([]));
    });
  });
}
