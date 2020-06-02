import 'dart:async';

import 'package:logging/logging.dart';
import 'package:pal_event_server/src/experiment_cache.dart';

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';

final logger = Logger('ExperimentServiceLocal');

class ExperimentServiceLocal implements ExperimentServiceLite {
  ExperimentCache _cache;

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

  Future<void> _init() async {
    _cache = await ExperimentCache.getInstance();
  }

  @override
  Future<Experiment> getExperimentById(int experimentId) async {
    var experiment = await _cache.getExperimentById(experimentId);

    if (experiment == null) {
      logger.info(
          'Cannot find experiment $experimentId in the cache or the database. Using the fallback value...');
      experiment = Experiment()
        ..id = experimentId
        ..anonymousPublic = true;
    }
    return experiment;
  }

  Future<List<Experiment>> getJoinedExperiments() async {
    return _cache.getJoinedExperiments();
  }

}
