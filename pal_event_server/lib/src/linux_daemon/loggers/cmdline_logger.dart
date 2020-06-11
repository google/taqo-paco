import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/interrupt_cue.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';

import '../triggers/triggers.dart';
import 'loggers.dart';
import 'pal_event_helper.dart';
import 'shell_util.dart' as shell;
final _logger = Logger('CmdLineLogger');

class CmdLineLogger extends PacoEventLogger with EventTriggerSource {
  static const cliLoggerName = 'cli_logger';
  static CmdLineLogger _instance;

  CmdLineLogger._() : super(cliLoggerName);

  factory CmdLineLogger() {
    if (_instance == null) {
      _instance = CmdLineLogger._();
    }
    return _instance;
  }

  @override
  void start(List<ExperimentLoggerInfo> experiments) async {
    if (active) {
      return;
    }

    _logger.info('Starting CmdLineLogger');
    await shell.enableCmdLineLogging();
    active = true;
    Timer.periodic(sendInterval, (Timer t) async {
      final pacoEvents = await _readLoggedCommands();
      sendToPal(pacoEvents, t);

      final triggerEvents = <TriggerEvent>[];
      for (final e in pacoEvents) {
        // TODO Use a different InterruptCue?
        triggerEvents.add(createEventTriggers(InterruptCue.APP_USAGE, e.responses[cmdRawKey]));
      }
      broadcastEventsForTriggers(triggerEvents);

      // Not active and no events means we stopped logging and flushed all prior events
      if (pacoEvents.isEmpty && !active) {
        t.cancel();
      }
    });

    // Create Paco Events
    super.start(experiments);
  }

  @override
  void stop(List<ExperimentLoggerInfo> experiments) async {
    if (!active) {
      return;
    }

    // Create Paco Events
    await super.stop(experiments);

    if (experimentsBeingLogged.isEmpty) {
      // No more experiments -- shut down
    _logger.info('Stopping CmdLineLogger');
      await shell.disableCmdLineLogging();
      active = false;
    }
  }

  Future<List<Event>> _readLoggedCommands() async {
    final events = <Event>[];
    try {
      final file = await File('${DartFileStorage.getLocalStorageDir().path}/command.log');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        // TODO race condition here
        await file.delete();
        for (var line in lines) {
          try {
            events.addAll(await createLoggerPacoEvents(jsonDecode(line),
                pacoEventCreator: createCmdUsagePacoEvent));
          } catch (_) {
            // TODO jsonDecode can fail with special characters in line, e.g.
            // Need to escape \ inside strings, i.e. \ -> \\
            // Need to escape " inside strings, i.e. " -> \"
            // Anything less than U+0020
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
