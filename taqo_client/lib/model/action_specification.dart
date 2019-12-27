import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/experiment_group.dart';
import 'package:taqo_client/model/paco_notification_action.dart';

import 'action_trigger.dart';

class ActionSpecification implements Comparable<ActionSpecification> {
  DateTime time;
  Experiment experiment;
  ExperimentGroup experimentGroup;

  ActionTrigger actionTrigger;

  PacoNotificationAction action;
  int actionTriggerSpecId;

  ActionSpecification(this.time, this.experiment, this.experimentGroup, this.actionTrigger,
      this.action, this.actionTriggerSpecId);

  @override
  int compareTo(ActionSpecification other) => time.compareTo(other.time);

  @override
  String toString() => '${experiment.title} - ${experimentGroup.name} - ${time.toIso8601String()}';
}
