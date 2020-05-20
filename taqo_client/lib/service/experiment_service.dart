import 'dart:async';
import 'dart:convert';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';
import 'package:taqo_common/util/schedule_printer.dart' as schedule_printer;
import 'package:taqo_common/util/zoned_date_time.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../providers/experiment_provider.dart' show sharedPrefsExperimentPauseKey;
import '../net/paco_api.dart';
import '../net/invitation_response.dart';
import '../service/platform_service.dart' as platform_service;
import '../storage/flutter_file_storage.dart';
import 'alarm/taqo_alarm.dart' as taqo_alarm;

class ExperimentService {
  final PacoApi _pacoApi;

  var _joined = Map<int, Experiment>();

  static ExperimentService _instance;

  ExperimentService._() : _pacoApi = PacoApi();

  static Future<ExperimentService> getInstance() {
    if (_instance == null) {
      final completer = Completer<ExperimentService>();
      final temp = ExperimentService._();
      temp._loadJoinedExperiments().then((_) {
        _instance = temp;
        completer.complete(_instance);
      });
      return completer.future;
    }

    return Future.value(_instance);
  }

  Future<void> _loadJoinedExperiments() async {
    final storage = await JoinedExperimentsStorage.get(FlutterFileStorage(JoinedExperimentsStorage.filename));
    return storage.readJoinedExperiments().then((List<Experiment> experiments) {
      _mapifyExperimentsById(experiments);
    });
  }

  Future<List<Experiment>> getExperimentsFromServer() {
    return _pacoApi.getExperimentsWithSavedCredentials()
        .then((response) {
          if (!response.isSuccess) {
            return <Experiment>[];
          }
          final experimentJson = response.body;
          List experimentJsonList;
          try {
            experimentJsonList = jsonDecode(experimentJson);
          } catch (e) {
            print('Error decoding Experiments response: $e');
            print ('Response was: "$experimentJson"');
            return <Experiment>[];
          }
          final experiments = <Experiment>[];
          for (var experimentJson in experimentJsonList) {
            var experiment;
            try {
              experiment = Experiment.fromJson(experimentJson);
            } catch (e) {
              print('Error parsing experiment ${experimentJson['id']}: $e');
              continue;
            }
            // Don't show Experiments already joined
            if (experiment != null && !_joined.containsKey(experiment.id)) {
              experiments.add(experiment);
            }
          }
          return experiments;
        });
  }

  Future<Experiment> getExperimentFromServerById(experimentId) {
    return _pacoApi.getExperimentByIdWithSavedCredentials(experimentId)
        .then((response) {
          if (!response.isSuccess) {
            return null;
          }
          final experimentJson = response.body;
          try {
            var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
            return Experiment.fromJson(experimentJsonObj);
          } catch (e) {
            print('Error decoding Experiments response: $e');
            print ('Response was: "$experimentJson"');
            return null;
          }
        });
  }

  Future<Experiment> getPubExperimentFromServerById(experimentId) {
    return _pacoApi.getPubExperimentById(experimentId)
        .then((response) {
          if (!response.isSuccess) {
            return null;
          }
          final experimentJson = response.body;
          try {
            var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
            return Experiment.fromJson(experimentJsonObj);
          } catch (e) {
            print('Error decoding Experiments response: $e');
            print ('Response was: "$experimentJson"');
            return null;
          }
        });
  }

  Future<List<Experiment>> updateJoinedExperiments() {
    return _pacoApi.getExperimentsByIdWithSavedCredentials(_joined.keys.toList())
        .then((response) {
          if (!response.isSuccess) {
            final experiments = <Experiment>[];
            _mapifyExperimentsById(experiments);
            saveJoinedExperiments();
            return experiments;
          }
          final experimentJson = response.body;
          List experimentJsonList;
          try {
            experimentJsonList = jsonDecode(experimentJson);
          } catch (e) {
            print('Error decoding Experiments response: $e');
            print ('Response was: "$experimentJson"');
            return <Experiment>[];
          }
          final experiments = <Experiment>[];
          for (var experimentJson in experimentJsonList) {
            experiments.add(Experiment.fromJson(experimentJson));
          }

          _mapifyExperimentsById(experiments);
          saveJoinedExperiments();
          return experiments;
        });
  }

