import 'dart:async';

import '../model/experiment.dart';

abstract class ExperimentServiceLite {
  FutureOr<Experiment> getExperimentById(int experimentId);
}

typedef ExperimentServiceLiteFactoryFunction = FutureOr<ExperimentServiceLite> Function();

class ExperimentServiceLiteFactory {
  static ExperimentServiceLiteFactoryFunction _factory;

  static void initialize(ExperimentServiceLiteFactoryFunction factory) {
    _factory = factory;
  }

  static FutureOr<ExperimentServiceLite> makeExperimentServiceLiteOrFuture() {
    return _factory();
  }
}
