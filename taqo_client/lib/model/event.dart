import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_client/util/time_util.dart';

part 'event.g.dart';

@JsonSerializable()

// TODO add the other properties of event here.
class Event {
  // The following fields are serializable, their exported names should be recognizable by the Paco server
  // DON'T change their names unless
  // (1) the Paco server protocol was changed;
  // or
  // (2) the correct exported name was specified in @JsonKey annotation

  Map<String, dynamic> responses = {};

  @JsonKey(name: 'experimentId')
  int experimentServerId;

  String experimentName;

  @JsonKey(name: 'scheduledTime', fromJson: TimeUtil.dateTimeFromString, toJson: TimeUtil.dateTimeToString)
  DateTime scheduleTime;

  @JsonKey(fromJson: TimeUtil.dateTimeFromString, toJson: TimeUtil.dateTimeToString)
  DateTime responseTime;

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

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);

}
