import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';

Future<List<Experiment>> readJoinedExperiments() async {
  try {
    final taqoDir = DartFileStorage.getLocalStorageDir().path;
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
