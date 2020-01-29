import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/net/google_auth.dart';
import 'package:taqo_client/pages/find_experiments_page.dart';
import 'package:taqo_client/pages/schedule_overview_page.dart';
import 'package:taqo_client/pages/survey/survey_page.dart';
import 'package:taqo_client/pages/survey_picker_page.dart';
import 'package:taqo_client/platform/platform_email.dart';
import 'package:taqo_client/service/experiment_service.dart';

class RunningExperimentsPage extends StatefulWidget {
  static const routeName = '/running_experiments';

  RunningExperimentsPage({Key key}) : super(key: key);

  @override
  _RunningExperimentsPageState createState() => _RunningExperimentsPageState();
}

class _RunningExperimentsPageState extends State<RunningExperimentsPage> {
  var gAuth = GoogleAuth();

  final _experimentRetriever = ExperimentService();
  var _experiments = <Experiment>[];

  @override
  void initState() {
    super.initState();
    _experiments = _experimentRetriever.getJoinedExperiments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Running Experiments'),
        backgroundColor: Colors.indigo,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            tooltip: 'Find Experiments to Join',
            onPressed: () => Navigator.pushNamed(context, FindExperimentsPage.routeName)
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Update Experiments',
            onPressed: updateExperiments,
          )
        ],
      ),
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
        child: ExperimentListItem(stopExperiment),
      ));
    }
    return ListView(
      children: children,
      shrinkWrap: true,
    );
  }

  void updateExperiments() {
    // TODO show progress indicator of some sort and remove once done
    _experimentRetriever.updateJoinedExperiments().then((List<Experiment> experiments) {
      setState(() {
        _experiments = experiments;
      });
    });
  }

  void stopExperiment(Experiment experiment) {
    _confirmStopDialog(context).then((result) {
      if (result == ConfirmAction.ACCEPT) {
        _experimentRetriever.stopExperiment(experiment);
        setState(() {
          _experiments = _experimentRetriever.getJoinedExperiments();
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
  final stop;
  ExperimentListItem(this.stop);

  void _onTapExperiment(BuildContext context, Experiment experiment) {
    if (experiment.getActiveSurveys().length == 1) {
      Navigator.pushNamed(context, SurveyPage.routeName,
          arguments: [
            experiment, experiment.getActiveSurveys().elementAt(0).name, DateTime.now(),
          ]
      );
    } else if (experiment.getActiveSurveys().length > 1) {
      Navigator.pushNamed(context, SurveyPickerPage.routeName,
          arguments: [experiment, DateTime.now(), ]);
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
    sendEmail(to, experiment.title);
  }
}

enum ConfirmAction { CANCEL, ACCEPT }
