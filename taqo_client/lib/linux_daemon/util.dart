import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../model/experiment.dart';
import '../storage/dart_file_storage.dart';

Future<List<Experiment>> readJoinedExperiments() async {
  try {
    final file = await File('$taqoDir/experiments.txt');
    if (await file.exists()) {
      String contents = await file.readAsString();
      List experimentList = jsonDecode(contents);
      var experiments = List<Experiment>();
      for (var experimentJson in experimentList) {
        var experiment = Experiment.fromJson(experimentJson);
        experiments.add(experiment);
      }
      return experiments;
    }
    print("joined experiment file does not exist or is corrupted");
    return [];
  } catch (e) {
    print("Error loading joined experiments file: $e");
    return [];
  }
}

const _lastAlarmFile = 'last_alarm.txt';

Future storeLastAlarmTime(String dt) async {
  try {
    final file = await File('$taqoDir/$_lastAlarmFile');
    file.writeAsString(dt);
  } catch (e) {
    print('Error storing last alarm time: $e');
  }
}

Future<String> readLastAlarmTime() async {
  try {
    final file = await File('$taqoDir/$_lastAlarmFile');
    if (await file.exists()) {
      return file.readAsString();
    } else {
      return null;
    }
  } catch (e) {
    print('Error reading last alarm time: $e');
    return null;
  }
}
