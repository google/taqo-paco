import 'package:test/test.dart';
import 'package:path/path.dart' as p;

// This is not a traditional unit test. We are testing the log file rotation
// logic here. The implementation of the logging service is in
// lib/service/logging_service.dart
// However, it is not obvious how to extract the logic out cleanly and effectively.
// For example, a straightforward way is to define some function as below
//
// Iterable<File> filterOldLogFiles(List<File> logFiles) {
//   logFiles.sort(
//       (File a, File b) => p.basename(a.path).compareTo(p.basename(b.path)));
//   return logFiles.take(max(logFiles.length - _MAX_LOG_FILES_COUNT,0));
// }
//
// However, there are several issues with the above extracted function
// (1) logFiles will be changed, so that later reference to logFiles will have
//     different contents. We're not saying a function should not modify its
//     arguments, but having a return value while modifying its arguments may be
//     error prone.
// (2) What's worse, if one modifies logFiles after the obtaining the return
//     value of the function, the contents in the return value will also be
//     changed.
// (3) Trying to make the function safer will add unnecessary overhead.void
//
// Apparently, the mutability and ownership concepts in Rust may help with this
// situation. But unfortunately in Dart we don't have such options.
// We decided to leave such error-prune functions only locally in the test,
// but not in the actual production code.

void main() {
  group('Filtering old logs based on sorting filenames', () {
    const _MAX_LOG_FILES_COUNT = 3;
    var mockFilterOldLogFilenames = (List<String> filenames) {
      if (filenames.length <= _MAX_LOG_FILES_COUNT) {
        return [];
      } else {
        filenames.sort((a, b) => p.basename(a).compareTo(p.basename(b)));
        return filenames.take(filenames.length - _MAX_LOG_FILES_COUNT).toList();
      }
    };
    test('Number of log files exceed limit', () {
      expect(
          mockFilterOldLogFilenames([
            'fcc4d8/2020-01-11.log',
            'fcc4d8/2020-01-10.log',
            'fcc4d8/2020-01-14.log',
            'fcc4d8/2020-01-12.log',
            'fcc4d8/2020-01-09.log',
            'fcc4d8/2020-01-13.log'
          ]),
          equals([
            'fcc4d8/2020-01-09.log',
            'fcc4d8/2020-01-10.log',
            'fcc4d8/2020-01-11.log'
          ]));
    });
    test('Number of log files within limit', (){
      expect(
          mockFilterOldLogFilenames([
            'fcc4d8/2020-01-14.log',
            'fcc4d8/2020-01-12.log',
            'fcc4d8/2020-01-13.log'
          ]),
          equals([]));
      expect(
          mockFilterOldLogFilenames([
            'fcc4d8/2020-01-14.log',
            'fcc4d8/2020-01-13.log'
          ]),
          equals([]));
    });


  });
}
