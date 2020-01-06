import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:petitparser/petitparser.dart';
import 'package:taqo_client/model/event.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/experiment_group.dart';
import 'package:taqo_client/model/feedback.dart' as taqo_feedback;
import 'package:taqo_client/pages/survey/feedback_page.dart';
import 'package:taqo_client/storage/local_database.dart';
import 'package:taqo_client/util/conditional_survey_parser.dart';
import 'package:taqo_client/util/zoned_date_time.dart';

import '../running_experiments_page.dart';
import 'multi_list_output.dart';
import 'multi_select_dialog.dart';
import 'package:taqo_client/model/input2.dart';

import 'package:numberpicker/numberpicker.dart';

class SurveyPage extends StatefulWidget {
  static const routeName = '/survey';

  SurveyPage(
      {Key key,
      this.title,
      @required this.experiment,
      @required this.experimentGroupName})
      : super(key: key);

  final String title;
  final Experiment experiment;
  final String experimentGroupName;

  @override
  _SurveyPageState createState() =>
      _SurveyPageState(experiment, experimentGroupName);
}

class _SurveyPageState extends State<SurveyPage> {
  static const String FORM_DURATION_IN_SECONDS = "Form Duration";
  Experiment _experiment;
  ExperimentGroup _experimentGroup;
  Event _event;
  DateTime _startTime;
  final _visible = <String, bool>{};

  var popupListResults = {};

  _SurveyPageState(this._experiment, String experimentGroupName) {
    _experimentGroup = _experiment.getGroupNamed(experimentGroupName);
    _event = Event.of(_experiment, _experimentGroup);
    _startTime = DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _experimentGroup.inputs.forEach((input) {
      _visible[input.name] = !input.conditional;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Survey: " + _experimentGroup.name),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        //margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),

        // TODO wrap each survey input in such a way that we can do error marking and
        // state management when it is time to save the responses
        child: buildSurveyInputs(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
          icon: Icon(Icons.send),
          label: Text('Submit'),
          onPressed: () {
            saveEvent();
          }),
    );
  }

  bool _evaluateInputCondition(Input2 input) {
    bool match = true;
    if (input.conditional) {
      match = false;
      final responses = Map<String, dynamic>.fromIterable(_experimentGroup.inputs,
          key: (i) => i.name,
          value: (i) => (_visible[i.name] ?? false) ? _event.responses[i.name] : null);
      try {
         final result = InputParser(responses).parse(input.conditionExpression);
         if (result is Failure) {
           print('failure parsing ${input.name}: ${result.message}');
         } else {
           match = result.value as bool;
           _visible[input.name] = match;
         }
      } catch(e) {
        print('unknown error parsing ${input.name}: $e');
      }
    }
    return match;
  }

  ListView buildSurveyInputs(BuildContext context) {
    var preambleChildren = <Widget>[
      buildPreambleTextWidget(),
      Divider(
        height: 16.0,
        color: Colors.black,
      ),
    ];
    var inputChildren = <Widget>[];
    _experimentGroup.inputs.forEach((input) {
      if (_evaluateInputCondition(input)) {
        var buildWidgetForInput2 = buildWidgetForInput(input);
        inputChildren.add(buildWidgetForInput2);
      }
    });

    var allChildren = preambleChildren + inputChildren + fabBufferSpace();
    return ListView(
      padding: EdgeInsets.all(4.0),
      children: allChildren,
    );
  }

  Widget buildWidgetForInput(Input2 input) {
    if (input.responseType == Input2.OPEN_TEXT) {
      return buildOpenTextQuestionWidget(input);
    } else if (input.responseType == Input2.LIKERT) {
      return buildScaleQuestionWidget(input);
    } else if (input.responseType == Input2.LIST && !input.multiselect) {
      return buildSingleSelectListQuestionWidget(input);
    } else if (input.responseType == Input2.LIST && input.multiselect) {
      return buildMultiSelectListPopupQuestionWidget(context, input);
    } else if (input.responseType == Input2.LOCATION) {
      return buildLocationQuestionWidget(context, input);
    } else if (input.responseType == Input2.PHOTO) {
      return buildPhotoQuestionWidget(context, input);
    } else if (input.responseType == Input2.AUDIO) {
      return buildAudioQuestionWidget(context, input);
    } else if (input.responseType == Input2.NUMBER) {
      return buildNumberQuestionWidget(context, input);
    } else if (input.responseType == Input2.LIKERT_SMILEYS) {
      return buildSmileyScaleQuestionWidget(context, input);
    } else {
      return Text("Can't render a " + input.responseType);
    }
  }

  Text buildPreambleTextWidget() {
    return Text(
      'Please answer each question to the best of your ability then press Save',
    );
  }

  Widget buildOpenTextQuestionWidget(Input2 input) {
    var inputWidget = buildOpenTextField(input);
    final promptText = input.text;
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildScaleQuestionWidget(Input2 input) {
    var inputWidget = buildScale(input);
    var promptText = input.text;
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildSingleSelectListQuestionWidget(Input2 input) {
    var promptText = input.text;
    var inputWidget = buildSingleSelectList(input);
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildMultiSelectListPopupQuestionWidget(
      BuildContext context, Input2 input) {
    var promptText = input.text;
    var inputWidget = buildMultiSelectListPopupDialog(context, input);
    return buildQuestionWidget(promptText, inputWidget);
  }

//  Widget buildMultiSelectListInlineQuestionWidget(BuildContext context, Input2 input) {
//    var promptText = input.text;
//    var inputWidget = buildMultiSelectListInline(context, input);
//    return buildQuestionWidget(promptText, inputWidget);
//  }

  Widget buildQuestionWidget(String promptText, Widget inputWidget) {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[buildTextPrompt(promptText), inputWidget],
        ));
  }

  Text buildTextPrompt(String promptMessage) => Text(
        promptMessage ?? "",
        softWrap: true,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
      );

  TextField buildOpenTextField(Input2 input) {
    return TextField(
      keyboardType: TextInputType.multiline,
      maxLength: 500,
      maxLines: null,
      onChanged: (text) {
        _event.responses[input.name] = text;
      },
    );
  }

  DropdownButton buildSingleSelectList(Input2 input) {
    return DropdownButton<String>(
      hint: Text('Please select'),
      isExpanded: true,
      value: (_event.responses[input.name] != null)
          ? _event.responses[input.name]
          : null,
      items: input.listChoices.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, softWrap: true),
        );
      }).toList(),
      onChanged: (String newValue) {
        setState(() {
          _event.responses[input.name] = newValue;
        });
      },
    );
  }

