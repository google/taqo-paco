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
import 'package:meta/meta.dart';

import 'action_specification.dart';

part 'notification_holder.g.dart';

@JsonSerializable()
class NotificationHolder {
  static const DEFAULT_SIGNAL_GROUP = "default";
  static const CUSTOM_GENERATED_NOTIFICATION = "customGenerated";

  int id;
  int alarmTime;
  int experimentId;
  int noticeCount;
  int timeoutMillis;

  // The source of this experiment, e.g. one of the signal groups (currently only one)
  // or a custom notification created by API
  String notificationSource = DEFAULT_SIGNAL_GROUP;
  String message;

  String experimentGroupName;
  int actionTriggerId;
  int actionId;
  int actionTriggerSpecId;

  int snoozeTime;
  int snoozeCount;

  @visibleForTesting
  NotificationHolder.empty();

  NotificationHolder(
      this.id,
      this.alarmTime,
      this.experimentId,
      this.noticeCount,
      this.timeoutMillis,
      this.experimentGroupName,
      this.actionTriggerId,
      this.actionId,
      this.notificationSource,
      this.message,
      this.actionTriggerSpecId);

  NotificationHolder.of(NotificationHolder holder) {
    id = holder.id;
    alarmTime = holder.alarmTime;
    experimentId = holder.experimentId;
    noticeCount = holder.noticeCount;
    timeoutMillis = holder.timeoutMillis;
    experimentGroupName = holder.experimentGroupName;
    actionTriggerId = holder.actionTriggerId;
    actionId = holder.actionId;
    notificationSource = holder.notificationSource;
    message = holder.message;
    actionTriggerSpecId = holder.actionTriggerSpecId;
  }

  factory NotificationHolder.fromJson(Map<String, dynamic> json) =>
      _$NotificationHolderFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationHolderToJson(this);

  bool get isActive {
    final alarmStart = DateTime.fromMillisecondsSinceEpoch(alarmTime);
    final alarmEnd = alarmStart.add(Duration(milliseconds: timeoutMillis));
    final now = DateTime.now();
    return alarmStart.isBefore(now) && now.isBefore(alarmEnd);
  }

  bool get isFuture {
    final alarmStart = DateTime.fromMillisecondsSinceEpoch(alarmTime);
    final now = DateTime.now();
    return alarmStart.isAfter(now);
  }

  bool isCustomNotification() => notificationSource == null
      ? false
      : notificationSource == CUSTOM_GENERATED_NOTIFICATION;

  bool matchesAction(ActionSpecification actionSpecification) =>
      experimentId == actionSpecification.experiment.id &&
      experimentGroupName == actionSpecification.experimentGroup.name &&
      actionTriggerId == actionSpecification.actionTrigger.id &&
      actionId == actionSpecification.action.id &&
      actionTriggerSpecId == actionSpecification.actionTriggerSpecId &&
      alarmTime == actionSpecification.time.millisecondsSinceEpoch;

  bool sameGroupAs(NotificationHolder other) =>
      experimentId == other.experimentId &&
      experimentGroupName == other.experimentGroupName;
}
