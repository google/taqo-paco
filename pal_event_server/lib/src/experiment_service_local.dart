import 'dart:async';

import 'package:logging/logging.dart';
import 'package:pal_event_server/src/experiment_cache.dart';

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';
import 'package:taqo_common/storage/local_file_storage.dart';

final logger = Logger('ExperimentServiceLocal');

class ExperimentServiceLocal implements ExperimentServiceLite {
  JoinedExperimentsStorage _storage;

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
    _storage = await JoinedExperimentsStorage.get();
  }

  @override
  Future<Experiment> getExperimentById(int experimentId) async {
    var experiment = ExperimentCache.getExperimentById(experimentId);
    // Ideally, the following retrieving from database code should goes into
    // the implementation of ExperimentCache, i.e. fetching an experiment from the
    // database when there is a cache miss. However, for now I can not find a
    // good expiration strategy which guarantees that a stopped experiment will
    // be eventually removed from the cache, after potentially being used by
    // stopping events and alarm cancellation. Therefore, the current strategy
    // is to sync the cache with joined experiments, and thus the following
    // retrieving is put here. Considering the number of queries for a stopped
    // experiment is O(1), currently at most two, this should not be too bad.
    if (experiment == null) {
      logger.info('Cache miss for experiment $experimentId. Retrieving from the database...');
      experiment = await _storage.getExperimentById(experimentId);
    }
    if (experiment == null) {
      logger.info(
          'Cannot find experiment $experimentId in the cache or the database. Using the fallback value...');
      experiment = Experiment()
        ..id = experimentId
        ..anonymousPublic = true;
    }
    return experiment;
  }
}