//  Column buildMultiSelectListInline(BuildContext context, Input2 input) {
//    return Column(
//      children: input.listChoices.map<Widget>((String value) {
//        return CheckboxListTile(
//          title: Text(value),
//          value: inlineMultiListOutput.answers[value],
//          controlAffinity: ListTileControlAffinity.leading,
//          onChanged: (newState) {
//            setState(() {
//              inlineMultiListOutput.answers[value] = newState;
//            });
//          },
//        );
//      }).toList(),
//    );
//  }

  RaisedButton buildMultiSelectListPopupDialog(
      BuildContext context, Input2 input) {
    var myPopupMultiListOutput = popupListResults[input.name];
    if (myPopupMultiListOutput == null) {
      myPopupMultiListOutput = new MultiListOutput(input.listChoices);
      popupListResults[input.name] = myPopupMultiListOutput;
    }

    var dialogButton = Text((myPopupMultiListOutput.countSelected() > 0)
        ? myPopupMultiListOutput.countSelected().toString() + " selected"
        : 'Please select');
    var raisedButton = RaisedButton(
      onPressed: () {
        var result = showDialog(
            context: context,
            builder: (_) {
              return MultiSelectListDialog(
                multiListOutput: myPopupMultiListOutput,
                input: input,
                event: _event,
              );
            });
        result.then((countSelected) {
          //child.Text(countSelected +" selected");
          setState(() {
            //_stateThatAllowsForcingARedraw++;
          });
        });
      },
      child: dialogButton,
    );
    return raisedButton;
  }

  Widget buildScale(Input2 input) {
    var leftLabel = buildScaleLabelWidget(input.leftSideLabel);
    var rightLabel = buildScaleLabelWidget(input.rightSideLabel);

    List<Widget> buttonChildren = buildRadioButtons(input.likertSteps, input);

    var allChildren = <Widget>[leftLabel] + buttonChildren + [rightLabel];

    return Padding(
        padding: EdgeInsets.all(0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: allChildren,
        ));
  }

  List<Widget> buildRadioButtons(int numberOfSteps, Input2 input) {
    return Iterable.generate(numberOfSteps, (i) => buildRadio(i + 1, input))
        .toList();
  }

  Widget buildRadio(int i, input) {
    var groupValue = (_event.responses[input.name] != null)
        ? _event.responses[input.name] as int
        : -1;

    return Expanded(
        child: Radio(
            value: i,
            groupValue: groupValue,
            onChanged: (int value) {
              setState(() {
                _event.responses[input.name] = value;
              });
            }));
  }

  Text buildScaleLabelWidget(String labelText) {
    return Text(
      (labelText != null) ? labelText : "",
      style: new TextStyle(fontSize: 16.0),
    );
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

  Future<void> saveEvent() async {
    // Filter out conditional inputs that may no longer be valid
    // This can occur if the user answered a conditional input but later modified an answer
    // that nullifies the conditional input
    _experimentGroup.inputs.forEach((input) {
      if (_event.responses.containsKey(input.name) && !_visible[input.name]) {
        _event.responses.remove(input.name);
      }
    });

    _event.responseTime = ZonedDateTime.now();
    _event.responses[FORM_DURATION_IN_SECONDS] =
    _event.responseTime.dateTime.difference(_startTime).inSeconds;
    await _alertLog("Saving Responses: " + jsonEncode(_event.toJson()));
    var savedOK = validateResponses();
    // TODO Validate answers and store locally.
    var db = LocalDatabase();
    await db.insertEvent(_event);
    // If should be uploaded alert sync service
    if (savedOK) {
      if (_experimentGroup.feedback.type == taqo_feedback.Feedback.FEEDBACK_TYPE_STATIC_MESSAGE) {
        Navigator.pushNamedAndRemoveUntil(
            context, FeedbackPage.routeName,
            ModalRoute.withName(RunningExperimentsPage.routeName),
            arguments: [_experiment, _experimentGroup]);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, RunningExperimentsPage.routeName, (Route route) => false);
      }
    }
  }

  Widget buildLocationQuestionWidget(BuildContext context, Input2 input) {
    var inputWidget = buildLocationButton(input);
    final promptText = input.text;
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildLocationButton(Input2 input) {
    return RaisedButton(
      child: Text("Get location"),
      onPressed: () {
        _alertLog("Not yet implemented");
      },
    );
  }

  Widget buildPhotoQuestionWidget(BuildContext context, Input2 input) {
    var inputWidget = buildPhotoButton(input);
    final promptText = input.text;
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildPhotoButton(Input2 input) {
    return RaisedButton(
      child: Text("Get Photo"),
      onPressed: () {
        _alertLog("Not yet implemented");
      },
    );
  }

  Widget buildAudioQuestionWidget(BuildContext context, Input2 input) {
    var inputWidget = buildAudioButton(input);
    final promptText = input.text;
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildAudioButton(Input2 input) {
    return RaisedButton(
      child: Text("Get Audio"),
      onPressed: () {
        _alertLog("Not yet implemented");
      },
    );
  }

  Widget buildNumberQuestionWidget(BuildContext context, Input2 input) {
    var inputWidget = buildNumberInput(input);
    final promptText = input.text;
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildNumberInput(Input2 input) {
//    return TextField(keyboardType: TextInputType.multiline, maxLength: 500, maxLines: null,
//      onChanged: (text) {
//        _event.responses[input.name] = text;
//      },);
    return buildInlineNumberPicker(input);
  }

  Container buildInlineNumberPicker(Input2 input) {
    return Container(
      child: NumberPicker.integer(
        initialValue: _event.responses[input.name] != null
            ? _event.responses[input.name]
            : 0,
        minValue: 0,
        maxValue: 32000000000,
        step: 1,
        onChanged: (value) =>
            setState(() => _event.responses[input.name] = value),
      ),
    );
  }

  Widget buildSmileyScaleQuestionWidget(BuildContext context, Input2 input) {
    var inputWidget = buildSmileyScale(input);
    var promptText = input.text;
    return buildQuestionWidget(promptText, inputWidget);
  }

  Widget buildSmileyScale(Input2 input) {
    List<Widget> buttonChildren = buildSmileyButtons(input);

    return
        //Padding(padding: EdgeInsets.all(5), child:
        Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttonChildren,
    )
        //)
        ;
  }

  List<Widget> buildSmileyButtons(Input2 input) {
    Widget getIconWidget(AssetImage asset, Color color, int value) {
      final blendMode = _event.responses[input.name] == value ? BlendMode.multiply : BlendMode.dst;
      return IconButton(
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image(image: asset, color: color, colorBlendMode: blendMode,),
        ),
        iconSize: 40,
        onPressed: () => setState(() => _event.responses[input.name] = value),
      );
    }

    return <Widget>[
      getIconWidget(AssetImage("assets/smile_icon1.png"), Colors.red, 1),
      getIconWidget(AssetImage("assets/smile_icon2.png"), Colors.orange, 2),
      getIconWidget(AssetImage("assets/smile_icon3.png"), Colors.yellow, 3),
      getIconWidget(AssetImage("assets/smile_icon4.png"), Colors.lightGreen, 4),
      getIconWidget(AssetImage("assets/smile_icon5.png"), Colors.green, 5),
    ];
  }

  List<Widget> fabBufferSpace() {
    return [
      Column(children: <Widget>[Text("\n\n")])
    ];
  }

  bool validateResponses() {
    // TODO check that all required inputs have answers

    return true;
  }
}
