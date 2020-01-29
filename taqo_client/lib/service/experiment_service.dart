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
import 'alarm_service.dart' as alarm_service;
import 'notification_service.dart' as notification_manager;

class ExperimentService {
  final GoogleAuth _gAuth;

  var _joined = Map<int, Experiment>();

  bool _loaded = false;
  bool get loaded => _loaded;

  final _joinedExperimentsLoadedStreamController = StreamController<bool>.broadcast();
  Stream<bool> get onJoinedExperimentsLoaded => _joinedExperimentsLoadedStreamController.stream;

  ExperimentService._() : _gAuth = GoogleAuth() {
    _loadJoinedExperiments();
  }

  static final ExperimentService _instance = ExperimentService._();

  factory ExperimentService() => _instance;

  Future<List<Experiment>> getExperimentsFromServer() async {
    return _gAuth.getExperimentsWithSavedCredentials().then((experimentJson) {
      final List experimentJsonList = jsonDecode(experimentJson);
      final experiments = <Experiment>[];
      for (var experimentJson in experimentJsonList) {
        final experiment = Experiment.fromJson(experimentJson);
        // Don't show Experiments already joined
        if (!_joined.containsKey(experiment.id)) {
          experiments.add(experiment);
        }
      }
      return experiments;
    });
  }

  Future<Experiment> getExperimentFromServerById(experimentId) async {
    return _gAuth.getExperimentById(experimentId).then((experimentJson) {
      var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
      return Experiment.fromJson(experimentJsonObj);
    });
  }

  Future<Experiment> getPubExperimentFromServerById(experimentId) async {
    return _gAuth.getPubExperimentById(experimentId).then((experimentJson) {
      var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
      return Experiment.fromJson(experimentJsonObj);
    });
  }

  Future<List<Experiment>> updateJoinedExperiments() async {
    return _gAuth.getExperimentsByIdWithSavedCredentials(_joined.keys).then((experimentJson) {
      final List experimentJsonList = jsonDecode(experimentJson);
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

    notification_manager.cancelForExperiment(experiment);
  }

  void _loadJoinedExperiments() async {
    JoinedExperimentsStorage().readJoinedExperiments().then((List<Experiment> experiments) {
      _mapifyExperimentsById(experiments);
      // Notify listeners that joined experiments are loaded
      _joinedExperimentsLoadedStreamController.add(true);
      _loaded = true;
    });
  }

  void _mapifyExperimentsById(List<Experiment> experiments) {
    _joined = Map.fromIterable(experiments, key: (e) => e.id);
  }

  void saveJoinedExperiments() async {
    await JoinedExperimentsStorage().saveJoinedExperiments(_joined.values.toList());
    alarm_service.scheduleNextNotification();
  }

  Future<InvitationResponse> checkCode(String code) async {
    return _gAuth.checkInvitationWithSavedCredentials(code).then((jsonResponse) {
      var response = jsonDecode(jsonResponse);

      var errorMessage;
      var participantId;
      var experimentId;

      if (jsonResponse.startsWith('[')) {
        response = response.elementAt(0);
        errorMessage = response["errorMessage"];
      } else {
        participantId = response["participantId"];
        experimentId = response["experimentId"];
      }

      return InvitationResponse(
          errorMessage: errorMessage,
          participantId: participantId,
          experimentId: experimentId);
    });
  }
}
