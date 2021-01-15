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

import 'package:flutter/material.dart';

import 'package:taqo_common/model/experiment.dart';
import 'informed_consent_page.dart';

class ExperimentDetailPage extends StatefulWidget {
  static const routeName = 'experiment_detail';

  ExperimentDetailPage({Key key}) : super(key: key);

  @override
  _ExperimentDetailPageState createState() => _ExperimentDetailPageState();
}

class _ExperimentDetailPageState extends State<ExperimentDetailPage> {
  @override
  Widget build(BuildContext context) {
    Experiment experiment = ModalRoute.of(context).settings.arguments;

    return Scaffold(
        appBar: AppBar(
          title: Text(experiment.title),
          backgroundColor: Colors.indigo,
        ),
        body: Container(
          padding: EdgeInsets.all(8.0),
          //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              buildCreatorRow(experiment),
              Divider(
                height: 16.0,
                color: Colors.black,
              ),
              buildContactRow(experiment),
              Divider(
                height: 16.0,
                color: Colors.black,
              ),
              buildDescriptionRow(experiment),
              Divider(
                height: 16.0,
                color: Colors.black,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.shop),
            onPressed: () {
              Navigator.pushNamed(context, InformedConsentPage.routeName,
                  arguments: experiment);
            }));
  }

  Widget buildCreatorRow(experiment) {
    return Row(children: <Widget>[
      Text(
        "Created by: ",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(experiment.organization != null
          ? experiment.organization
          : experiment.contactEmail != null
              ? experiment.contactEmail
              : experiment.creator),
    ]);
  }

  Widget buildContactRow(experiment) {
    return Row(children: <Widget>[
      Text(
        "Contact: ",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(experiment.contactEmail != null
          ? experiment.contactEmail
          : experiment.creator),
    ]);
  }

  Widget buildDescriptionRow(experiment) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Description:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(experiment.description != null
              ? experiment.description
              : "None provided"),
        ]);
  }
}
