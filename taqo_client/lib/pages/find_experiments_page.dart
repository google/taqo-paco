import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taqo_common/model/experiment.dart';

import '../providers/experiment_provider.dart';
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
  @override
  Widget build(BuildContext context) {
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
              child: ChangeNotifierProvider<ExperimentProvider>(
                create: (_) => ExperimentProvider.withAvailableExperiments(),
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
  static const _noExperimentsMsg = "No Experiments available to join.";

  final Widget _loadingWidget = Center(
    child: Padding(
      padding: EdgeInsets.only(top: 16.0),
      child: CircularProgressIndicator(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExperimentProvider>(context);

    if (provider.experiments == null) {
      return Center(
        child: _loadingWidget,
      );
    } else if (provider.experiments.isEmpty) {
      return Center(
        child: const Text(_noExperimentsMsg),
      );
    }

    final listItems = <Widget>[];
    for (var experiment in provider.experiments) {
      listItems.add(ExperimentListItem(experiment));
    }
    return ListView(children: listItems, shrinkWrap: true,);
  }
}

class ExperimentListItem extends StatelessWidget {
  final Experiment experiment;

  ExperimentListItem(this.experiment);

  void _onTapExperiment(BuildContext context, Experiment experiment) {
    Navigator.pushNamed(context, ExperimentDetailPage.routeName, arguments: experiment);
  }

  @override
  Widget build(BuildContext context) {
    return TaqoCard(
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
        onTap: () => _onTapExperiment(context, experiment),
      )
    );
  }
}
