import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:taqo_client/pages/experiment_detail_page.dart';
import 'package:taqo_client/pages/find_experiments_page.dart';
import 'package:taqo_client/pages/informed_consent_page.dart';
import 'package:taqo_client/pages/post_join_instructions_page.dart';
import 'package:taqo_client/pages/running_experiments_page.dart';
import 'package:taqo_client/pages/schedule_overview_page.dart';
import 'package:taqo_client/pages/survey/feedback_page.dart';

import 'package:taqo_client/pages/survey/survey_page.dart';
import 'package:taqo_client/pages/survey_picker_page.dart';
import 'package:taqo_client/pages/welcome_page.dart';
import 'package:taqo_client/pages/invitation_entry_page.dart';
import 'package:taqo_client/pages/login_page.dart';

import 'package:taqo_client/net/google_auth.dart';
import 'package:taqo_client/storage/user_preferences.dart';

var gAuth = GoogleAuth();

void main() {
  // Desktop platforms are not recognized as valid targets by
  // Flutter; force a specific target to prevent exceptions.
  // TODO this shoudl change as we adopt the new Flutter Desktop Embedder
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  UserPreferences _userPreferences = UserPreferences();



  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Taqo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        LoginPage.routeName: (context) => LoginPage(),
        SurveyPage.routeName: (context) => SurveyPage(),
        FeedbackPage.routeName: (context) => FeedbackPage(),
        SurveyPickerPage.routeName: (context) => SurveyPickerPage(),
        FindExperimentsPage.routeName: (context) => FindExperimentsPage(),
        ExperimentDetailPage.routeName: (context) => ExperimentDetailPage(),
        InformedConsentPage.routeName: (context) => InformedConsentPage(),
        ScheduleOverviewPage.routeName: (context) => ScheduleOverviewPage(),
        InvitationEntryPage.routeName: (context) => InvitationEntryPage(),
        WelcomePage.routeName: (context) => WelcomePage(),
        RunningExperimentsPage.routeName: (context) => RunningExperimentsPage(),
        PostJoinInstructionsPage.routeName: (context) => PostJoinInstructionsPage(),
      },
    );
  }

}

