import 'package:flutter/material.dart';
import 'package:taqo_client/model/action_trigger.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/schedule_trigger.dart';
import 'package:taqo_client/pages/schedule_detail_page.dart';
import 'package:taqo_client/storage/user_preferences.dart';
import 'package:taqo_client/util/schedule_printer.dart' as schedule_printer;

class ScheduleOverviewPage extends StatefulWidget {
  static const routeName = '/schedule_overview';

  ScheduleOverviewPage({Key key}) : super(key: key);

  @override
  _ScheduleOverviewPageState createState() => _ScheduleOverviewPageState();
}


class _ScheduleOverviewPageState extends State<ScheduleOverviewPage> {
  var _userPreferences;

  @override
  initState() {
    super.initState();
    _userPreferences = UserPreferences();
  }


  Widget build(BuildContext context) {
    Experiment experiment = ModalRoute.of(context).settings.arguments;
    return Scaffold(
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
              const Text("Tap to edit schedule, if allowed", style: TextStyle(fontSize: 20)),
              ListView(
                children: _buildExperimentGroupScheduleList(experiment),
                shrinkWrap: true,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.done),tooltip: "Done",
            onPressed: () {
              Navigator.pop(context);
            })
    );
  }

  List<Widget> _buildExperimentGroupScheduleList(Experiment experiment) {
    final List<Widget> widgets = [];
    for (var i = 0; i < experiment.groups.length; i++) {
      final group = experiment.groups[i];
      if (group == null) {
        continue;
      }
      for (var actionTrigger in group.actionTriggers) {
        if (actionTrigger == null ||
            ActionTrigger.SCHEDULE_TRIGGER_TYPE_SPECIFIER != actionTrigger.type ||
            actionTrigger is! ScheduleTrigger) {
          continue;
        }
        final scheduleTrigger = actionTrigger as ScheduleTrigger;
        if (scheduleTrigger.schedules == null || scheduleTrigger.schedules.isEmpty) {
          continue;
        }
        widgets.add(Divider());
        widgets.add(Text(group.name == null || group.name.isEmpty || group.name == "null"
            ? "Question ${i + 1}"
            : group.name));
        for (var schedule in scheduleTrigger.schedules) {
          var rowChildren = <Widget>[
            Expanded(
                child: InkWell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(schedule_printer.toPrettyString(schedule),
                        style: TextStyle(fontSize: 18),),
                    ],
                  ),
                  onTap: () {
                    if (schedule.userEditable && !schedule.onlyEditableOnJoin) {
                      Navigator.pushNamed(context, ScheduleDetailPage.routeName,
                          arguments: ScheduleDetailArguments(experiment, schedule));
                    }
                  },
                )),
          ];

          var experimentRow = Card(child: Padding(padding: EdgeInsets.all(8),
              child: Row(children: rowChildren)));
          widgets.add(experimentRow);
        }
      }
    }
    return widgets;
  }
}
