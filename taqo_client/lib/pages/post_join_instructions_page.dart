import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:taqo_common/model/experiment.dart';
import 'running_experiments_page.dart';

class PostJoinInstructionsPage extends StatefulWidget {
  static const routeName = 'post_join_instructions';

  PostJoinInstructionsPage({Key key}) : super(key: key);

  @override
  _PostJoinInstructionsPageState createState() =>
      _PostJoinInstructionsPageState();
}

class _PostJoinInstructionsPageState extends State<PostJoinInstructionsPage> {
  @override
  Widget build(BuildContext context) {
    Experiment experiment = ModalRoute.of(context).settings.arguments;
    return Scaffold(
        appBar: AppBar(
          title: Text("${experiment.title} Instructions"),
          backgroundColor: Colors.indigo,
        ),
        body: Container(
          padding: EdgeInsets.all(8.0),
          child: Column(children: <Widget>[
            Expanded(
              child: _buildInstructionsColumn(experiment),
            ),
          ]),
        ),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.done),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context,
                RunningExperimentsPage.routeName, (Route route) => false)));
  }

  Widget _buildInstructionsColumn(Experiment experiment) {
    final data = experiment.postInstallInstructions != null
        ? experiment.postInstallInstructions
        : "No further instructions provided";

    return SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          Text("Post Join Instructions",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Divider(height: 16.0, color: Colors.black),
          Html(
            data: data,
          ),
        ]));
  }
}
