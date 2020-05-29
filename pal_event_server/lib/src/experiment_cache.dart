import 'package:taqo_common/model/experiment.dart';

class ExperimentCache {
  static Map<int, Experiment> _cache = <int, Experiment>{};
  static setCacheWithJoinedExperiment(List<Experiment> experiments) {
    _cache = {for (var experiment in experiments) experiment.id: experiment};
  }

  static Experiment getExperimentById(int experimentId) {
    return _cache[experimentId];
  }
}
