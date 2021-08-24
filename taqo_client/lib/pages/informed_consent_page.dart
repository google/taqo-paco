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
import 'package:flutter_html/flutter_html.dart';

import 'package:taqo_common/model/experiment.dart';
import '../service/experiment_service.dart';
import 'post_join_instructions_page.dart';
import 'schedule_overview_page.dart';

import '../widgets/taqo_widgets.dart';

class InformedConsentPage extends StatefulWidget {
  static const routeName = "informed_consent";

  InformedConsentPage({Key key}) : super(key: key);

  @override
  _InformedConsentPageState createState() => _InformedConsentPageState();
}

class _InformedConsentPageState extends State<InformedConsentPage> {
  @override
  Widget build(BuildContext context) {
    Experiment experiment = ModalRoute.of(context).settings.arguments;

    return Scaffold(
        appBar: AppBar(
          title: Text(experiment.title + " Informed Consent"),
          backgroundColor: Colors.indigo,
        ),
        body: Container(
          padding: EdgeInsets.all(8.0),
          //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              buildPreambleRow(experiment),
              Divider(
                height: 16.0,
                color: Colors.black,
              ),
              Expanded(child: buildInformedConsentRow(experiment)),
              Divider(
                height: 16.0,
                color: Colors.black,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                TaqoRoundButton(
                  child: const Text(
                    "Edit schedule",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: experiment.userCanEditAtLeastOneSchedule()
                      ? () {
                          Navigator.pushNamed(
                              context, ScheduleOverviewPage.routeName,
                              arguments: ScheduleOverviewArguments(experiment,
                                  fromConsentPage: true));
                        }
                      : null,
                )
              ]),
            ],
          ),
        ),
        persistentFooterButtons: <Widget>[
          TaqoRoundButton(
              child: Text("Agree", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final service = await ExperimentService.getInstance();
                service.joinExperiment(experiment);
                Navigator.popAndPushNamed(
                    context, PostJoinInstructionsPage.routeName,
                    arguments: experiment);
              }),
          TaqoRoundButton(
              child: Text("Cancel", style: TextStyle(color: Colors.white)),
              onPressed: () {
                // TODO should this be a pop? Probably
                Navigator.pop(context, experiment);
              }),
        ]);
  }

  Widget buildPreambleRow(experiment) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Attention",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
              "Please review the data that will be collected by this experiment and read the following information carefully before deciding to join this experiment. It describes how the researcher will handle and share your data."),
        ]);
  }

  Widget buildInformedConsentRow(experiment) {
    var data = experiment.informedConsentForm != null
        ? "<div>${experiment.informedConsentForm}</div>"
        : "No statement provided";

    return SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          Text(
            "Informed Consent Statement from the Experiment Creator",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Html(data: data),
        ]));
  }
}
