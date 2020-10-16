import 'package:flutter/material.dart';

import '../service/experiment_service.dart';
import 'experiment_detail_page.dart';

class InvitationEntryPage extends StatefulWidget {
  static const routeName = 'invitation_entry';

  InvitationEntryPage({Key key}) : super(key: key);

  @override
  _InvitationEntryPageState createState() => _InvitationEntryPageState();
}

class _InvitationEntryPageState extends State<InvitationEntryPage> {
  static const _titleText = 'Invitation Code Entry';
  static const _preambleText =
      'If you were given an Invitation Code for an experiment, enter it below.';
  static const _promptText = 'Invitation Code';
  static const _submitText = 'Submit';

  String _invitationCodeInput;

  void _onTextInputChanged(String value) {
    _invitationCodeInput = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_titleText),
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
            buildInvitationCodeInputWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.send),
        label: const Text(_submitText),
        onPressed: () {
          _validateInvitationCode();
        },
      ),
    );
  }

  Widget buildPreambleTextWidget() => const Text(_preambleText);

  Widget buildInvitationCodeInputWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildInvitationCodePrompt(),
          buildInvitationCodeInput(),
        ],
      ),
    );
  }

  Widget buildInvitationCodePrompt() {
    return Text(
      _promptText,
      softWrap: true,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
    );
  }

  Widget buildInvitationCodeInput() {
    return TextField(
      onChanged: _onTextInputChanged,
      keyboardType: TextInputType.multiline,
      maxLength: 500,
      maxLines: null,
    );
  }

  void _validateInvitationCode() async {
    // Send code to server
    final service = await ExperimentService.getInstance();
    final response = await service.checkCode(_invitationCodeInput);

    if (!response.isSuccess) {
      _alertLog(response.statusMsg);
    } else {
      var experiment =
          await service.getPubExperimentFromServerById(response.experimentId);
      if (experiment != null) {
        experiment.participantId = response.participantId;
        experiment.anonymousPublic = true;
        Navigator.pushReplacementNamed(context, ExperimentDetailPage.routeName,
            arguments: experiment);
      } else {
        _alertLog(
            "Error fetching experiment with id: ${response.experimentId}, participant: ${response.participantId}");
      }
    }
  }

  Future<void> _alertLog(String msg) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(msg),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: const Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
