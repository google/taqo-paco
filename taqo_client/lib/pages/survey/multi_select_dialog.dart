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

import 'package:taqo_common/model/input2.dart';
import 'multi_list_output.dart';

class MultiSelectListDialog extends StatefulWidget {
  final MultiListOutput multiListOutput;

  var input;

  var event;

  @override
  _MultiSelectListDialogState createState() =>
      _MultiSelectListDialogState(multiListOutput, input, event);

  MultiSelectListDialog({this.multiListOutput, this.input, this.event});
}

class _MultiSelectListDialogState extends State<MultiSelectListDialog> {
  MultiListOutput multiListOutput;
  Input2 input;

  var event;

  _MultiSelectListDialogState(this.multiListOutput, this.input, this.event);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Please select all applicable items'),
      content: SingleChildScrollView(
        child: Column(
          children: input.listChoices.map<Widget>((String value) {
            return CheckboxListTile(
              title: Text(value),
              value: multiListOutput.answers[value] != null
                  ? multiListOutput.answers[value]
                  : false,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (newState) {
                setState(() {
                  multiListOutput.answers[value] = newState;
                  event.responses[input.name] =
                      multiListOutput.stringifyAnswers();
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Done'),
          onPressed: () {
            Navigator.of(context).pop(multiListOutput.countSelected());
          },
        ),
      ],
    );
  }
}
