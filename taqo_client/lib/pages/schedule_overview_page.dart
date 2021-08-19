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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:taqo_common/model/action_trigger.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/schedule.dart';
import 'package:taqo_common/model/schedule_trigger.dart';
import 'package:taqo_common/util/schedule_printer.dart' as schedule_printer;

import '../service/experiment_service.dart';
import '../widgets/taqo_widgets.dart';
import 'schedule_detail_page.dart';

class ScheduleOverviewArguments {
  final Experiment experiment;
  final bool fromConsentPage;

  ScheduleOverviewArguments(this.experiment, {this.fromConsentPage = false});
}

class ScheduleRevision {
  final Experiment experiment;
  final int scheduleId;
  final Schedule schedule;
  ScheduleRevision(this.experiment, this.scheduleId, this.schedule);
}

class ScheduleOverviewPage extends StatefulWidget {
  static const routeName = 'schedule_overview';

  ScheduleOverviewPage({Key key}) : super(key: key);

  @override
  _ScheduleOverviewPageState createState() => _ScheduleOverviewPageState();
}

class _ScheduleOverviewPageState extends State<ScheduleOverviewPage> {
  final _scheduleChangesToRevert = List<ScheduleRevision>();

  ScheduleOverviewArguments args;
  Experiment experiment;

  @override
  initState() {
    super.initState();
    _scheduleChangesToRevert.clear();
  }

  Future<bool> _onWillPop() {
    if (_scheduleChangesToRevert.isEmpty) {
      Navigator.pop(context);
      return Future.value(false);
    }

    // For each Button Navigator.pop() should return true because we close the Dialog regardless
    return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Are you sure?'),
            content: Text('Discard pending schedule changes?'),
            actions: <Widget>[
              FlatButton(
                onPressed: _onDiscardChanges,
                child: Text('Discard'),
              ),
              FlatButton(
                onPressed: _onSaveChanges,
                child: Text('Save'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget build(BuildContext context) {
    args = ModalRoute.of(context).settings.arguments;
    experiment = args.experiment;

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            appBar: AppBar(
              title: Text("${experiment.title} Schedule Overview"),
              backgroundColor: Colors.indigo,
            ),
            body: Container(
              padding: EdgeInsets.all(8.0),
              //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text("Tap to edit schedule, if allowed",
                      style: TextStyle(fontSize: 20)),
                  ListView(
                    children: _buildExperimentGroupScheduleList(
                        experiment, args.fromConsentPage),
                    shrinkWrap: true,
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              child: Icon(Icons.done),
              tooltip: "Done",
              onPressed: _onSaveChanges,
            )));
  }

  List<Widget> _buildExperimentGroupScheduleList(
      Experiment experiment, bool fromConsentPage) {
    final List<Widget> widgets = [];
    for (var i = 0; i < experiment.groups.length; i++) {
      final group = experiment.groups[i];
      if (group == null) {
        continue;
      }
      for (var actionTrigger in group.actionTriggers) {
        if (actionTrigger == null ||
            ActionTrigger.SCHEDULE_TRIGGER_TYPE_SPECIFIER !=
                actionTrigger.type ||
            actionTrigger is! ScheduleTrigger) {
          continue;
        }
        final scheduleTrigger = actionTrigger as ScheduleTrigger;
        if (scheduleTrigger.schedules == null ||
            scheduleTrigger.schedules.isEmpty) {
          continue;
        }
        widgets.add(Divider());
        widgets.add(Text(
            group.name == null || group.name.isEmpty || group.name == "null"
                ? "Question ${i + 1}"
                : group.name));
        for (var schedule in scheduleTrigger.schedules) {
          var rowChildren = <Widget>[
            Expanded(
                child: InkWell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          schedule_printer.toPrettyString(schedule),
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    onTap: () =>
                        _onTapSchedule(experiment, schedule, fromConsentPage))),
          ];

          var experimentRow = TaqoCard(child: Row(children: rowChildren));
          widgets.add(experimentRow);
        }
      }
    }
    return widgets;
  }

  void _onTapSchedule(
      Experiment experiment, Schedule schedule, bool fromConsentPage) async {
    if (schedule.userEditable &&
        (!schedule.onlyEditableOnJoin || fromConsentPage)) {
      // TODO Ugly method of cloning
      var scheduleClone =
          Schedule.fromJson(jsonDecode(jsonEncode(schedule.toJson())));
      final wasChanged = await Navigator.pushNamed(
          context, ScheduleDetailPage.routeName,
          arguments: ScheduleDetailArguments(experiment, scheduleClone));
      if (wasChanged ?? false) {
        // Tentatively updates the schedule
        setState(() {
          experiment.updateSchedule(schedule.id, scheduleClone);
        });
        // Cache changes for revert
        _scheduleChangesToRevert
            .add(ScheduleRevision(experiment, schedule.id, schedule));
      }
    }
  }

  void _onDiscardChanges() {
    // Revert changes
    if (_scheduleChangesToRevert.isNotEmpty) {
      for (var change in _scheduleChangesToRevert) {
        change.experiment.updateSchedule(change.scheduleId, change.schedule);
      }
    }
    Navigator.pop(context, true);
  }

  void _onSaveChanges() async {
    // Persist changes
    if (_scheduleChangesToRevert.isNotEmpty) {
      final service = await ExperimentService.getInstance();
      service.updateExperimentSchedule(experiment);
    }
    Navigator.pop(context, true);
  }
}
