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

import 'package:json_annotation/json_annotation.dart';

import 'experiment.dart';
import 'experiment_group.dart';
import '../util/zoned_date_time.dart';

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

  int experimentId;

  @JsonKey(ignore: true)
  bool uploaded = false;

  Event();

  Event.of(Experiment experiment, ExperimentGroup experimentGroup) {
    experimentId = experiment.id;
    experimentName = experiment.title;
    experimentVersion = experiment.version;
    groupName = experimentGroup.name;
  }

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);

  static List<Map<String, dynamic>> _responsesToListOfMap(
          Map<String, dynamic> responses) =>
      responses.entries
          .map((entry) => {'name': entry.key, 'answer': entry.value})
          .toList();

  static Map<String, dynamic> _responsesFromListOfMap(List listOfMap) =>
      listOfMap == null
          ? {}
          : Map.fromIterable(listOfMap,
              key: (item) => item['name'], value: (item) => item['answer']);

  static ZonedDateTime _zonedDateTimeFromString(String string) =>
      string == null ? null : ZonedDateTime.fromString(string);

  static String _zonedDateTimeToString(ZonedDateTime zonedDateTime) =>
      zonedDateTime?.toString();

  @override
  String toString() {
    return '$experimentName - $groupName: ${responses.toString()}';
  }

  Event copy() {
    // TODO if speed is needed, do direct assignment of fields
    // This is very rarely used so it is low priority
    return Event.fromJson(toJson());
  }
}
