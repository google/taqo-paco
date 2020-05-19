import 'dart:async';

import '../model/experiment.dart';

abstract class ExperimentCache {
  Experiment getExperimentById(int experimentId);
}

typedef ExperimentCacheFactoryFunction = FutureOr<ExperimentCache> Function();

class ExperimentCacheFactory {
  static ExperimentCacheFactoryFunction _factory;

  static void initialize(ExperimentCacheFactoryFunction factory) {
    _factory = factory;
  }

  static FutureOr<ExperimentCache> makeExperimentCacheOrFuture() {
    return _factory();
  }
}
