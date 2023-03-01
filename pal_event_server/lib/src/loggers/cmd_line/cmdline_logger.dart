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

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/model/interrupt_cue.dart';
import 'package:taqo_common/model/shell_command_log.dart';

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

  final _controller = StreamController<ShellCommandLog>();

  CmdLineLogger._() : super(cliLoggerName) {
    StreamSubscription<ShellCommandLog> subscription;
    subscription = _controller.stream.listen((cmdLog) async {
      subscription.pause();
      await _addLog(cmdLog);
      subscription.resume();
    });
  }

  factory CmdLineLogger() {
    if (_instance == null) {
      _instance = CmdLineLogger._();
    }
    return _instance;
  }

  @override
  void start(List<ExperimentLoggerInfo> toLog,
      List<ExperimentLoggerInfo> toTrigger) async {
    if (active || (toLog.isEmpty && toTrigger.isEmpty)) {
      return;
    }

    _logger.info('Starting CmdLineLogger');
    await shell.enableCmdLineLogging();
    active = true;

    // Create Paco Events
    super.start(toLog, toTrigger);
  }

  @override
  void stop(List<ExperimentLoggerInfo> toLog,
      List<ExperimentLoggerInfo> toTrigger) async {
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

  void addLog(ShellCommandLog cmdLog) {
    if (active) {
      _controller.add(cmdLog);
    }
  }

  Future<void> _addLog(ShellCommandLog cmdLog) async {
    // Log events
    final pacoEvents = await createLoggerPacoEvents(cmdLog.toJson(),
        experimentsBeingLogged, createShellUsagePacoEvent, cliGroupType);
    if (pacoEvents.isNotEmpty) {
      storePacoEvent(pacoEvents);
    }

    // Handle triggers
    final triggerEvents = <TriggerEvent>[];
    for (final e in pacoEvents) {
      triggerEvents
          .add(createEventTriggers(cliStartCue, e.responses['command']));
    }
    broadcastEventsForTriggers(triggerEvents);
  }
}
