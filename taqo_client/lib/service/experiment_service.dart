import 'dart:async';
import 'dart:convert';

import '../model/event.dart';
import '../model/experiment.dart';
import '../net/google_auth.dart';
import '../net/invitation_response.dart';
import '../storage/joined_experiments_storage.dart';
import '../storage/local_database.dart';
import '../util/schedule_printer.dart' as schedule_printer;
import '../util/zoned_date_time.dart';
import 'alarm/flutter_local_notifications.dart' as flutter_local_notifications;
import 'alarm/taqo_alarm.dart' as taqo_alarm;

class ExperimentService {
  final GoogleAuth _gAuth;

  var _joined = Map<int, Experiment>();

  static ExperimentService _instance;

  ExperimentService._() : _gAuth = GoogleAuth();

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

  Future<void> _loadJoinedExperiments() async =>
      JoinedExperimentsStorage().readJoinedExperiments().then((List<Experiment> experiments) {
        _mapifyExperimentsById(experiments);
      });

  Future<List<Experiment>> getExperimentsFromServer() async {
    return _gAuth.getExperimentsWithSavedCredentials()
        .then((response) {
          final experimentJson = response.body;
          final List experimentJsonList = jsonDecode(experimentJson);
          final experiments = <Experiment>[];
          for (var experimentJson in experimentJsonList) {
            var experiment;
            try {
              experiment = Experiment.fromJson(experimentJson);
            } catch(e) {
              print('Error parsing experiment ${experimentJson['id']}: $e');
              continue;
            }
            // Don't show Experiments already joined
            if (experiment != null && !_joined.containsKey(experiment.id)) {
              experiments.add(experiment);
            }
          }
          return experiments;
        })
        .catchError((e) => <Experiment>[]);
  }

  Future<Experiment> getExperimentFromServerById(experimentId) async {
    return _gAuth.getExperimentByIdWithSavedCredentials(experimentId)
        .then((response) {
          final experimentJson = response.body;
          var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
          return Experiment.fromJson(experimentJsonObj);
        })
        .catchError((_) => null);
  }

  Future<Experiment> getPubExperimentFromServerById(experimentId) async {
    return _gAuth.getPubExperimentById(experimentId)
        .then((response) {
          final experimentJson = response.body;
          var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
          return Experiment.fromJson(experimentJsonObj);
        })
        .catchError((_) => null);
  }

  Future<List<Experiment>> updateJoinedExperiments() async {
    return _gAuth.getExperimentsByIdWithSavedCredentials(_joined.keys.toList())
        .then((response) {
          final experimentJson = response.body;
          final List experimentJsonList = jsonDecode(experimentJson);
          final experiments = <Experiment>[];
          for (var experimentJson in experimentJsonList) {
            experiments.add(Experiment.fromJson(experimentJson));
          }

          _mapifyExperimentsById(experiments);
          saveJoinedExperiments();
          return experiments;
        })
        .catchError((_) {
          final experiments = <Experiment>[];
          _mapifyExperimentsById(experiments);
          saveJoinedExperiments();
          return experiments;
        });
  }

  List<Experiment> getJoinedExperiments() => List<Experiment>.from(_joined.values);

  Event _createJoinEvent(Experiment experiment, {bool joining}) {
    final event = Event();
    event.experimentId = experiment.id;
    event.experimentServerId = experiment.id;
    event.experimentName = experiment.title;
    event.experimentVersion = experiment.version;
    event.responseTime = ZonedDateTime.now();
    event.responses = {
      "schedule": schedule_printer.createStringOfAllSchedules(experiment),
    };
    event.responses["joined"] = joining.toString();

    if (experiment.recordPhoneDetails) {
      // TODO Platform implementation
    }

    return event;
  }

  void joinExperiment(Experiment experiment) {
    _joined[experiment.id] = experiment;
    saveJoinedExperiments();
    LocalDatabase().insertEvent(_createJoinEvent(experiment, joining: true));
  }

  bool isJoined(Experiment experiment) => _joined.containsKey(experiment.id);

  void stopExperiment(Experiment experiment) {
    _joined.remove(experiment.id);
    saveJoinedExperiments();
    LocalDatabase().insertEvent(_createJoinEvent(experiment, joining: false));

    flutter_local_notifications.cancelForExperiment(experiment);
  }

  void _mapifyExperimentsById(List<Experiment> experiments) {
    _joined = Map.fromIterable(experiments, key: (e) => e.id);
  }

  void saveJoinedExperiments() async {
    await JoinedExperimentsStorage().saveJoinedExperiments(_joined.values.toList());
    taqo_alarm.schedule();
  }

  Future<InvitationResponse> checkCode(String code) async {
    return _gAuth.checkInvitationWithSavedCredentials(code)
        .then((response) {
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
        })
        .catchError((_) => null);
  }

  Future<void> clear() async {
    _joined.clear();
    await JoinedExperimentsStorage().clear();
  }
}
