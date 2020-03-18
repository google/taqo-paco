import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/alarm/taqo_alarm.dart' as taqo_alarm;
import 'experiment.dart';

class ExperimentProvider with ChangeNotifier {
  static const EXPERIMENT_PAUSED_KEY_PREFIX = "paused";
  final Experiment experiment;

  bool _paused;

  bool get paused {
    return _paused ?? false;
  }

  set paused(bool value) {
    SharedPreferences.getInstance().then((sharedPreferences) {
      sharedPreferences.setBool("${EXPERIMENT_PAUSED_KEY_PREFIX}_${experiment.id}", value);
      _paused = value;
      notifyListeners();
      taqo_alarm.schedule();
    });
    experiment.paused = value;
  }

  ExperimentProvider(this.experiment) {
    SharedPreferences.getInstance().then((sharedPreferences) {
      _paused = sharedPreferences.getBool("${EXPERIMENT_PAUSED_KEY_PREFIX}_${experiment.id}") ?? false;
      notifyListeners();
    });
  }
}