  List<Experiment> getJoinedExperiments() => List<Experiment>.from(_joined.values);

  Event _createPacoEvent(Experiment experiment, PacoEventType eventType) {
    final event = Event();
    event.experimentId = experiment.id;
    event.experimentServerId = experiment.id;
    event.experimentName = experiment.title;
    event.experimentVersion = experiment.version;
    event.responseTime = ZonedDateTime.now();
    event.responses = {
      "schedule": schedule_printer.createStringOfAllSchedules(experiment),
    };

    switch (eventType) {
      case PacoEventType.EXPERIMENT_JOIN:
        event.responses["joined"] = "true";
        break;
      case PacoEventType.EXPERIMENT_STOP:
        event.responses["joined"] = "false";
        break;
      case PacoEventType.SCHEDULE_EDIT:
      default:
        // Nothing for now
    }

    if (experiment.recordPhoneDetails) {
      // TODO Platform implementation
    }

    return event;
  }

  void joinExperiment(Experiment experiment) async {
    _joined[experiment.id] = experiment;
    saveJoinedExperiments();
    final db = await platform_service.databaseImpl;
    db.insertEvent(_createPacoEvent(experiment, PacoEventType.EXPERIMENT_JOIN));
  }

  bool isJoined(Experiment experiment) => _joined.containsKey(experiment.id);

  void stopExperiment(Experiment experiment) async {
    final storageDir = await FlutterFileStorage.getLocalStorageDir();
    final sharedPreferences = TaqoSharedPrefs(storageDir.path);
    await sharedPreferences.remove("${sharedPrefsExperimentPauseKey}_${experiment.id}");

    _joined.remove(experiment.id);
    saveJoinedExperiments();
    final db = await platform_service.databaseImpl;
    db.insertEvent(_createPacoEvent(experiment, PacoEventType.EXPERIMENT_STOP));

    taqo_alarm.cancelForExperiment(experiment);
  }

  void _mapifyExperimentsById(List<Experiment> experiments) {
    _joined = Map.fromIterable(experiments, key: (e) => e.id);
  }

  void saveJoinedExperiments() async {
    final storage = await JoinedExperimentsStorage.get(FlutterFileStorage(JoinedExperimentsStorage.filename));
    await storage.saveJoinedExperiments(_joined.values.toList());
    taqo_alarm.schedule();
  }

  void updateExperimentSchedule(Experiment experiment) async {
    saveJoinedExperiments();

    final db = await platform_service.databaseImpl;
    db.insertEvent(_createPacoEvent(experiment, PacoEventType.SCHEDULE_EDIT));
  }

  Future<InvitationResponse> checkCode(String code) async {
    return _pacoApi.checkInvitationWithSavedCredentials(code)
        .then((response) {
          if (!response.isSuccess) {
            return null;
          }
          final jsonResponse = response.body;
          var decodedResponse = jsonDecode(jsonResponse);
          var errorMessage;
          var participantId;
          var experimentId;

          if (jsonResponse.startsWith('[')) {
            decodedResponse = decodedResponse.elementAt(0);
            errorMessage = decodedResponse["errorMessage"];
          } else {
            participantId = decodedResponse["participantId"];
            experimentId = decodedResponse["experimentId"];
          }

          return InvitationResponse(
              errorMessage: errorMessage,
              participantId: participantId,
              experimentId: experimentId);
        });
  }

  Future<void> clear() async {
    _joined.clear();
    final storage = await JoinedExperimentsStorage.get(FlutterFileStorage(JoinedExperimentsStorage.filename));
    await storage.clear();
  }
}

enum PacoEventType {
  EXPERIMENT_JOIN, SCHEDULE_EDIT, EXPERIMENT_STOP,
}
