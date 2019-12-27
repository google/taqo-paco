import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_client/model/action_specification.dart';

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

  NotificationHolder(this.id, this.alarmTime, this.experimentId, this.noticeCount, this.timeoutMillis,
      this.experimentGroupName, this.actionTriggerId, this.actionId, this.notificationSource,
      this.message, this.actionTriggerSpecId);

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

  factory NotificationHolder.fromJson(Map<String, dynamic> json) => _$NotificationHolderFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationHolderToJson(this);

  bool isActive() =>
      DateTime.now().isBefore(DateTime(alarmTime).add(Duration(milliseconds: timeoutMillis)));

  bool isCustomNotification() =>
      notificationSource == null ? false : notificationSource == CUSTOM_GENERATED_NOTIFICATION;

  bool matches(ActionSpecification actionSpecification) =>
      experimentId == actionSpecification.experiment.id &&
      experimentGroupName == actionSpecification.experimentGroup.name &&
      actionTriggerId == actionSpecification.actionTrigger.id &&
      actionId == actionSpecification.action.id &&
      actionTriggerSpecId == actionSpecification.actionTriggerSpecId &&
      alarmTime == actionSpecification.time.millisecondsSinceEpoch;
}
