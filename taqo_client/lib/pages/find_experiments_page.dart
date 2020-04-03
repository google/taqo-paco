import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/net/google_auth.dart';
import 'package:taqo_client/pages/welcome_page.dart';
import 'package:taqo_client/service/experiment_service.dart';

import 'experiment_detail_page.dart';

class FindExperimentsPage extends StatefulWidget {
  static const routeName = 'find_experiments';

  FindExperimentsPage({Key key}) : super(key: key);

  @override
  _FindExperimentsPageState createState() => _FindExperimentsPageState();
}

class _FindExperimentsPageState extends State<FindExperimentsPage> {
  var gAuth = GoogleAuth();

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
            Expanded(
              child: FutureProvider<List<Experiment>>(
                create: (_) => ExperimentService.getInstance().then(
                        (service) => service.getExperimentsFromServer()),
                child: ExperimentList(),
              ),
            ),
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
}

class ExperimentList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final experiments = Provider.of<List<Experiment>>(context);
    final listItems = <Widget>[];

    if (experiments != null) {
      for (var experiment in experiments) {
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

        listItems.add(experimentRow);
      }
    }

    return ListView(children: listItems, shrinkWrap: true,);
  }
}
