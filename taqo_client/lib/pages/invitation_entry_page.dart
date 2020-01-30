import 'package:flutter/material.dart';
import 'package:taqo_client/net/invitation_response.dart';
import 'package:taqo_client/service/experiment_service.dart';

import 'experiment_detail_page.dart';

class InvitationEntryPage extends StatefulWidget {
  static const routeName = '/invitation_entry';

  InvitationEntryPage({Key key}) : super(key: key);

  @override
  _InvitationEntryPageState createState() => _InvitationEntryPageState();
}


class _InvitationEntryPageState extends State<InvitationEntryPage> {
  var textEditController = TextEditingController();

  var _participantId;

  var _experimentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitation Code Entry'),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: ListView(
          padding: EdgeInsets.all(4.0),
          children: <Widget>[
            buildPreambleTextWidget(),
            Divider(
              height: 16.0,
              color: Colors.black,
            ),
            buildOpenTextQuestionWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          icon: Icon(Icons.send), label: Text('Submit'), onPressed: () {
            validateCode();
      }),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    textEditController.dispose();
    super.dispose();
  }

  Text buildPreambleTextWidget() {
    return Text(
      'If you were given an Invitation Code for an experiment, enter it below.',
    );
  }

  Widget buildOpenTextQuestionWidget() {
    var inputWidget = buildOpenTextField();

    final promptText = "Invitation Code";
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildQuestionWidget(String promptText, Widget inputWidget) {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[buildTextPrompt(promptText), inputWidget],
        ));
  }

  Text buildTextPrompt(String promptMessage) => Text(
    promptMessage,
    softWrap: true,
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
  );

  TextField buildOpenTextField() {
    return TextField(
        keyboardType: TextInputType.multiline, maxLength: 500, maxLines: null, controller: textEditController);
  }

  void validateCodeX() async {
    // send code to server
    var response = await sendCodetoServer(textEditController.text);
    // parse json result
    // if error show error message
    if (response.errorMessage != null) {
      _alertLog(response.errorMessage);
    } else {
      _alertLog(response.participantId.toString() + " " + response.experimentId.toString() + "\nNow fetching experiment.");
      _participantId = response.participantId;
      _experimentId = response.experimentId;
      final service = await ExperimentService.getInstance();
      var experiment = await service.getPubExperimentFromServerById(_experimentId);
      Navigator.pushReplacementNamed(context, ExperimentDetailPage.routeName, arguments: experiment);
    }
    // if success
    // parse participant ID and experiment ID.
    // store participant ID and experiment ID.
    // request experiment from server
    // if error show error message
    // else show ExperimentDetailPage
  }

  void validateCode() async {

      _participantId = 88;
      _experimentId = 5238446861320192;
      final service = await ExperimentService.getInstance();
      var experiment = await service.getPubExperimentFromServerById(
          _experimentId);
      if (service.isJoined(experiment)) {
        // TODO Show msg: "already joined" or disable button entirely
        return;
      }
      Navigator.pushNamed(
          context, ExperimentDetailPage.routeName, arguments: experiment);
    }

  Future<void> _alertLog(msg) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(msg),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<InvitationResponse> sendCodetoServer(String code) async {
    final service = await ExperimentService.getInstance();
    return service.checkCode(code);
  }

}
