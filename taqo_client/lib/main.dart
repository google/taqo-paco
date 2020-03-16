import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:taqo_client/pages/experiment_detail_page.dart';
import 'package:taqo_client/pages/find_experiments_page.dart';
import 'package:taqo_client/pages/informed_consent_page.dart';
import 'package:taqo_client/pages/post_join_instructions_page.dart';
import 'package:taqo_client/pages/running_experiments_page.dart';
import 'package:taqo_client/pages/schedule_detail_page.dart';
import 'package:taqo_client/pages/schedule_overview_page.dart';
import 'package:taqo_client/pages/survey/feedback_page.dart';

import 'package:taqo_client/pages/survey/survey_page.dart';
import 'package:taqo_client/pages/survey_picker_page.dart';
import 'package:taqo_client/pages/welcome_page.dart';
import 'package:taqo_client/pages/invitation_entry_page.dart';
import 'package:taqo_client/pages/login_page.dart';
import 'package:taqo_client/platform/platform_logging.dart';
import 'package:taqo_client/platform/platform_sync_service.dart';
import 'package:taqo_client/service/experiment_service.dart';
import 'package:taqo_client/service/logging_service.dart';

import 'package:taqo_client/net/google_auth.dart';
import 'package:taqo_client/storage/esm_signal_storage.dart';
import 'package:taqo_client/storage/local_database.dart';

import 'package:taqo_time_plugin/taqo_time_plugin.dart' as taqo_time_plugin;

import 'service/alarm/taqo_alarm.dart' as taqo_alarm;

var gAuth = GoogleAuth();

void _onTimeChange() async {
  /// TODO Currently provides no info on how the time was changed
  print('time [zone] changed, rescheduling');
  await ESMSignalStorage().deleteAllSignals();
  taqo_alarm.schedule();
}

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  WidgetsFlutterBinding.ensureInitialized();
  setupLoggingMethodChannel();
  setupSyncServiceMethodChannel();
  notifySyncService();
  taqo_time_plugin.initialize(_onTimeChange);

  // LoggingService.init() and taqo_alarm.init() should be called once and only once
  // Calling them here ensures that they complete before the app launches
  LoggingService.init().then((_) {
    taqo_alarm.init().then((_) {
      runApp(MyApp());
    });
  });
}

class MyApp extends StatefulWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // If there is an active notification when the app is open,
  // direct the user to the survey.
  // This also solves the issue with not having Pending (launch) Intents on Linux
  void _checkActiveNotification() async {
    final activeNotifications = (await LocalDatabase().getAllNotifications())
        .where((n) => n.isActive).toList(growable: false);

    if (activeNotifications.isNotEmpty) {
      final n = activeNotifications.first;
      try {
        final service = await ExperimentService.getInstance();
        final e = service
            .getJoinedExperiments()
            .firstWhere((e) => e.id == n.experimentId);
        e.groups.firstWhere((g) => g.name == n.experimentGroupName);
        MyApp.navigatorKey.currentState.pushReplacementNamed(SurveyPage.routeName,
            arguments: [e, n.experimentGroupName, true]);
      } on StateError catch (e, stack) {
        print('StateError: $e');
        print(stack);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkActiveNotification();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taqo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/welcome',
      navigatorKey: MyApp.navigatorKey,
      routes: {
        LoginPage.routeName: (context) => LoginPage(),
        FeedbackPage.routeName: (context) => FeedbackPage(),
        SurveyPickerPage.routeName: (context) => SurveyPickerPage(),
        FindExperimentsPage.routeName: (context) => FindExperimentsPage(),
        ExperimentDetailPage.routeName: (context) => ExperimentDetailPage(),
        InformedConsentPage.routeName: (context) => InformedConsentPage(),
        ScheduleOverviewPage.routeName: (context) => ScheduleOverviewPage(),
        ScheduleDetailPage.routeName: (context) => ScheduleDetailPage(),
        InvitationEntryPage.routeName: (context) => InvitationEntryPage(),
        WelcomePage.routeName: (context) => WelcomePage(),
        PostJoinInstructionsPage.routeName: (context) => PostJoinInstructionsPage(),
      },
      // Here the route for SurveyPage is configured separately in onGenerateRoute(),
      // since we need to pass argument to this route before the page being built,
      // which is not supported by ModalRoute.of().
      onGenerateRoute: (settings) {
        final List args = settings.arguments;
        switch (settings.name) {
          case SurveyPage.routeName:
            return MaterialPageRoute(
                builder: (context) => SurveyPage(
                    experiment: args[0], experimentGroupName: args[1],
                    fromLaunch: args.length > 2 ? args[2] : false));
          case RunningExperimentsPage.routeName:
            return MaterialPageRoute(
                builder: (context) => RunningExperimentsPage(
                    timeout: args == null ? false : args.length > 0 ? args[0] : false));
        }
        return null;
      },
    );
  }
}
