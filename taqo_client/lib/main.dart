import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:taqo_time_plugin/taqo_time_plugin.dart' as taqo_time_plugin;

import 'net/google_auth.dart';
import 'pages/experiment_detail_page.dart';
import 'pages/find_experiments_page.dart';
import 'pages/informed_consent_page.dart';
import 'pages/invitation_entry_page.dart';
import 'pages/login_page.dart';
import 'pages/post_join_instructions_page.dart';
import 'pages/running_experiments_page.dart';
import 'pages/schedule_detail_page.dart';
import 'pages/schedule_overview_page.dart';
import 'pages/survey/feedback_page.dart';
import 'pages/survey/survey_page.dart';
import 'pages/survey_picker_page.dart';
import 'pages/welcome_page.dart';
import 'platform/platform_logging.dart';
import 'platform/platform_sync_service.dart';
import 'service/alarm/taqo_alarm.dart' as taqo_alarm;
import 'service/logging_service.dart';
import 'storage/esm_signal_storage.dart';

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

class MyApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taqo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/welcome',
      navigatorKey: navigatorKey,
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
                    experiment: args[0], experimentGroupName: args[1]));
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
