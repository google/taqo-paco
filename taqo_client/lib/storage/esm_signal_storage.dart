import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:taqo_client/storage/local_storage.dart';

class ESMSignalStorage extends LocalFileStorage {
  static const filename = "esm_signals.json";
  static const date = "date";
  static const experiment = "experimentId";
  static const time = "alarmTime";
  static const group = "groupName";
  static const actionTrigger = "actionTriggerId";
  static const schedule = "scheduleId";

  static final _instance = ESMSignalStorage._();

  ESMSignalStorage._() : super(filename);

  factory ESMSignalStorage() {
    return _instance;
  }

  Future<void> storeSignal(DateTime periodStart, int experimentId, DateTime alarmTime,
      String groupName, int actionTriggerId, int scheduleId) async {
    try {
      final file = await localFile;
      await file.writeAsString(jsonEncode({
        date: periodStart.toIso8601String(),
        experiment: experimentId,
        time: alarmTime.toIso8601String(),
        group: groupName,
        actionTrigger: actionTriggerId,
        schedule: scheduleId,
      }), mode: FileMode.append);
      await file.writeAsString('\n', mode: FileMode.append, flush: true);
    } catch (e) {
      print("Error storing esm signal: $e");
    }
  }

  Future<List<DateTime>> getSignals(DateTime periodStart, int experimentId, String groupName,
      int actionTriggerId, int scheduleId) async {
    final signals = <DateTime>[];
    try {
      final file = await localFile;
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (var line in lines) {
          final m = jsonDecode(line);
          if (m[date] == periodStart.toIso8601String() && m[experiment] == experimentId &&
              m[group] == groupName && m[actionTrigger] == actionTriggerId &&
              m[schedule] == scheduleId) {
            signals.add(DateTime.parse(m[time]));
          }
        }
      } else {
        print("esm signal file does not exist or is corrupted");
      }
    } catch (e) {
      print("Error reading esm signal: $e");
    }
    return signals;
  }

  @visibleForTesting
  Future<List<Map>> getAllSignals() async {
    final signals = <Map>[];
    try {
      final file = await localFile;
      assert(file.existsSync());
      for (var line in file.readAsLinesSync()) {
        signals.add(jsonDecode(line));
      }
    } catch (e) {
      print("Error reading esm signals: $e");
    }
    return signals;
  }

  @visibleForTesting
  Future<void> deleteAllSignals() async {
    try {
      final file = await localFile;
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      print("Error reading esm signals: $e");
    }
  }

  Future<void> deleteAllSignalsForSurvey(int experimentId) async {
    // TODO Perhaps can be improved
    final allSignals = await getAllSignals();
    await deleteAllSignals();
    allSignals.removeWhere((signal) => int.tryParse(signal[experiment]) == experimentId);
    try {
      final file = await localFile;
      for (var signal in allSignals) {
        await file.writeAsString(jsonEncode(signal), mode: FileMode.append);
        await file.writeAsString('\n', mode: FileMode.append, flush: true);
      }
    } catch (e) {
      print("Error storing esm signal: $e");
    }
  }

  Future<void> deleteSignalsForPeriod(DateTime periodStart, int experimentId, String groupName,
      int actionTriggerId, int scheduleId) async {
    // TODO Perhaps can be improved
    final allSignals = await getAllSignals();
    await deleteAllSignals();
    allSignals.removeWhere((signal) =>
        DateTime.tryParse(signal[date]) == periodStart &&
        int.tryParse(signal[experiment]) == experimentId &&
        signal[groupName] == groupName &&
        int.tryParse(signal[actionTrigger]) == actionTriggerId &&
        int.tryParse(signal[schedule]) == scheduleId
    );
    try {
      final file = await localFile;
      for (var signal in allSignals) {
        await file.writeAsString(jsonEncode(signal), mode: FileMode.append);
        await file.writeAsString('\n', mode: FileMode.append, flush: true);
      }
    } catch (e) {
      print("Error storing esm signal: $e");
    }
  }
}
