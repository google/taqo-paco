import 'package:flutter/material.dart';
import 'package:taqo_survey/model/event.dart';
import 'package:taqo_survey/model/input2.dart';
import 'package:taqo_survey/pages/survey/multi_list_output.dart';

class MultiSelectListDialog extends StatefulWidget {

  final MultiListOutput multiListOutput;

  var input;

  var event;

  @override
  _MultiSelectListDialogState createState() => new _MultiSelectListDialogState(multiListOutput, input, event);

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
              value: multiListOutput.answers[value] != null ? multiListOutput.answers[value] : false,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (newState) {
                setState(() {
                  multiListOutput.answers[value] = newState;
                  event.responses[input.name] = multiListOutput.stringifyAnswers();
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