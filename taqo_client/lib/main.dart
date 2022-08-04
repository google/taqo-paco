// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:taqo_common/net/google_auth.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/service/logging_service.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_common/storage/esm_signal_storage.dart';
import 'package:taqo_common/storage/local_file_storage.dart';
import 'package:taqo_time_plugin/taqo_time_plugin.dart' as taqo_time_plugin;

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
import 'platform/platform_logging.dart';
import 'platform/platform_sync_service.dart';
import 'service/alarm/taqo_alarm.dart' as taqo_alarm;
import 'service/experiment_service.dart';
import 'service/platform_service.dart';
import 'storage/flutter_file_storage.dart';

final _logger = Logger('Main');

void _onTimeChange() async {
  /// TODO Currently provides no info on how the time was changed
  _logger.info('time [zone] changed, rescheduling');
  final storage =
      await ESMSignalStorage.get(FlutterFileStorage(ESMSignalStorage.filename));
  storage.deleteAllSignals();
  taqo_alarm.schedule();
}

void main() async {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  WidgetsFlutterBinding.ensureInitialized();

  // On macOS only (for now), check if taqo_daemon is running.
  // If not, start it using native plugin channel
  if (Platform.isMacOS) {
    final tespConnected = await isTespConnected();
    if (!tespConnected) {
      final channel = MethodChannel("com.taqo.survey");
      await channel.invokeMethod("startTespServer");
    }
  }

  LocalFileStorageFactory.initialize((fileName) => FlutterFileStorage(fileName),
      await FlutterFileStorage.getLocalStorageDir());
  await LoggingService.initialize(
      logFilePrefix: 'client-', outputsToStdout: kDebugMode);
  DatabaseFactory.initialize(() => databaseImpl);
  ExperimentServiceLiteFactory.initialize(ExperimentService.getInstance);
  setupLoggingMethodChannel();

  if (!isTaqoDesktop) {
    setupSyncServiceMethodChannel();
    notifySyncService();
  }

  if (!Platform.isLinux) {
    taqo_time_plugin.initialize(_onTimeChange);
  }
  await taqo_alarm.init();

  // If there is an active notification when the app is open,
  // direct the user to the RunningExperimentsPage.
  // This also solves the issue with not having Pending (launch) Intents on Linux
  final activeNotification = await taqo_alarm.checkActiveNotification();
  final authState = await GoogleAuth().isAuthenticated;

  // Add licenses manually for Taqo and Alerter. This help to add the licenses
  // those are not automatically fetched and added by showLicensePage method.
  await loadManualLicenses();

  runApp(MyApp(activeNotification: activeNotification, authState: authState));
}

/// Loads the manually listed licenses and adds those to the license registry.
Future<void> loadManualLicenses() async {
  // Add entries to the list below to load particular licenses manually. Make
  // sure that the paths for the listed licenses are specified in the assets
  // section of pubspec.yaml
  final manualLicenses = [
    ['taqo', 'assets/LICENSE'],
    ['alerter', 'assets/alerter_LICENSE']
  ];

  // Iterate through each of the licenses provided in the "licenses" list and
  // then generate the LicenseEntry object.
  final licenseEntries = <LicenseEntry>[
    for (final licenseInfo in manualLicenses)
      await generateLicenseEntry(licenseInfo[0], licenseInfo[1])
  ];

  // Add license all at once from the stream.
  LicenseRegistry.addLicense(() {
    return Stream.fromIterable(licenseEntries);
  });
}

/// Generates a LicenseEntry object given the package name [packageName], and
/// the path to the package's license file [licensePath].
Future<LicenseEntry> generateLicenseEntry(
    String packageName, String licensePath) async {
  final licenseText = await rootBundle.loadString(licensePath);
  return LicenseEntryWithLineBreaks([packageName], licenseText);
}

class MyApp extends StatefulWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();

  bool activeNotification;
  bool authState;

  MyApp({this.activeNotification, this.authState});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _initialRoute = LoginPage.routeName;

  @override
  void initState() {
    super.initState();

    if (widget.authState) {
      _initialRoute = RunningExperimentsPage.routeName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taqo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: _initialRoute,
      navigatorKey: MyApp.navigatorKey,
      routes: {
        LoginPage.routeName: (context) => LoginPage(),
        FeedbackPage.routeName: (context) => FeedbackPage(),
        FindExperimentsPage.routeName: (context) => FindExperimentsPage(),
        ExperimentDetailPage.routeName: (context) => ExperimentDetailPage(),
        InformedConsentPage.routeName: (context) => InformedConsentPage(),
        ScheduleOverviewPage.routeName: (context) => ScheduleOverviewPage(),
        ScheduleDetailPage.routeName: (context) => ScheduleDetailPage(),
        InvitationEntryPage.routeName: (context) => InvitationEntryPage(),
        PostJoinInstructionsPage.routeName: (context) =>
            PostJoinInstructionsPage(),
      },
      // Here the route for SurveyPage is configured separately in onGenerateRoute(),
      // since we need to pass argument to this route before the page being built,
      // which is not supported by ModalRoute.of().
      onGenerateRoute: (settings) {
        final List args = settings.arguments;
        switch (settings.name) {
          case SurveyPickerPage.routeName:
            return MaterialPageRoute(
                builder: (context) => SurveyPickerPage(experiment: args[0]));
          case SurveyPage.routeName:
            return MaterialPageRoute(
                builder: (context) => SurveyPage(
                    experiment: args[0], experimentGroupName: args[1]));
          case RunningExperimentsPage.routeName:
            return MaterialPageRoute(
                builder: (context) => RunningExperimentsPage(
                    timeout: args == null
                        ? false
                        : args.length > 0
                            ? args[0]
                            : false));
        }
        return null;
      },
    );
  }
}
