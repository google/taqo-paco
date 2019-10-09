import 'dart:convert';
import 'dart:io';

import 'package:taqo_client/model/experiment.dart';

class JoinedExperimentsStorage {

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/experiments.txt');
  }

  Future<List<Experiment>> readJoinedExperiments() async {
    try {
      final file = await _localFile;
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

  Future<File>  saveJoinedExperiments(List<Experiment> experiments) async {
    // TODO for mobile platforms use secure storage apis
    // for desktop, use local secure storage apis, e.g., Macos use keychain..
    // for Fuchsia ...?

    final file = await _localFile;
    var experimentJsons = experiments.map((experiment) => json.encode(experiment.toJson())).join(",");
    var experimentJsonString = "[" + experimentJsons + "]";
    return file.writeAsString(experimentJsonString, flush: true);
  }

  getApplicationDocumentsDirectory() {
    return Directory.systemTemp;
  }

  Future<void> clearTokens() async {
     final file = await _localFile;
     if (await file.exists()) {
       await file.delete();
     }
  }
}