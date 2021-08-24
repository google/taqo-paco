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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taqo_client/providers/auth_provider.dart';
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
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider<ExperimentProvider>(
                    create: (_) => ExperimentProvider(),
                  ),
                  ChangeNotifierProvider<AuthProvider>(
                    create: (_) => AuthProvider(),
                  ),
                ],
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

class ExperimentList extends StatefulWidget {
  @override
  State<ExperimentList> createState() => ExperimentListState();
}

class ExperimentListState extends State<ExperimentList> {
  static const _noExperimentsMsg = "No Experiments available to join.";

  final Widget _loadingWidget = Center(
    child: Padding(
      padding: EdgeInsets.only(top: 16.0),
      child: CircularProgressIndicator(),
    ),
  );

  bool authStatus;

  @override
  void initState() {
    super.initState();
    authStatus = false;
  }

  @override
  Widget build(BuildContext context) {
    final exProvider = Provider.of<ExperimentProvider>(context);

    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isAuthenticated != authStatus) {
      // Change in login state
      authStatus = authProvider.isAuthenticated;
      exProvider.loadAvailableExperiments();
    }

    if (exProvider.experiments == null) {
      return Center(
        child: _loadingWidget,
      );
    } else if (exProvider.experiments.isEmpty) {
      return Center(
        child: const Text(_noExperimentsMsg),
      );
    }

    final listItems = <Widget>[];
    for (var experiment in exProvider.experiments) {
      listItems.add(ExperimentListItem(experiment));
    }
    return ListView(
      children: listItems,
      shrinkWrap: true,
    );
  }
}

class ExperimentListItem extends StatelessWidget {
  final Experiment experiment;

  ExperimentListItem(this.experiment);

  void _onTapExperiment(BuildContext context, Experiment experiment) {
    Navigator.pushNamed(context, ExperimentDetailPage.routeName,
        arguments: experiment);
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
    ));
  }
}
