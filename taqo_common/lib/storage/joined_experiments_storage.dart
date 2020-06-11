import 'dart:async';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/base_database.dart';

final _logger = Logger('JoinedExperimentStorage');

class JoinedExperimentsStorage {

  static Completer<JoinedExperimentsStorage> _completer;
  static JoinedExperimentsStorage _instance;

  BaseDatabase _db;

  JoinedExperimentsStorage._();

  static Future<JoinedExperimentsStorage> get() {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<JoinedExperimentsStorage>();
      final temp = JoinedExperimentsStorage._();
      temp._initialize().then((_) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future _initialize() async {
    _db = await DatabaseFactory.makeDatabaseOrFuture();
  }
  
  Future<List<Experiment>> readJoinedExperiments() async {
    try {
      return _db.getJoinedExperiments();
    } catch (e) {
      _logger.warning("Error loading joined experiments: $e");
      return [];
    }
  }

  Future<void> saveJoinedExperiments(List<Experiment> experiments) async {
    await _db.saveJoinedExperiments(experiments);
  }

  Future<Experiment> getExperimentById(int experimentId) {
    return _db.getExperimentById(experimentId);
  }

  Future<void> savePausedStatus(Experiment experiment, bool paused) async {
    await _db.setExperimentPausedStatus(experiment, paused);
  }

  Future<Map<int, bool>> loadPausedStatuses(Iterable<Experiment> experiments) async {
    return await _db.getExperimentsPausedStatus(experiments);
  }

}
