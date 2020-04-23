import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:taqo_common/model/experiment.dart';

import 'local_file_storage.dart';

class JoinedExperimentsStorage {
  static const filename = 'experiments.txt';

  static Completer<JoinedExperimentsStorage> _completer;
  static JoinedExperimentsStorage _instance;

  ILocalFileStorage _storageImpl;

  JoinedExperimentsStorage._();

  static Future<JoinedExperimentsStorage> get(ILocalFileStorage storageImpl) {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<JoinedExperimentsStorage>();
      final temp = JoinedExperimentsStorage._();
      temp._initialize(storageImpl).then((_) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future _initialize(ILocalFileStorage storageImpl) async {
    _storageImpl = storageImpl;
  }
  
  Future<List<Experiment>> readJoinedExperiments() async {
    try {
      final file = await _storageImpl.localFile;
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
    return (await _storageImpl.localFile).writeAsString(experimentJsonString, flush: true);
  }

  Future clear() => _storageImpl.clear();
}
