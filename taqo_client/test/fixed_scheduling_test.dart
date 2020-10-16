import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taqo_client/storage/flutter_file_storage.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/scheduling/action_schedule_generator.dart';
import 'package:taqo_common/storage/esm_signal_storage.dart';

List<Experiment> loadExperiments(String json) {
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

final dt1 = DateTime(2013, 1, 1); // tues
final dt2 = DateTime(2005, 2, 4); // fri
final dt3 = DateTime(2012, 3, 7); // wed
final dt4 = DateTime(2006, 4, 10); // mon
final dt5 = DateTime(2017, 5, 14); // sun
final dt6 = DateTime(2003, 6, 16); // mon
final dt7 = DateTime(2010, 7, 18); // sun
final dt8 = DateTime(2019, 8, 22); // thu
final dt9 = DateTime(2014, 9, 25); // thu
final dt10 = DateTime(2009, 10, 31); // sat
final dt11 = DateTime(2007, 11, 30); // fri
final dt12 = DateTime(2011, 12, 31); // sat
final testDateTimes = [
  dt1, dt2, dt3, dt4, dt5, dt6, dt7, dt8, dt9, dt10, dt11, dt12, //
];

final expected = <String, Map<DateTime, DateTime>>{
  'Experiment 1': {
    dt1: DateTime(2013, 1, 1, 10),
    dt2: DateTime(2005, 2, 4, 10),
    dt3: DateTime(2012, 3, 7, 10),
    dt4: DateTime(2006, 4, 10, 10),
    dt5: DateTime(2017, 5, 14, 10),
    dt6: DateTime(2003, 6, 16, 10),
    dt7: DateTime(2010, 7, 18, 10),
    dt8: DateTime(2019, 8, 22, 10),
    dt9: DateTime(2014, 9, 25, 10),
    dt10: DateTime(2009, 10, 31, 10),
    dt11: DateTime(2007, 11, 30, 10),
    dt12: DateTime(2011, 12, 31, 10),
  },
  'Experiment 2': {
    dt1: DateTime(2013, 1, 4, 12),
    dt2: DateTime(2005, 2, 9, 12),
    dt3: DateTime(2012, 3, 10, 12),
    dt4: DateTime(2006, 4, 12, 12),
    dt5: DateTime(2017, 5, 14, 12),
    dt6: DateTime(2003, 6, 21, 12),
    dt7: DateTime(2010, 7, 20, 12),
    dt8: DateTime(2019, 8, 26, 12),
    dt9: DateTime(2014, 9, 27, 12),
    dt10: DateTime(2009, 11, 4, 11), // TODO daylight savings
    dt11: DateTime(2007, 12, 2, 12),
    dt12: DateTime(2012, 1, 4, 12),
  },
  'Experiment 3': {
    dt1: DateTime(2013, 1, 1, 13),
    dt2: DateTime(2005, 2, 4, 13),
    dt3: DateTime(2012, 3, 7, 13),
    dt4: DateTime(2006, 4, 10, 13),
    dt5: DateTime(2017, 5, 15, 13),
    dt6: DateTime(2003, 6, 16, 13),
    dt7: DateTime(2010, 7, 19, 13),
    dt8: DateTime(2019, 8, 22, 13),
    dt9: DateTime(2014, 9, 25, 13),
    dt10: DateTime(2009, 11, 3, 12), // TODO daylight savings
    dt11: DateTime(2007, 11, 30, 13),
    dt12: DateTime(2012, 1, 2, 13),
  },
  'Experiment 4': {
    dt1: DateTime(2013, 1, 5, 15, 30),
    dt2: DateTime(2005, 2, 5, 15, 30),
    dt3: DateTime(2012, 3, 10, 15, 30),
    dt4: DateTime(2006, 4, 15, 15, 30),
    dt5: DateTime(2017, 5, 14, 15, 30),
    dt6: DateTime(2003, 6, 21, 15, 30),
    dt7: DateTime(2010, 7, 18, 15, 30),
    dt8: DateTime(2019, 8, 24, 15, 30),
    dt9: DateTime(2014, 9, 27, 15, 30),
    dt10: DateTime(2009, 10, 31, 15, 30),
    dt11: DateTime(2007, 12, 1, 15, 30),
    dt12: DateTime(2011, 12, 31, 15, 30),
  },
  'Experiment 5': {
    dt1: DateTime(2013, 1, 7, 15),
    dt2: DateTime(2005, 2, 4, 15),
    dt3: DateTime(2012, 3, 7, 15),
    dt4: DateTime(2006, 4, 10, 15),
    dt5: DateTime(2017, 5, 15, 15),
    dt6: DateTime(2003, 6, 23, 15),
    dt7: DateTime(2010, 7, 19, 15),
    dt8: DateTime(2019, 8, 26, 15),
    dt9: DateTime(2014, 9, 29, 15),
    dt10: DateTime(2009, 11, 2, 15),
    dt11: DateTime(2007, 12, 3, 15),
    dt12: DateTime(2012, 1, 9, 15),
  },
  'Experiment 6': {
    dt1: DateTime(2013, 1, 11, 18, 22),
    dt2: DateTime(2005, 2, 11, 18, 22),
    dt3: DateTime(2012, 3, 11, 19, 22), // TODO daylight savings
    dt4: DateTime(2006, 4, 11, 18, 22),
    dt5: DateTime(2017, 6, 11, 18, 22),
    dt6: DateTime(2003, 7, 11, 18, 22),
    dt7: DateTime(2010, 8, 11, 18, 22),
    dt8: DateTime(2019, 9, 11, 18, 22),
    dt9: DateTime(2014, 10, 11, 18, 22),
    dt10: DateTime(2009, 11, 11, 18, 22),
    dt11: DateTime(2007, 12, 11, 18, 22),
    dt12: DateTime(2012, 1, 11, 18, 22),
  },
  'Experiment 7': {
    dt1: DateTime(2013, 1, 31, 17),
    dt2: DateTime(2005, 4, 30, 17),
    dt3: DateTime(2012, 4, 30, 17),
    dt4: DateTime(2006, 4, 30, 17),
    dt5: DateTime(2017, 7, 31, 17),
    dt6: DateTime(2003, 7, 31, 17),
    dt7: DateTime(2010, 7, 31, 17),
    dt8: DateTime(2019, 10, 31, 17),
    dt9: DateTime(2014, 10, 31, 17),
    dt10: DateTime(2009, 10, 31, 17),
    dt11: DateTime(2008, 1, 31, 17),
    dt12: DateTime(2012, 1, 31, 17),
  },
  'Experiment 8': {
    dt1: DateTime(2013, 1, 15, 21),
    dt2: DateTime(2005, 2, 15, 21),
    dt3: DateTime(2012, 3, 15, 21),
    dt4: DateTime(2006, 4, 18, 21),
    dt5: DateTime(2017, 5, 16, 21),
    dt6: DateTime(2003, 6, 17, 21),
    dt7: DateTime(2010, 7, 20, 21),
    dt8: DateTime(2019, 9, 17, 21),
    dt9: DateTime(2014, 10, 16, 21),
    dt10: DateTime(2009, 11, 17, 21),
    dt11: DateTime(2007, 12, 18, 21),
    dt12: DateTime(2012, 1, 17, 21),
  },
  'Experiment 9': {
    dt1: DateTime(2013, 1, 25, 22, 10),
    dt2: DateTime(2005, 5, 27, 22, 10),
    dt3: DateTime(2012, 5, 25, 22, 10),
    dt4: DateTime(2006, 5, 26, 22, 10),
    dt5: DateTime(2017, 5, 26, 22, 10),
    dt6: DateTime(2003, 9, 26, 22, 10),
    dt7: DateTime(2010, 9, 24, 22, 10),
    dt8: DateTime(2019, 9, 27, 22, 10),
    dt9: DateTime(2014, 9, 26, 22, 10),
    dt10: DateTime(2010, 1, 25, 22, 10),
    dt11: DateTime(2008, 1, 25, 22, 10),
    dt12: DateTime(2012, 1, 27, 22, 10),
  },
  'Experiment 10': {
    dt1: DateTime(2013, 1, 1, 23, 59),
    dt2: DateTime(2005, 3, 1, 23, 59),
    dt3: DateTime(2012, 3, 7, 23, 59),
    dt4: DateTime(2006, 5, 1, 23, 59),
    dt5: DateTime(2017, 7, 1, 23, 59),
    dt6: DateTime(2003, 7, 1, 23, 59),
    dt7: DateTime(2010, 9, 1, 23, 59),
    dt8: DateTime(2019, 9, 1, 23, 59),
    dt9: DateTime(2014, 11, 1, 23, 59),
    dt10: DateTime(2009, 11, 1, 22, 59), // TODO daylight savings
    dt11: DateTime(2008, 1, 1, 23, 59),
    dt12: DateTime(2012, 1, 1, 23, 59),
  },
};

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Begin date for all is 2000-01-01
  // Exp 1 - Daily, repeat rate = 1, time = 10am
  // Exp 2 - Daily, repeat rate = 6, time = 12pm
  // Exp 3 - Weekdays, repeat rate = 1, time = 1pm
  // Exp 4 - Weekly SunSat, repeat rate = 1, time = 330pm
  // Exp 5 - Weekly MWF, repeat rate = 2, time = 3pm
  // Exp 6 - Monthly 11th, repeat rate = 1, time = 622pm
  // Exp 7 - Monthly 31st, repeat rate = 3, time = 5pm
  // Exp 8 - Monthly 3rd TH, repeat rate = 1, time = 9pm
  // Exp 9 - Monthly 5th MF, repeat rate = 4, time = 1010pm
  // Exp 10 - Monthly 1st all, repeat rate = 2, time = 1159pm
  final fixedExperiments =
      loadExperiments('test/data/fixed_schedule_test_data.json');
  final storageImpl = FlutterFileStorage(ESMSignalStorage.filename);

  for (var e in fixedExperiments) {
    for (var dt in testDateTimes) {
      test('Fixed ${e.title}: ${dt.toIso8601String()}', () async {
        final nextAlarm =
            (await getNextAlarmTimesOrdered(storageImpl, [e], now: dt)).first;
        expect(nextAlarm.time, equals(expected[e.title][dt]));
      });
    }
  }
}
