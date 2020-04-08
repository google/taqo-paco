import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../model/event.dart';
import '../../model/experiment.dart';
import '../../model/experiment_group.dart';
import '../../model/feedback.dart' as taqo_feedback;
import '../../model/input2.dart';
import '../../pages/survey/feedback_page.dart';
import '../../platform/platform_sync_service.dart';
import '../../service/alarm/flutter_local_notifications.dart' as flutter_local_notifications;
import '../../service/alarm/taqo_alarm.dart' as taqo_alarm;
import '../../storage/flutter_file_storage.dart';
import '../../storage/local_database.dart';
import '../../util/conditional_survey_parser.dart';
import '../../util/date_time_util.dart';
import '../../util/zoned_date_time.dart';
import '../../widgets/taqo_widgets.dart';
import '../running_experiments_page.dart';
import 'multi_list_output.dart';
import 'multi_select_dialog.dart';

class SurveyPage extends StatefulWidget {
  static const routeName = 'survey';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
      key: _scaffoldKey,
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
            submitSurvey();
          }),
    );
  }

  List<Widget> _evaluateInputConditions(List<Input2> inputs) {
    final env = Environment();
    inputs.forEach((input) {
      env[input.name] = Binding(input.name, input.responseType, _event.responses[input.name]);
    });

    final parser = InputParser(env);

    final children = <Widget>[];
    inputs.forEach((input) {
      if (input.conditional) {
        final id = input.name;
        final result = parser.getParseResult(input.conditionExpression);
        if (result) {
          children.add(buildWidgetForInput(input));
          _visible[id] = true;
        } else {
          env[id] = Binding(id, input.responseType, null);
          _visible[id] = false;
        }
      } else {
        children.add(buildWidgetForInput(input));
      }
    });

    return children;
  }

  ListView buildSurveyInputs(BuildContext context) {
    var preambleChildren = <Widget>[
      buildPreambleTextWidget(),
      Divider(
        height: 16.0,
        color: Colors.black,
      ),
    ];
    var inputChildren = _evaluateInputConditions(_experimentGroup.inputs);
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

  Widget buildMultiSelectListPopupDialog(
      BuildContext context, Input2 input) {
    var myPopupMultiListOutput = popupListResults[input.name];
    if (myPopupMultiListOutput == null) {
      myPopupMultiListOutput = new MultiListOutput(input.listChoices);
      popupListResults[input.name] = myPopupMultiListOutput;
    }

    var dialogButton = Text((myPopupMultiListOutput.countSelected() > 0)
        ? myPopupMultiListOutput.countSelected().toString() + " selected"
        : 'Please select');
    return TaqoRoundButton(
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
  }

  Widget buildScale(Input2 input) {
    Widget children = buildScaleRow(input.likertSteps, input);

    return Row(
      children: <Widget>[
        children,
      ],
    );
  }

  Widget buildScaleRow(int numberOfSteps, Input2 input) {
    final leftLabel = buildScaleLabelWidget(input.leftSideLabel);
    final rightLabel = buildScaleLabelWidget(input.rightSideLabel);

    final radioButtons = Iterable.generate(numberOfSteps, (i) =>
        buildRadio(i + 1, input)).toList();

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [leftLabel] + radioButtons + [rightLabel],
      ),
    );
  }

  Widget buildRadio(int i, input) {
    var groupValue = (_event.responses[input.name] != null)
        ? _event.responses[input.name] as int
        : -1;

    return Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Radio(
              value: i,
              groupValue: groupValue,
              onChanged: (int value) {
                setState(() {
                  _event.responses[input.name] = value;
                });
              })
        )
    );
  }

  Widget buildScaleLabelWidget(String labelText) {
    return Container(
        constraints: BoxConstraints(maxWidth: 64),
        child: Text(
          (labelText != null) ? labelText : "",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16.0),
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        )
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

  Future<void> submitSurvey() async {
    final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
    final pendingAlarms = await storage.getAllAlarms();

    for (var entry in pendingAlarms.entries) {
      final id = entry.key;
      final alarm = entry.value;
      if (alarm.experiment.id == _experiment.id &&
        alarm.experimentGroup.name == _experimentGroup.name &&
        alarm.time.isBefore(DateTime.now())) {
        // This alarm is the timeout for the notification
        // The alarm for the notification was already cleared when it fired
        _event.actionId = alarm.action.id;
        _event.actionTriggerId = alarm.actionTrigger.id;
        _event.actionTriggerSpecId = alarm.actionTriggerSpecId;
        _event.scheduleTime = getZonedDateTime(alarm.time);

        // Cancel timeout alarm
        // We cancel here both for self-report as well as coming from a notification
        taqo_alarm.cancel(id);
        final activeNotifications =
            await storage.getAllNotificationsForExperiment(_experiment);
        // Clear any pending notification
        for (var notification in activeNotifications) {
          if (notification.matchesAction(alarm)) {
            await taqo_alarm.cancel(notification.id);
          }
        }

        break;
      }
    }

    // Cancel existing (pending) notifications FOR THIS SURVEY only
    // The implication here is that the actual timeout/expiration time is
    // the min of the explicit timeout and the time until the next notification
    // for the same survey fires
    final pendingNotifications = (await storage
        .getAllNotificationsForExperiment(_experiment))
        .where((e) => e.experimentGroupName == _experimentGroup.name);

    final expired = pendingNotifications
        .where((e) => !e.isActive && !e.isFuture).toList();
    for (var pn in expired) {
      // Record Paco missed event for expired or stale
      await taqo_alarm.timeout(pn.id);
    }

    final active = pendingNotifications.where((e) => e.isActive).toList();
    for (var i = 0; i < active.length; i++) {
      final pn = active[i];
      if (i + 1 < active.length) {
        // If there are still multiple active notifications,
        // we record a Paco missed event for all but 1
        await taqo_alarm.timeout(pn.id);
      } else {
        // Just clean it up (no missed event)
        await taqo_alarm.cancel(pn.id);
      }
    }

    // Filter out conditional inputs that may no longer be valid
    // This can occur if the user answered a conditional input but later modified an answer
    // that nullifies the conditional input
    _event.responses.removeWhere((String k, _) => !(_visible[k] ?? true));
    _event.responseTime = ZonedDateTime.now();
    _event.responses[FORM_DURATION_IN_SECONDS] =
    _event.responseTime.dateTime.difference(_startTime).inSeconds;
    var savedOK = validateResponses();
    // TODO Validate answers and store locally.
    await storage.insertEvent(_event);
    notifySyncService();
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
    return TaqoRoundButton(
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
    return TaqoRoundButton(
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
    return TaqoRoundButton(
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
