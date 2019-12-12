import 'package:flutter/material.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/net/google_auth.dart';
import 'package:taqo_client/pages/schedule_overview_page.dart';
import 'package:taqo_client/pages/survey/survey_page.dart';
import 'package:taqo_client/pages/survey_picker_page.dart';
import 'package:taqo_client/service/experiment_service.dart';
import 'package:taqo_client/storage/user_preferences.dart';

import 'experiment_detail_page.dart';
import 'find_experiments_page.dart';

class RunningExperimentsPage extends StatefulWidget {
  static const routeName = '/running_experiments';

  RunningExperimentsPage({Key key}) : super(key: key);

  @override
  _RunningExperimentsPageState createState() => _RunningExperimentsPageState();
}

class _RunningExperimentsPageState extends State<RunningExperimentsPage> {
  var gAuth = GoogleAuth();

  List<Experiment> _experiments = [];
  var _experimentRetriever = ExperimentService();

  var _userPreferences;

  @override
  void initState() {
    super.initState();
    _experiments = _experimentRetriever.getJoinedExperiments();
    _userPreferences = UserPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Running Experiments'),
        backgroundColor: Colors.indigo,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            tooltip: 'Find Experiments to Join',
            onPressed: () {
              Navigator.pushNamed(context, FindExperimentsPage.routeName);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Update Experiments',
            onPressed: () {
              updateExperiments();
            },
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: Column(
          children: <Widget>[
//            buildWelcomeTextWidget(),
            Divider(
              height: 16.0,
              color: Colors.black,
            ),
            ListView(
              children: buildExperimentList(),
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildExperimentList() {
    List<Widget> widgets = [];
    for (var experiment in _experiments) {
      var rowChildren = <Widget>[
        Expanded(
            child: InkWell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(experiment.title, textScaleFactor: 1.5),
              if (experiment.organization != null &&
                  experiment.organization.isNotEmpty)
                Text(experiment.organization),
              Text(experiment.contactEmail != null
                  ? experiment.contactEmail
                  : experiment.creator),
            ],
          ),
          onTap: () {
            if (experiment.getActiveSurveys().length == 1) {
              Navigator.pushNamed(context, SurveyPage.routeName,
                  arguments: [experiment, experiment.getActiveSurveys().elementAt(0).name]);
            } else if (experiment.getActiveSurveys().length > 1) {
              Navigator.pushNamed(context, SurveyPickerPage.routeName,
                  arguments: experiment);
            } else {
              // TODO no action for finished surveys
              _alertLog("This experiment has finished.");
            }
          },
        )),
      ];

      rowChildren.add(IconButton(
          icon: Icon(_userPreferences.paused ? Icons.play_arrow : Icons.pause),
          onPressed: () => setState(() => _userPreferences.paused = !_userPreferences.paused)));
      rowChildren.add(IconButton(
          icon: Icon(Icons.edit), onPressed: () => editExperiment(experiment)));
      rowChildren.add(IconButton(
          icon: Icon(Icons.email),
          onPressed: () => emailExperiment(experiment)));
      rowChildren.add(IconButton(
          icon: Icon(Icons.close),
          onPressed: () => stopExperiment(experiment)));

      var experimentRow = Card(child: Row(children: rowChildren));

      widgets.add(experimentRow);
    }
    return widgets;
  }

  void updateExperiments() {
    // TODO show progress indicator of some sort and remove once done
    _experimentRetriever.updateJoinedExperiments((experiments) {
      setState(() {
        _experiments = experiments;
      });
    });
  }

  void stopExperiment(Experiment experiment) {
    _confirmStopDialog(context).then((result) {
      if (result == ConfirmAction.ACCEPT) {
        _experimentRetriever.stopExperiment(experiment);
        setState(() {
          _experiments = _experimentRetriever.getJoinedExperiments();
        });
      }
    });
  }

  Future<ConfirmAction> _confirmStopDialog(BuildContext context) async {
    return showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Stop Experiment'),
          content: const Text(
              'Do you want to stop participating in this experiment?'),
          actions: <Widget>[
            FlatButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.CANCEL);
              },
            ),
            FlatButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.ACCEPT);
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _alertLog(msg) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(msg),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void editExperiment(Experiment experiment) {
    Navigator.pushNamed(context, ScheduleOverviewPage.routeName,
        arguments: ScheduleOverviewArguments(experiment));
  }

  void emailExperiment(Experiment experiment) {}
}

enum ConfirmAction { CANCEL, ACCEPT }
