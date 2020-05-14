import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:taqo_common/model/experiment.dart';
import '../service/experiment_service.dart';
import '../widgets/taqo_page.dart';
import '../widgets/taqo_widgets.dart';
import 'experiment_detail_page.dart';

class FindExperimentsPage extends StatefulWidget {
  static const routeName = 'find_experiments';

  FindExperimentsPage({Key key}) : super(key: key);

  @override
  _FindExperimentsPageState createState() => _FindExperimentsPageState();
}

class _FindExperimentsPageState extends State<FindExperimentsPage> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    Widget _loadingWidget = Center(
      child: Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: CircularProgressIndicator(),
      ),
    );

    return TaqoScaffold(
      title: 'Find Experiments to Join',
      body: Container(
        padding: EdgeInsets.all(8.0),
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
                  (service) => service.getExperimentsFromServer().then((v) {
                    setState(() {
                      _isLoading = false;
                    });
                    return v;
                  })),
                child: _isLoading ? _loadingWidget : ExperimentList(),
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
        var experimentRow = TaqoCard(
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
            )
        );

        listItems.add(experimentRow);
      }
    }

    return ListView(children: listItems, shrinkWrap: true,);
  }
}
