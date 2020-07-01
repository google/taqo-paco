import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/model/interrupt_cue.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';

import '../../triggers/triggers.dart';
import '../loggers.dart';
import '../pal_event_helper.dart';
import 'shell_util.dart' as shell;

final _logger = Logger('CmdLineLogger');

class CmdLineLogger extends PacoEventLogger with EventTriggerSource {
  static const cliLoggerName = 'cli_logger';
  static const cliGroupType = GroupTypeEnum.APPUSAGE_SHELL;
  static const cliStartCue = InterruptCue.APP_USAGE_SHELL;
  static const cliClosedCue = InterruptCue.APP_CLOSED_SHELL;

  static CmdLineLogger _instance;

  CmdLineLogger._() : super(cliLoggerName);

  factory CmdLineLogger() {
    if (_instance == null) {
      _instance = CmdLineLogger._();
    }
    return _instance;
  }

  @override
  void start(List<ExperimentLoggerInfo> toLog, List<ExperimentLoggerInfo> toTrigger) async {
    if (active || (toLog.isEmpty && toTrigger.isEmpty)) {
      return;
    }

    _logger.info('Starting CmdLineLogger');
    await shell.enableCmdLineLogging();
    active = true;
    Timer.periodic(sendInterval, _timerFunc);

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
      _logger.info('Stopping CmdLineLogger');
      await shell.disableCmdLineLogging();
      active = false;
    }
  }

  void _timerFunc(Timer t) async {
    // Log events
    final pacoEvents = await _readLoggedCommands();
    sendToPal(pacoEvents, t);

    // Handle triggers
    final triggerEvents = <TriggerEvent>[];
    for (final e in pacoEvents) {
      triggerEvents.add(createEventTriggers(cliStartCue, e.responses[cmdRawKey]));
    }
    broadcastEventsForTriggers(triggerEvents);

    // Not active and no events means we stopped logging and flushed all prior events
    if (pacoEvents.isEmpty && !active) {
      t.cancel();
    }
  }

  String _escapeRawCmd(String line) {
    // [line]s look like this: {"pid":70372,"cmd_raw":"vim ~/.zshrc","cmd_ret":0}
    const startTok = r'"cmd_raw":"';
    const endTok = r'","cmd_ret"';
    final start = line.indexOf(startTok) + startTok.length;
    final end = line.indexOf(endTok);
    final cmdRaw = line.substring(start, end);
    final charCodes = cmdRaw.codeUnits;
    final sb = StringBuffer();
    for (final c in charCodes) {
      // http://www.asciitable.com/
      if (c < 0x20) {
        sb.write(r'\u' + c.toRadixString(16).padLeft(4, '0'));
      } else if (c == 0x22) {
        sb.write(r'\"');
      } else if (c == 0x5c) {
        sb.write(r'\\');
      } else {
        sb.write(String.fromCharCode(c));
      }
    }

    return line.substring(0, start) + sb.toString() + line.substring(end);
  }

  Future<List<Event>> _readLoggedCommands() async {
    final events = <Event>[];
    try {
      final file = await File('${DartFileStorage.getLocalStorageDir().path}/command.log');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        // TODO race condition here
        await file.delete();
        for (var rawLine in lines) {
          final line = _escapeRawCmd(rawLine);
          try {
            events.addAll(await createLoggerPacoEvents(jsonDecode(line), experimentsBeingLogged,
                createCmdUsagePacoEvent, cliGroupType));
          } catch (e) {
            _logger.warning('Error parsing command line: $rawLine: $e');
          }
        }
        return events;
      }
      _logger.info("No new terminal commands to log");
    } catch (e) {
      _logger.warning("Error loading terminal commands file: $e");
    }
    return events;
  }
}
