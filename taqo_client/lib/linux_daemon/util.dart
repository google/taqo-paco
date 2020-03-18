import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../model/experiment.dart';

String get homeDir {
  final env = Platform.environment;
  String home;
  if (Platform.isLinux) {
    home = env['HOME'];
  } else {
    throw UnsupportedError('Only supports Linux and MacOS');
  }
  return '$home/.taqo';
}

Future<List<Experiment>> readJoinedExperiments() async {
  try {
    final file = await File('$homeDir/experiments.txt');
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
