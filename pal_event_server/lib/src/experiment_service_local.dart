import 'dart:async';

import 'package:logging/logging.dart';

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';
import 'package:taqo_common/storage/local_file_storage.dart';

final logger = Logger('ExperimentServiceLocal');

class ExperimentServiceLocal implements ExperimentServiceLite {
  JoinedExperimentsStorage _storage;
  var _experimentCache = Map<int, Experiment>();
  DateTime _timestamp;

  static ExperimentServiceLocal _instance;

  ExperimentServiceLocal._();

  static Future<ExperimentServiceLocal> getInstance() {
    if (_instance == null) {
      final completer = Completer<ExperimentServiceLocal>();
      final temp = ExperimentServiceLocal._();
      temp._init().then((_) {
        _instance = temp;
        completer.complete(_instance);
      });
      return completer.future;
    }

    return Future.value(_instance);
  }

  void _mapifyExperimentsById(List<Experiment> experiments) {
    _experimentCache = Map.fromIterable(experiments, key: (e) => e.id);
  }

  Future<void> _loadJoinedExperiments() async {
    _timestamp = await _storage.lastModified();
    await _storage.readJoinedExperiments().then((List<Experiment> experiments) {
      _mapifyExperimentsById(experiments);
    });
  }

  Future<void> _init() async {
    _storage = await JoinedExperimentsStorage.get(
        LocalFileStorageFactory.makeLocalFileStorage(
            JoinedExperimentsStorage.filename));
    await _loadJoinedExperiments();
  }

  Future<void> _refreshIfNeeded() async {
    if (_timestamp.isBefore(await _storage.lastModified())) {
      await _loadJoinedExperiments();
    }
  }

  @override
  Future<Experiment> getExperimentById(int experimentId) async {
    await _refreshIfNeeded();
    var experiment = _experimentCache[experimentId];
    if (experiment == null) {
      logger.info(
          'Cannot find experiment $experimentId in the cache. Using fallback value...');
      experiment = Experiment()
        ..id = experimentId
        ..anonymousPublic = true;
    }
    return experiment;
  }
}
