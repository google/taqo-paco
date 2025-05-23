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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:taqo_common/model/experiment.dart';

import '../service/experiment_service.dart';
import 'experiment_detail_page.dart';

class LocalExperimentOpenPage extends StatefulWidget {
  static const routeName = 'local_experiment_open';

  LocalExperimentOpenPage({Key key}) : super(key: key);

  @override
  _LocalExperimentOpenPageState createState() => _LocalExperimentOpenPageState();
}

class _LocalExperimentOpenPageState extends State<LocalExperimentOpenPage> {
  static const _titleText = 'Choose local experiment json file';
  static const _preambleText =
      'If you were sent an experiment file, choose it now';
  static const _promptText = 'File path';
  static const _submitText = 'Submit';

  String _experimentJsonFilePathInput;

  void _onTextInputChanged(String value) {
    _experimentJsonFilePathInput = value;
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
            buildExperimentFilePathInputWidgets(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.send),
        label: const Text(_submitText),
        onPressed: () {
          _validateExperimentFilePath();
        },
      ),
    );
  }

  Widget buildPreambleTextWidget() => const Text(_preambleText);

  Widget buildExperimentFilePathInputWidgets() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildExperimentFilePathPrompt(),
          buildExperimentFilePathInput(),
        ],
      ),
    );
  }

  Widget buildExperimentFilePathPrompt() {
    return Text(
      _promptText,
      softWrap: true,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
    );
  }

  Widget buildExperimentFilePathInput() {
    return TextField(
      onChanged: _onTextInputChanged,
      keyboardType: TextInputType.multiline,
      maxLength: 500,
      maxLines: null,
    );
  }

  void _validateExperimentFilePath() async {
    // Send code to server
    final service = await ExperimentService.getInstance();
    var input = await File(_experimentJsonFilePathInput).readAsString();
    var file = jsonDecode(input);
    var experiment = Experiment.fromJson(file);
    experiment.anonymousPublic = true;

    if (experiment != null) {
      Navigator.pushReplacementNamed(context, ExperimentDetailPage.routeName,
          arguments: experiment);
    } else {
      _alertLog(
          "Error fetching experiment from file path: ${_experimentJsonFilePathInput}");
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
