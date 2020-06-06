import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:taqo_email_plugin/taqo_email_plugin.dart' as taqo_email_plugin;

import 'package:taqo_common/model/experiment.dart';
import '../providers/experiment_provider.dart';
import '../widgets/taqo_page.dart';
import '../widgets/taqo_widgets.dart';
import 'schedule_overview_page.dart';
import 'survey_picker_page.dart';
import 'survey/survey_page.dart';

class RunningExperimentsPage extends StatefulWidget {
  static const routeName = 'running_experiments';
  final bool timeout;

  RunningExperimentsPage({this.timeout=false, Key key}) : super(key: key);

  @override
  _RunningExperimentsPageState createState() => _RunningExperimentsPageState();
}

class _RunningExperimentsPageState extends State<RunningExperimentsPage> {
  static const _timeoutMsg =
      "The survey for the notification selected has expired. "
      "Please respond sooner next time.";

  var _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // TODO Is there a better way?
    Future.delayed(Duration(milliseconds: 500), () {
      if (widget.timeout) {
        _showTimeout();
      }
    });
  }

  void _showTimeout() {
    _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(
            _timeoutMsg,
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          duration: Duration(seconds: 10),)
    );
  }

  @override
  Widget build(BuildContext context) {
    return TaqoScaffold(
        title: 'Running Experiments',
        body: Container(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              ChangeNotifierProvider<ExperimentProvider>(
                create: (_) => ExperimentProvider.withRunningExperiments(),
                child: ExperimentList(),
              ),
            ],
          ),
        ),
    );
  }

  // TODO Add to UI
  // Show progress indicator of some sort and remove once done
  void updateExperiments() async {
  }
}

class ExperimentList extends StatelessWidget {
  static const _joinMsg = "Join some Experiments to get started.";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExperimentProvider>(context);

    if (provider.experiments == null || provider.experiments.isEmpty) {
      return Center(
        child: const Text(_joinMsg),
      );
    }

    final listItems = <Widget>[];
    for (var e in provider.experiments) {
      listItems.add(ExperimentListItem(provider, e));
    }
    return ListView(children: listItems, shrinkWrap: true,);
  }
}

class ExperimentListItem extends StatefulWidget {
  final ExperimentProvider provider;
  final Experiment experiment;

  ExperimentListItem(this.provider, this.experiment);

  @override
  _ExperimentListItemState createState() => _ExperimentListItemState();
}

class _ExperimentListItemState extends State<ExperimentListItem> {
  bool _pauseButtonDisabled = false;

  void _onTapExperiment(BuildContext context, Experiment experiment) {
    if (experiment.getActiveSurveys().length == 1) {
      Navigator.pushNamed(context, SurveyPage.routeName,
          arguments: [
            experiment, experiment.getActiveSurveys().elementAt(0).name,
          ]
      );
    } else if (experiment.getActiveSurveys().length > 1) {
      Navigator.pushNamed(context, SurveyPickerPage.routeName,
          arguments: [experiment, ]);
    } else {
      // TODO no action for finished surveys
      _alertLog(context, "This experiment has finished.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return TaqoCard(
      child: Row(
        children: <Widget>[
          if (widget.experiment.active) Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.notifications_active, color: Colors.redAccent),
          ),

          Expanded(
              child: InkWell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(widget.experiment.title, textScaleFactor: 1.5),
                    if (widget.experiment.organization != null &&
                        widget.experiment.organization.isNotEmpty)
                      Text(widget.experiment.organization),
                    Text(widget.experiment.contactEmail != null
                        ? widget.experiment.contactEmail
                        : widget.experiment.creator),
                  ],
                ),
                onTap: () => _onTapExperiment(context, widget.experiment),
              )
          ),

          IconButton(
              icon: Icon(widget.experiment.paused ? Icons.play_arrow : Icons.pause),
              onPressed: _pauseButtonDisabled ? null : () async {
                setState(() => _pauseButtonDisabled = true);
                await widget.provider.setPausedAndNotifyListeners(widget.experiment, !widget.experiment.paused);
                setState(() => _pauseButtonDisabled = false);
              }
          ),
          IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => editExperiment(context, widget.experiment)
          ),
          IconButton(
              icon: Icon(Icons.email),
              onPressed: () => emailExperiment(context, widget.experiment)
          ),
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () => stopExperiment(context),
          ),
        ],
      ),
    );
  }

  void editExperiment(BuildContext context, Experiment experiment) {
    Navigator.pushNamed(
        context, ScheduleOverviewPage.routeName, arguments: ScheduleOverviewArguments(experiment));
  }

  Future<void> _alertLog(context, msg) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
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
              onPressed: () => Navigator.of(context).pop()
            ),
          ],
        );
      },
    );
  }

  Future<ConfirmAction> _confirmEmailDialog(BuildContext context, String to, String subject) async {
    return showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email the Experiment researcher?'),
          content: Text('If you have a question regarding this experiment, please contact $to with the subject "$subject"'),
          actions: <Widget>[
            FlatButton(
                child: const Text('Open my email'),
                onPressed: () => Navigator.of(context).pop(ConfirmAction.ACCEPT)
            ),
            FlatButton(
                child: const Text("I'll do it myself"),
                onPressed: () => Navigator.of(context).pop(ConfirmAction.CANCEL)
            ),
          ],
        );
      },
    );
  }

  void emailExperiment(BuildContext context, Experiment experiment) async {
    bool validateEmail(String email) {
      return RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(email);
    }

    var to = experiment.creator;
    final contactEmail = experiment.contactEmail;
    if (contactEmail != null && contactEmail.isNotEmpty && validateEmail(contactEmail)) {
      to = contactEmail;
    }

    final val = await _confirmEmailDialog(context, to, experiment.title);
    if (val == ConfirmAction.ACCEPT) {
      taqo_email_plugin.sendEmail(to, experiment.title);
    }
  }

  void stopExperiment(BuildContext context) {
    _confirmStopDialog(context).then((result) async {
      if (result == ConfirmAction.ACCEPT) {
        widget.provider.stopExperiment(widget.experiment);
      }
    });
  }

  Future<ConfirmAction> _confirmStopDialog(BuildContext context) async {
    return showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Stop Experiment'),
          content: const Text('Do you want to stop participating in this experiment?'),
          actions: <Widget>[
            FlatButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(ConfirmAction.CANCEL)
            ),
            FlatButton(
              child: const Text('Yes'),
              onPressed: () => Navigator.of(context).pop(ConfirmAction.ACCEPT)
            )
          ],
        );
      },
    );
  }
}

enum ConfirmAction { CANCEL, ACCEPT }

// This was on the old WelcomePage.
// Putting it here to reference the ExperimentService Provider usage.
//class RunningExperimentsList extends StatelessWidget {
//  final bool _authenticated;
//  RunningExperimentsList(this._authenticated);
//
//  @override
//  Widget build(BuildContext context) {
//    final service = Provider.of<ExperimentService>(context);
//    bool isRunningExperiments() {
//      return service != null && _authenticated && service.getJoinedExperiments().isNotEmpty;
//    }
//
//    return RaisedButton(
//      onPressed: isRunningExperiments() ?
//          () => Navigator.pushReplacementNamed(context, RunningExperimentsPage.routeName) : null,
//      child: const Text('Go to Joined Experiments'),
//    );
//  }
//}
