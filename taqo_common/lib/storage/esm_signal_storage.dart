// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'local_file_storage.dart';

final _logger = Logger('EsmSignalStorage');

class ESMSignalStorage {
  static const filename = "esm_signals.json";
  static const date = "date";
  static const experiment = "experimentId";
  static const time = "alarmTime";
  static const group = "groupName";
  static const actionTrigger = "actionTriggerId";
  static const schedule = "scheduleId";

  static Completer<ESMSignalStorage> _completer;
  static ESMSignalStorage _instance;

  ILocalFileStorage _storageImpl;

  ESMSignalStorage._();

  static Future<ESMSignalStorage> get(ILocalFileStorage storageImpl) {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<ESMSignalStorage>();
      final temp = ESMSignalStorage._();
      temp._initialize(storageImpl).then((_) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future _initialize(ILocalFileStorage storageImpl) async {
    _storageImpl = storageImpl;
  }

  Future<void> storeSignal(
      DateTime periodStart,
      int experimentId,
      DateTime alarmTime,
      String groupName,
      int actionTriggerId,
      int scheduleId) async {
    try {
      final file = await _storageImpl.localFile;
      await file.writeAsString(
          jsonEncode({
            date: periodStart.toIso8601String(),
            experiment: experimentId,
            time: alarmTime.toIso8601String(),
            group: groupName,
            actionTrigger: actionTriggerId,
            schedule: scheduleId,
          }),
          mode: FileMode.append);
      await file.writeAsString('\n', mode: FileMode.append, flush: true);
    } catch (e) {
      _logger.warning("Error storing esm signal: $e");
    }
  }

  Future<List<DateTime>> getSignals(DateTime periodStart, int experimentId,
      String groupName, int actionTriggerId, int scheduleId) async {
    final signals = <DateTime>[];
    try {
      final file = await _storageImpl.localFile;
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (var line in lines) {
          var m;
          try {
            m = jsonDecode(line);
          } catch (_) {
            continue;
          }
          if (m[date] == periodStart.toIso8601String() &&
              m[experiment] == experimentId &&
              m[group] == groupName &&
              m[actionTrigger] == actionTriggerId &&
              m[schedule] == scheduleId) {
            signals.add(DateTime.parse(m[time]));
          }
        }
      } else {
        _logger.info("esm signal file does not exist or is corrupted");
      }
    } catch (e) {
      _logger.warning("Error reading esm signal: $e");
    }
    return signals;
  }

  @visibleForTesting
  Future<List<Map>> getAllSignals() async {
    final signals = <Map>[];
    try {
      final file = await _storageImpl.localFile;
      assert(file.existsSync());
      for (var line in file.readAsLinesSync()) {
        try {
          signals.add(jsonDecode(line));
        } catch (_) {}
      }
    } catch (e) {
      _logger.warning("Error reading esm signals: $e");
    }
    return signals;
  }

  Future deleteAllSignals() async {
    try {
      final file = await _storageImpl.localFile;
      if (await file.exists()) {
        return file.delete();
      }
    } catch (e) {
      _logger.warning("Error reading esm signals: $e");
    }
  }

  Future<void> deleteAllSignalsForSurvey(int experimentId) async {
    // TODO Perhaps can be improved
    final allSignals = await getAllSignals();
    await deleteAllSignals();
    allSignals.removeWhere(
        (signal) => int.tryParse(signal[experiment]) == experimentId);
    try {
      final file = await _storageImpl.localFile;
      for (var signal in allSignals) {
        await file.writeAsString(jsonEncode(signal), mode: FileMode.append);
        await file.writeAsString('\n', mode: FileMode.append, flush: true);
      }
    } catch (e) {
      _logger.warning("Error storing esm signal: $e");
    }
  }

  Future<void> deleteSignalsForPeriod(DateTime periodStart, int experimentId,
      String groupName, int actionTriggerId, int scheduleId) async {
    // TODO Perhaps can be improved
    final allSignals = await getAllSignals();
    await deleteAllSignals();
    allSignals.removeWhere((signal) =>
        DateTime.tryParse(signal[date]) == periodStart &&
        int.tryParse(signal[experiment]) == experimentId &&
        signal[groupName] == groupName &&
        int.tryParse(signal[actionTrigger]) == actionTriggerId &&
        int.tryParse(signal[schedule]) == scheduleId);
    try {
      final file = await _storageImpl.localFile;
      for (var signal in allSignals) {
        await file.writeAsString(jsonEncode(signal), mode: FileMode.append);
        await file.writeAsString('\n', mode: FileMode.append, flush: true);
      }
    } catch (e) {
      _logger.warning("Error storing esm signal: $e");
    }
  }

  Future clear() => _storageImpl.clear();
}
