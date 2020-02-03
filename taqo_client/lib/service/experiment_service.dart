import 'dart:async';
import 'dart:convert';

import 'package:taqo_client/model/event.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/net/google_auth.dart';
import 'package:taqo_client/net/invitation_response.dart';
import 'package:taqo_client/storage/joined_experiments_storage.dart';
import 'package:taqo_client/storage/local_database.dart';
import 'package:taqo_client/util/schedule_printer.dart' as schedule_printer;
import 'package:taqo_client/util/zoned_date_time.dart';

class ExperimentService {
  GoogleAuth _gAuth;

  var _joined = Map<int, Experiment>();

  StreamController<bool> _joinedExperimentsLoadedStreamController =
      StreamController<bool>.broadcast();

  Stream<bool> get onJoinedExperimentsLoaded =>
      _joinedExperimentsLoadedStreamController.stream;

  ExperimentService._privateConstructor() {
    _gAuth = GoogleAuth();
    loadJoinedExperiments();
  }

  static final ExperimentService _instance =
      ExperimentService._privateConstructor();

  factory ExperimentService() {
    return _instance;
  }

  Future<List<Experiment>> getExperiments() async {
    return await _gAuth
        .getExperimentsWithSavedCredentials()
        .then((experimentJson) {
      List experimentList = jsonDecode(experimentJson);
      var experiments = List<Experiment>();
      for (var experimentJson in experimentList) {
        var experiment = Experiment.fromJson(experimentJson);
        experiments.add(experiment);
      }
      return experiments;
    });
  }

  List<Experiment> getJoinedExperiments() {
    return List<Experiment>.from(_joined.values);
  }

  Event createJoinEvent(Experiment experiment, {bool joining = false}) {
    final event = Event();
    event.experimentId = experiment.id;
    event.experimentServerId = experiment.id;
    event.experimentName = experiment.title;
    event.experimentVersion = experiment.version;
    event.responseTime = ZonedDateTime.now();
    event.responses = {
      "schedule": schedule_printer.createStringOfAllSchedules(experiment),
    };
    if (joining) {
      event.responses["joined"] = "true";
    }
    if (experiment.recordPhoneDetails) {
      // TODO Platform implementation
    }
    return event;
  }

  void joinExperiment(Experiment experiment) {
    _joined[experiment.id] = experiment;
    saveJoinedExperiments();
    final event = createJoinEvent(experiment, joining: true);
    LocalDatabase().insertEvent(event);
  }

  isJoined(Experiment experiment) {
    return _joined[experiment.id] != null;
  }

  void stopExperiment(Experiment experiment) {
    _joined.remove(experiment.id);
    saveJoinedExperiments();

    final event = Event();
    event.experimentId = experiment.id;
    event.experimentServerId = experiment.id;
    event.experimentName = experiment.title;
    event.experimentVersion = experiment.version;
    event.responseTime = ZonedDateTime.now();
    event.responses = {
      "joined": "false",
    };

    LocalDatabase().insertEvent(event);
  }

  void loadJoinedExperiments() async {
    JoinedExperimentsStorage()
        .readJoinedExperiments()
        .then((List<Experiment> experiments) {
      _joined = {};
      mapifyExperimentsById(experiments);
      // notify listeners that joined experiments are loaded?
      _joinedExperimentsLoadedStreamController.add(true);
    });
  }

  void mapifyExperimentsById(List<Experiment> experiments) {
    experiments.forEach((experiment) => _joined[experiment.id] = experiment);
  }

  void saveJoinedExperiments() {
    JoinedExperimentsStorage().saveJoinedExperiments(_joined.values.toList());
  }

  Future<InvitationResponse> checkCode(String code) async {
    return await _gAuth
        .checkInvitationWithSavedCredentials(code)
        .then((jsonResponse) {
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

      var invitationResponse = InvitationResponse(
          errorMessage: errorMessage,
          participantId: participantId,
          experimentId: experimentId);
      return Future.value(invitationResponse);
    });
  }

  Future<Experiment> getExperimentById(experimentId) async {
    return await _gAuth.getExperimentById(experimentId).then((experimentJson) {
      var experimentJsonObj = jsonDecode(experimentJson);
      var experiment = Experiment.fromJson(experimentJsonObj);
      return Future.value(experiment);
    });
  }

  Future<Experiment> getPubExperimentById(experimentId) async {
    return await _gAuth
        .getPubExperimentById(experimentId)
        .then((experimentJson) {
      var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
      var experiment = Experiment.fromJson(experimentJsonObj);
      return Future.value(experiment);
    });
  }

  Future<List<Experiment>> updateJoinedExperiments(callback) async {
    final experimentJson = await _gAuth.getExperimentsByIdWithSavedCredentials(_joined.keys);
    final experimentList = jsonDecode(experimentJson);
    final experiments = List<Experiment>();
    for (var expJson in experimentList) {
      experiments.add(Experiment.fromJson(expJson));
    }
    _joined = {};
    mapifyExperimentsById(experiments);
    saveJoinedExperiments();
    callback(experiments);
    return experiments;
  }

  Future<void> clear() async {
    _joined.clear();
    await JoinedExperimentsStorage().clear();
  }
}
