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

// @dart=2.9

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'action_trigger.dart';
import 'experiment.dart';
import 'experiment_group.dart';
import 'paco_notification_action.dart';

part 'action_specification.g.dart';

@JsonSerializable()
class ActionSpecification implements Comparable<ActionSpecification> {
  DateTime time;
  DateTime timeUTC;
  Experiment experiment;
  ExperimentGroup experimentGroup;

  ActionTrigger actionTrigger;

  PacoNotificationAction action;
  int actionTriggerSpecId;

  @visibleForTesting
  ActionSpecification.empty();

  ActionSpecification(this.time, this.experiment, this.experimentGroup,
      this.actionTrigger, this.action, this.actionTriggerSpecId) {
    if (action != null && action.timeout == null) {
      action.timeout = 59;
    }
    timeUTC = time.toUtc();
  }

  factory ActionSpecification.fromJson(Map<String, dynamic> json) =>
      _$ActionSpecificationFromJson(json);

  Map<String, dynamic> toJson() => _$ActionSpecificationToJson(this);

  @override
  int compareTo(ActionSpecification other) => time.compareTo(other.time);

  @override
  String toString() =>
      '${experiment.title} - ${experimentGroup.name} - ${actionTriggerSpecId} - '
      '${time.toIso8601String()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionSpecification &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          experiment.id == other.experiment.id &&
          experimentGroup.name == other.experimentGroup.name;

  @override
  int get hashCode =>
      time.hashCode ^ experiment.id.hashCode ^ experimentGroup.name.hashCode;
}
