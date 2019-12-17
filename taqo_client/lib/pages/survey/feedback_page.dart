import 'package:flutter/material.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/experiment_group.dart';
import '../running_experiments_page.dart';

class FeedbackPage extends StatefulWidget {
  static const routeName = '/feedback';

  FeedbackPage({Key key}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  Experiment _experiment;

  ExperimentGroup _experimentGroup;

  @override
  Widget build(BuildContext context) {
    var list = ModalRoute.of(context).settings.arguments as List;
    _experiment = list.elementAt(0) as Experiment;
    _experimentGroup = list.elementAt(1) as ExperimentGroup;


    return Scaffold(
        appBar: AppBar(
          title: Text(_experimentGroup.name),
          backgroundColor: Colors.indigo,
        ),
        body: Container(
          padding: EdgeInsets.all(8.0),
          //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              buildFeedbackMessageRow(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.done),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, RunningExperimentsPage.routeName, (Route route) => false)
        )
    );
  }

  // TODO determine if it is html feedback and show in an html widget
  Widget buildFeedbackMessageRow() {
    return Row(children: <Widget>[
      Text(
        _experimentGroup.feedback.text,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ]);
  }
}
