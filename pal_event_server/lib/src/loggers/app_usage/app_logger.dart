import 'dart:async';
import 'dart:isolate';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/model/interrupt_cue.dart';

import '../../triggers/triggers.dart';
import '../loggers.dart';
import '../pal_event_helper.dart';
import 'linux/linux_helper.dart' as linux_helper;
import 'macos/macos_helper.dart' as macos_helper;

final _logger = Logger('AppLogger');

const queryInterval = const Duration(seconds: 1);

class AppLogger extends PacoEventLogger with EventTriggerSource {
  static const appUsageLoggerName = 'app_usage_logger';
  static const appUsageGroupType = GroupTypeEnum.APPUSAGE_DESKTOP;
  static const appStartCue = InterruptCue.APP_USAGE_DESKTOP;
  static const appClosedCue = InterruptCue.APP_CLOSED_DESKTOP;

  static const Object _isolateDiedObj = Object();
  static AppLogger _instance;

  // Port for the main Isolate to receive msg from AppLogger Isolate
  ReceivePort _receivePort;
  // Background Isolate that will poll for the active window
  Isolate _isolate;

  // List of Events that should be sent to PAL
  final _eventsToSend = <Event>[];

  AppLogger._() : super(appUsageLoggerName);

  factory AppLogger() {
    if (_instance == null) {
      _instance = AppLogger._();
    }
    return _instance;
  }

  @override
  void start(List<ExperimentLoggerInfo> toLog, List<ExperimentLoggerInfo> toTrigger) async {
    if (active || (toLog.isEmpty && toTrigger.isEmpty)) {
      return;
    }

    var isolateFunc;
    if (Platform.isLinux) {
      isolateFunc = linux_helper.linuxAppLoggerIsolate;
    } else if (Platform.isMacOS) {
      isolateFunc = macos_helper.macOSAppLoggerIsolate;
    }

    _logger.info('Starting AppLogger');
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(isolateFunc, _receivePort.sendPort);
    _isolate.addOnExitListener(_receivePort.sendPort, response: _isolateDiedObj);
    _receivePort.listen(_listen);
    active = true;

    // Periodically sync events to PAL Event server
    Timer.periodic(sendInterval, (Timer t) {
      final events = List.of(_eventsToSend);
      _eventsToSend.clear();
      sendToPal(events, t);
    });

    // Create Paco Events
    super.start(toLog, toTrigger);
  }

  @override
  void stop(List<ExperimentLoggerInfo> toLog, List<ExperimentLoggerInfo> toTrigger) async {
    if (!active) {
      return;
    }

    // Create Paco Events
    await super.stop(toLog, toTrigger);

    if (experimentsBeingLogged.isEmpty && experimentsBeingTriggered.isEmpty) {
      // No more experiments -- shut down
      _logger.info('Stopping AppLogger');
      active = false;
      _isolate?.kill();
      _receivePort?.close();
    }
  }

  void _listen(dynamic data) async {
    if (data == _isolateDiedObj) {
      // The background Isolate died
      _isolate?.kill();
      _receivePort?.close();
      if (active) {
        start(experimentsBeingLogged, experimentsBeingTriggered);
      }
      return;
    }

    if (data is Map && data.isNotEmpty) {
      // Log events
      final pacoEvents = await createLoggerPacoEvents(data, experimentsBeingLogged,
          createAppUsagePacoEvent, appUsageGroupType);
      _eventsToSend.addAll(pacoEvents);

      // Handle triggers
      final triggerEvents = <TriggerEvent>[];
      for (final e in pacoEvents) {
        triggerEvents.add(createEventTriggers(appStartCue, e.responses[appsUsedKey]));
      }
      broadcastEventsForTriggers(triggerEvents);
    } else if (data is String && data.isNotEmpty) {
      final triggerEvent = createEventTriggers(appClosedCue, data);
      broadcastEventsForTriggers(<TriggerEvent>[triggerEvent]);
    }
  }
}
