import 'package:flutter/material.dart';
import 'package:taqo_survey/model/experiment.dart';
import 'package:taqo_survey/net/google_auth.dart';
import 'package:taqo_survey/pages/welcome_page.dart';
import 'package:taqo_survey/service/experiment_service.dart';

import 'experiment_detail_page.dart';

class FindExperimentsPage extends StatefulWidget {
  static const routeName = '/find_experiments';

  FindExperimentsPage({Key key}) : super(key: key);

  @override
  _FindExperimentsPageState createState() => _FindExperimentsPageState();
}

class _FindExperimentsPageState extends State<FindExperimentsPage> {
  var gAuth = GoogleAuth();
  var _experimentRetriever = ExperimentService();

  List<Experiment> _experiments = [];

  @override
  void initState() {
    super.initState();
    _experimentRetriever.getExperiments().then((experiments) {
      setState(() {
        _experiments = experiments;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Experiments to Join'),
        backgroundColor: Colors.indigo,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.home),
            tooltip: 'Welcome Page',
            onPressed: () {
              Navigator.pushNamed(context, WelcomePage.routeName);
            },
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: Column(
          children: <Widget>[
            buildWelcomeTextWidget(),
            Divider(
              height: 16.0,
              color: Colors.black,
            ),
            Expanded(child: ListView(
              children: buildExperimentList(),
              shrinkWrap: true,
            )),
          ],
        ),
      ),
    );
  }

  Text buildWelcomeTextWidget() {
    return Text(
      'Find Experiments Page',
    );
  }

  List<Widget> buildExperimentList() {
    List<Widget> widgets = [];
    for (var experiment in _experiments) {
      var experimentRow = Card(
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
          Navigator.pushNamed(context, ExperimentDetailPage.routeName, arguments: experiment);
        },
      ));

      widgets.add(experimentRow);
    }
    return widgets;
  }
}
