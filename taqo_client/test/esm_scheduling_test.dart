import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/scheduling/action_schedule_generator.dart';
import 'package:taqo_client/storage/esm_signal_storage.dart';

List<Experiment> _loadExperiments(String json) {
  try {
    final file = File(json);
    assert(file.existsSync(), '$json file does not exist');
    final List experimentList = jsonDecode(file.readAsStringSync());
    return List.from(experimentList.map((e) => Experiment.fromJson(e)));
  } catch (e) {
    print("Error loading joined experiments file: $e");
    return [];
  }
}

class ESMTestResult {
  final String groupName;
  final bool weekends;
  final int minBuffer;
  final int num;

  final DateTime periodStart, nextPeriodStart;
  final int alarmStart, alarmEnd;
  final int periodLength, nextPeriodLength;

  ESMTestResult(this.groupName, this.periodStart, this.nextPeriodStart, this.alarmStart, this.alarmEnd,
      this.periodLength, this.nextPeriodLength, this.num, this.minBuffer, [this.weekends = true]);

  bool _verifyAlarm(Iterable<Map> period, DateTime start, DateTime end) {
    return period.map((m) {
      final a1 = DateTime.parse(m['alarmTime']);
      if (!weekends && a1.weekday > DateTime.friday) {
        return false;
      }
      return (a1.isAtSameMomentAs(start) || a1.isAfter(start)) &&
          (a1.isBefore(end) || a1.isAtSameMomentAs(end));
    }).every((b) => b);
  }

  bool _verifyBuffer(Iterable<Map> period) {
    final alarms = period.map((r) => DateTime.parse(r['alarmTime'])).toList(growable: false)..sort();
    for (var i = 0; i < alarms.length - 1; i++) {
      if (alarms[i].difference(alarms[i+1]).inMinutes.abs() < minBuffer) {
        return false;
      }
    }
    return true;
  }

  bool verify(List<Map> result) {
    final period = result.where((m) => DateTime.parse(m['date']) == periodStart &&
        m['groupName'] == groupName);
    final pStart = periodStart.add(Duration(hours: alarmStart));
    final pEnd = periodStart.add(Duration(days: periodLength)).add(Duration(hours: alarmEnd));

    final nextPeriod = result.where((m) => DateTime.parse(m['date']) == nextPeriodStart &&
        m['groupName'] == groupName);
    final pNextStart = nextPeriodStart.add(Duration(hours: alarmStart));
    final pNextEnd = nextPeriodStart.add(Duration(days: nextPeriodLength))
        .add(Duration(hours: alarmEnd));

    bool verified = true;
    verified &= period.length == num;
    verified &= _verifyAlarm(period, pStart, pEnd);
    verified &= _verifyBuffer(period);
    verified &= nextPeriod.length == num;
    verified &= _verifyAlarm(nextPeriod, pNextStart, pNextEnd);
    verified &= _verifyBuffer(nextPeriod);

    return verified;
  }
}

// TODO Clean this up
final dt1 = DateTime(2001, 1, 1);
final dt2 = DateTime(2005, 9, 15);
final dt3 = DateTime(2012, 8, 25);
final _testDateTimes = [dt1, dt2, dt3, ];

final m = {
  'Experiment 1': {
    dt1: ESMTestResult('Experiment 1', DateTime(2001, 1, 1), DateTime(2001, 1, 2), 9, 17, 0, 0, 5, 59),
    dt2: ESMTestResult('Experiment 1', DateTime(2005, 9, 15), DateTime(2005, 9, 16), 9, 17, 0, 0, 5, 59),
    dt3: ESMTestResult('Experiment 1', DateTime(2012, 8, 25), DateTime(2012, 8, 26), 9, 17, 0, 0, 5, 59),
  },
  'Experiment 2': {
    dt1: ESMTestResult('Experiment 2', DateTime(2000, 12, 31), DateTime(2001, 1, 7), 6, 14, 7, 7, 11, 118),
    dt2: ESMTestResult('Experiment 2', DateTime(2005, 9, 11), DateTime(2005, 9, 18), 6, 14, 7, 7, 11, 118),
    dt3: ESMTestResult('Experiment 2', DateTime(2012, 8, 19), DateTime(2012, 8, 26), 6, 14, 7, 7, 11, 118),
  },
  'Experiment 3': {
    dt1: ESMTestResult('Experiment 3', DateTime(2001, 1, 1), DateTime(2001, 2, 1), 13, 23, 31, 28, 45, 15),
    dt2: ESMTestResult('Experiment 3', DateTime(2005, 9, 1), DateTime(2005, 10, 1), 13, 23, 30, 31, 45, 15),
    dt3: ESMTestResult('Experiment 3', DateTime(2012, 8, 1), DateTime(2012, 9, 1), 13, 23, 31, 30, 45, 15),
  },
  'Experiment 4': {
    dt1: ESMTestResult('Experiment 4', DateTime(2001, 1, 1), DateTime(2001, 1, 2), 11, 13, 0, 0, 1, 10, false),
    dt2: ESMTestResult('Experiment 4', DateTime(2005, 9, 15), DateTime(2005, 9, 16), 11, 13, 0, 0, 1, 10, false),
    dt3: ESMTestResult('Experiment 4', DateTime(2012, 8, 27), DateTime(2012, 8, 28), 11, 13, 0, 0, 1, 10, false),
  },
  'Experiment 5': {
    dt1: ESMTestResult('Experiment 5', DateTime(2001, 1, 1), DateTime(2001, 1, 8), 0, 5, 7, 7, 3, 400, false),
    dt2: ESMTestResult('Experiment 5', DateTime(2005, 9, 12), DateTime(2005, 9, 19), 0, 5, 7, 7, 3, 400, false),
    dt3: ESMTestResult('Experiment 5', DateTime(2012, 8, 20), DateTime(2012, 8, 27), 0, 5, 7, 7, 3, 400, false),
  },
  'Experiment 6': {
    dt1: ESMTestResult('Experiment 6', DateTime(2001, 1, 1), DateTime(2001, 2, 1), 16, 22, 31, 28, 16, 200, false),
    dt2: ESMTestResult('Experiment 6', DateTime(2005, 9, 1), DateTime(2005, 10, 3), 16, 22, 30, 31, 16, 200, false),
    dt3: ESMTestResult('Experiment 6', DateTime(2012, 8, 1), DateTime(2012, 9, 3), 16, 22, 31, 30, 16, 200, false),
  },
};

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final esmExperiments = _loadExperiments('test/data/esm_schedule_test_data.json');

  for (var e in esmExperiments) {
    await ESMSignalStorage().deleteAllSignals();

    for (var dt in _testDateTimes) {
      test('ESM ${e.title}: ${dt.toIso8601String()}', () async {
        await getNextAlarmTimesOrdered([e], now: dt);
        final signals = await ESMSignalStorage().getAllSignals();
        expect(m[e.title][dt].verify(signals), true);
      });
    }
  }
}
