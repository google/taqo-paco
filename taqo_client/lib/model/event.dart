import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/experiment_group.dart';
import 'package:taqo_client/util/zoned_date_time.dart';

part 'event.g.dart';

@JsonSerializable()
class Event {
  // The following fields are serializable, their exported names should be recognizable by the Paco server
  // DON'T change their names unless
  // (1) the Paco server protocol was changed;
  // or
  // (2) the correct exported name was specified in @JsonKey annotation

  @JsonKey(fromJson: _responsesFromListOfMap, toJson: _responsesToListOfMap)
  Map<String, dynamic> responses = {};

  @JsonKey(name: 'experimentId')
  int experimentServerId;

  String experimentName;

  @JsonKey(
      name: 'scheduledTime',
      fromJson: _zonedDateTimeFromString,
      toJson: _zonedDateTimeToString)
  ZonedDateTime scheduleTime;

  @JsonKey(fromJson: _zonedDateTimeFromString, toJson: _zonedDateTimeToString)
  ZonedDateTime responseTime;

  int experimentVersion;

  @JsonKey(name: 'experimentGroupName')
  String groupName;

  int actionTriggerId;

  int actionTriggerSpecId;

  int actionId;

  // End of serializable fields

  @JsonKey(ignore: true)
  int id;

  @JsonKey(ignore: true)
  int experimentId;

  @JsonKey(ignore: true)
  bool uploaded;

  Event();

  Event.of(Experiment experiment, ExperimentGroup experimentGroup) {
    experimentServerId = experiment.id;
    experimentName = experiment.title;
    experimentVersion = experiment.version;
    groupName = experimentGroup.name;
    uploaded = false;
  }

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);

  static List<Map<String, dynamic>> _responsesToListOfMap(
          Map<String, dynamic> responses) =>
      responses.entries
          .map((entry) => {'name': entry.key, 'answer': entry.value})
          .toList();

  static Map<String, dynamic> _responsesFromListOfMap(
          List<Map<String, dynamic>> listOfMap) =>
      Map.fromIterable(listOfMap,
          key: (item) => item['name'], value: (item) => item['answer']);

  static ZonedDateTime _zonedDateTimeFromString(String string) =>
      string == null ? null : ZonedDateTime.fromString(string);
  static String _zonedDateTimeToString(ZonedDateTime zonedDateTime) =>
      zonedDateTime?.toString();
}
