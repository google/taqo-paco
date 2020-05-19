import 'dart:async';

import 'package:logging/logging.dart';

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/service/experiment_cache.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';
import 'package:taqo_common/storage/local_file_storage.dart';

final logger = Logger('ExperimentServiceLocal');

class ExperimentServiceLocal implements ExperimentCache {
  var _experimentCahce = Map<int, Experiment>();

  static ExperimentServiceLocal _instance;

  ExperimentServiceLocal._();

  static Future<ExperimentServiceLocal> getInstance() {
    if (_instance == null) {
      final completer = Completer<ExperimentServiceLocal>();
      final temp = ExperimentServiceLocal._();
      temp._loadJoinedExperiments().then((_) {
        _instance = temp;
        completer.complete(_instance);
      });
      return completer.future;
    }

    return Future.value(_instance);
  }

  void _mapifyExperimentsById(List<Experiment> experiments) {
    _experimentCahce = Map.fromIterable(experiments, key: (e) => e.id);
  }

  Future<void> _loadJoinedExperiments() async {
    final storage = await JoinedExperimentsStorage.get(
        LocalFileStorageFactory.makeLocalFileStorage(
            JoinedExperimentsStorage.filename));
    await storage.readJoinedExperiments().then((List<Experiment> experiments) {
      _mapifyExperimentsById(experiments);
    });
  }

  @override
  Experiment getExperimentById(int experimentId) {
    var experiment = _experimentCahce[experimentId];
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
