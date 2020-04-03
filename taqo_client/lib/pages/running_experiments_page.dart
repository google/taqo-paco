import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:taqo_email_plugin/taqo_email_plugin.dart' as taqo_email_plugin;

import '../model/experiment.dart';
import '../net/google_auth.dart';
import '../service/experiment_service.dart';
import '../storage/local_database.dart';
import '../widgets/taqo_page.dart';
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
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _timeoutMsg =
      "The survey for the notification selected has expired. "
      "Please respond sooner next time.";

  var gAuth = GoogleAuth();

  var _experiments = <Experiment>[];

  final _active = <int>{};

  @override
  void initState() {
    super.initState();
    ExperimentService.getInstance().then((service) {
      setState(() {
        _experiments = service.getJoinedExperiments();
      });
      LocalDatabase().getAllNotifications().then((all) {
        final active = all.where((n) => n.isActive);
        setState(() {
          _active.clear();
          _active.addAll(active.map((e) => e.experimentId));
        });
      });
    });

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
    // TODO Add refresh?
    return TaqoScaffold(
        title: 'Running Experiments',
        body: Container(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Divider(
                height: 16.0,
                color: Colors.black,
              ),
              _buildExperimentList(),
            ],
          ),
        ),
    );
  }

  Widget _buildExperimentList() {
    final children = <Widget>[];
    for (var experiment in _experiments) {
      children.add(ChangeNotifierProvider<Experiment>.value(
        value: experiment,
        child: ExperimentListItem(_active.contains(experiment.id), stopExperiment),
      ));
    }
    return ListView(
      children: children,
      shrinkWrap: true,
    );
  }

  void updateExperiments() async {
    // TODO show progress indicator of some sort and remove once done
    final service = await ExperimentService.getInstance();
    service.updateJoinedExperiments().then((List<Experiment> experiments) {
      setState(() {
        _experiments = experiments;
      });
    });
  }

  void stopExperiment(Experiment experiment) {
    _confirmStopDialog(context).then((result) async {
      if (result == ConfirmAction.ACCEPT) {
        final service = await ExperimentService.getInstance();
        service.stopExperiment(experiment);
        setState(() {
          _experiments = service.getJoinedExperiments();
        });
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

class ExperimentListItem extends StatelessWidget {
  final bool _active;
  final stop;
  ExperimentListItem(this._active, this.stop);

  void _onTapExperiment(BuildContext context, Experiment experiment) {
    if (experiment.getActiveSurveys().length < 1) {
      Navigator.pushNamed(context, SurveyPage.routeName,
          arguments: [
            experiment, experiment.getActiveSurveys().elementAt(0).name,
          ]
      );
    } else if (experiment.getActiveSurveys().length >= 1) {
      Navigator.pushNamed(context, SurveyPickerPage.routeName,
          arguments: [experiment, ]);
    } else {
      // TODO no action for finished surveys
      _alertLog(context, "This experiment has finished.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Experiment>(
        builder: (BuildContext context, Experiment experiment, _) {
          return Card(
            child: Row(
              children: <Widget>[
                if (_active) Padding(padding: EdgeInsets.all(4),
                  child: Icon(Icons.notifications_active, color: Colors.redAccent,),),

                Expanded(
                    child: InkWell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(experiment.title, textScaleFactor: 1.5),
                          if (experiment.organization != null &&
                              experiment.organization.isNotEmpty)
                            Text(experiment.organization),
                          Text(experiment.contactEmail != null
                              ? experiment.contactEmail
                              : experiment.creator),
                        ],
                      ),
                      onTap: () => _onTapExperiment(context, experiment),
                    )
                ),

                IconButton(
                    icon: Icon(experiment.paused ? Icons.play_arrow : Icons.pause),
                    onPressed: () => experiment.paused = !experiment.paused
                ),
                IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => editExperiment(context, experiment)
                ),
                IconButton(
                    icon: Icon(Icons.email),
                    onPressed: () => emailExperiment(experiment)
                ),
                IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => stop(experiment)
                ),
              ],
            ),
          );
        }
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

  void emailExperiment(Experiment experiment) {
    bool validateEmail(String email) {
      return RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(email);
    }
    var to = experiment.creator;
    final contactEmail = experiment.contactEmail;
    if (contactEmail != null && contactEmail.isNotEmpty && validateEmail(contactEmail)) {
      to = contactEmail;
    }
    taqo_email_plugin.sendEmail(to, experiment.title);
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
