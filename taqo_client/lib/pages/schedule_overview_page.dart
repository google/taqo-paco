import 'package:flutter/material.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/storage/user_preferences.dart';

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
    _userPreferences = UserPreferences();
    super.initState();
  }


  Widget build(BuildContext context) {
    Experiment experiment = ModalRoute.of(context).settings.arguments;
    return Scaffold(
        appBar: AppBar(
          title: Text(experiment.title + "Schedule Overview"),
          backgroundColor: Colors.indigo,
        ),
        body: Container(
          padding: EdgeInsets.all(8.0),
          //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              (!experiment.isOver()) ? buildPauseRow(experiment) : Text(""),
              Divider(
                height: 16.0,
                color: Colors.black,
              ),
              Text("List scheduled by group"),
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

  Widget buildPauseRow(experiment) {
    var pauseState = "Pause";
    var pauseIcon = Icons.pause;
    if (_userPreferences.paused) {
      pauseState = "Resume";
      pauseIcon = Icons.play_arrow;
    }

    return Column(children: <Widget>[
      Text(pauseState + " experiment data collection", style: TextStyle(fontWeight: FontWeight.bold),),
      IconButton(icon: Icon(pauseIcon),
      onPressed: () {
        toggleExperimentRunning();
      },),
    ]);
  }

  void toggleExperimentRunning() {
    setState(() {
      _userPreferences.paused = !_userPreferences.paused;
    });


  }


}

