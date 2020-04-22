import 'package:flutter/foundation.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../service/alarm/taqo_alarm.dart' as taqo_alarm;
import '../storage/flutter_file_storage.dart';

const sharedPrefsExperimentPauseKey = "paused";

class ExperimentProvider with ChangeNotifier {
  final Experiment experiment;

  bool _paused;

  bool get paused {
    return _paused ?? false;
  }

  set paused(bool value) {
    FlutterFileStorage.getLocalStorageDir().then((storageDir) async {
      final sharedPreferences = TaqoSharedPrefs(storageDir.path);
      await sharedPreferences.setBool("${sharedPrefsExperimentPauseKey}_${experiment.id}", value);
      _paused = value;
      notifyListeners();
      taqo_alarm.schedule();
    });
    experiment.paused = value;
  }

  ExperimentProvider(this.experiment) {
    FlutterFileStorage.getLocalStorageDir().then((storageDir) async {
      final sharedPreferences = TaqoSharedPrefs(storageDir.path);
      _paused =
          (await sharedPreferences.getBool("${sharedPrefsExperimentPauseKey}_${experiment.id}")) ?? false;
      notifyListeners();
    });
  }
}
