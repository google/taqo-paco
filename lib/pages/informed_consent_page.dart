import 'package:flutter/material.dart';
import 'package:flutter_html_view/flutter_html_view.dart';
import 'package:taqo_survey/model/experiment.dart';
import 'package:taqo_survey/pages/post_join_instructions_page.dart';
import 'package:taqo_survey/service/experiment_service.dart';

class InformedConsentPage extends StatefulWidget {
  static const routeName = "/informed_consent";

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
              buildInformedConsentRow(experiment),
              Divider(
                height: 16.0,
                color: Colors.black,
              ),
            ],
          ),
        ),
      persistentFooterButtons: (!ExperimentService().isJoined(experiment)) ? <Widget>[
        RaisedButton(
          child: Text("Agree", style: TextStyle(color: Colors.white)),
          onPressed: () {
            ExperimentService().joinExperiment(experiment);
              Navigator.popAndPushNamed(context, PostJoinInstructionsPage.routeName, arguments: experiment); }),
        RaisedButton(child: Text("Cancel", style: TextStyle(color: Colors.white)),
            onPressed: () {
          //TODO should this be a pop? Probably
              Navigator.pop(context, experiment); }),
      ] : null,
        );
  }

  Widget buildPreambleRow(experiment) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
      Text(
        "Attention",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Text("Please review the data that will be collected by this experiment and read the following information carefully before deciding to join this experiment. It describes how the researcher will handle and share your data."),
    ]);
  }

  Widget buildInformedConsentRow(experiment) {
    var data = experiment.informedConsentForm != null ? "<div>" + experiment.informedConsentForm + "</div>" : "No statement provided";

    return Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Informed Consent Statement from the Experiment Creator", style: TextStyle(fontWeight: FontWeight.bold),),
          Expanded(child: HtmlView(data: data)),
        ]));

  }
}
