import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taqo_common/model/experiment.dart';

import '../service/platform_service.dart' as platform_service;
import '../widgets/taqo_widgets.dart';
import 'survey/survey_page.dart';

class SurveyPickerPage extends StatefulWidget {
  static const routeName = 'survey_picker';

  final Experiment experiment;

  SurveyPickerPage({Key key, @required this.experiment}) : super(key: key);

  @override
  _SurveyPickerPageState createState() => _SurveyPickerPageState();
}

class _SurveyPickerPageState extends State<SurveyPickerPage> {
  final _active = <String>{};

  @override
  void initState() {
    super.initState();

    platform_service.databaseImpl.then((db) {
      db.getAllNotificationsForExperiment(widget.experiment).then((all) {
        final active = all.where((n) => n.isActive);
        setState(() {
          _active.clear();
          _active.addAll(active.map((e) => e.experimentGroupName));
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var rowChildren = <Widget>[
      buildPickSurveyPromptRow(widget.experiment),
      Divider(
        height: 16.0,
        color: Colors.black,
      ),
    ];

    rowChildren.addAll(buildSurveyList(widget.experiment));

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.experiment.title}: Choose Survey"),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      ),
    );
  }

  Widget buildPickSurveyPromptRow(experiment) {
    return const Text(
      "Please pick the survey to respond",
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }

  List<Widget> buildSurveyList(experiment) {
    List<Widget> widgets = [];
    for (var survey in experiment.getActiveSurveys()) {
      var rowChildren = <Widget>[
        if (_active.contains(survey.name))
          Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.notifications_active,
              color: Colors.redAccent,
            ),
          ),
        Expanded(
            child: InkWell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(survey.name, textScaleFactor: 1.5),
            ],
          ),
          onTap: () {
            Navigator.pushNamed(context, SurveyPage.routeName,
                arguments: [experiment, survey.name]);
          },
        )),
      ];

      widgets.add(TaqoCard(child: Row(children: rowChildren)));
    }

    return widgets;
  }
}
