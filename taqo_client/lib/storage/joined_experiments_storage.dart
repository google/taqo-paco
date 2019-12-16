import 'dart:convert';
import 'dart:io';

import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/storage/local_storage.dart';

class JoinedExperimentsStorage extends LocalFileStorage {
  static const filename = 'experiments.txt';
  static final _instance = JoinedExperimentsStorage._();

  JoinedExperimentsStorage._() : super(filename);

  factory JoinedExperimentsStorage() {
    return _instance;
  }

  Future<List<Experiment>> readJoinedExperiments() async {
    try {
      final file = await localFile;
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

  Future<File> saveJoinedExperiments(List<Experiment> experiments) async {
    // By default, jsonEncode() calls toJson() on each object
    var experimentJsonString = jsonEncode(experiments);
    return (await localFile).writeAsString(experimentJsonString, flush: true);
  }
}
