import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:taqo_survey/pages/experiment_detail_page.dart';
import 'package:taqo_survey/pages/find_experiments_page.dart';
import 'package:taqo_survey/pages/informed_consent_page.dart';
import 'package:taqo_survey/pages/post_join_instructions_page.dart';
import 'package:taqo_survey/pages/running_experiments_page.dart';
import 'package:taqo_survey/pages/schedule_overview_page.dart';
import 'package:taqo_survey/pages/survey/feedback_page.dart';

import 'package:taqo_survey/pages/survey/survey_page.dart';
import 'package:taqo_survey/pages/survey_picker_page.dart';
import 'package:taqo_survey/pages/welcome_page.dart';
import 'package:taqo_survey/pages/invitation_entry_page.dart';
import 'package:taqo_survey/pages/login_page.dart';

import 'package:taqo_survey/net/google_auth.dart';
import 'package:taqo_survey/storage/user_preferences.dart';

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

