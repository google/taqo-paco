import 'package:flutter/material.dart';
import 'package:taqo_survey/model/experiment.dart';
import 'package:taqo_survey/service/experiment_service.dart';

import 'informed_consent_page.dart';

class ExperimentDetailPage extends StatefulWidget {
  static const routeName = '/experiment_detail';

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
        floatingActionButton: Visibility(visible: !ExperimentService().isJoined(experiment),
        child: FloatingActionButton(
            child: Icon(Icons.shop),
            onPressed: () {
                    Navigator.pushNamed(context, InformedConsentPage.routeName,
                        arguments: experiment);
                  }
                )));

    }

  Widget buildCreatorRow(experiment) {
    return Row(children: <Widget>[
      Text(
        "Created by: ",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(experiment.organization != null
          ? experiment.organization
          : experiment.contactEmail != null ? experiment.contactEmail : experiment.creator),
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
