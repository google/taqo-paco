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

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/model/interrupt_cue.dart';

import '../../triggers/triggers.dart';
import '../loggers.dart';
import 'linux/linux_helper.dart' as linux_helper;
import 'macos/macos_helper.dart' as macos_helper;

final _logger = Logger('IntelliJLogger');

class IntelliJLogger extends PacoEventLogger with EventTriggerSource {
  static const intelliJLoggerName = 'app_usage_logger';
  static const intelliJGroupType = GroupTypeEnum.IDE_IDEA_USAGE;
  static const intelliJCue = InterruptCue.IDE_IDEA_USAGE;

  static IntelliJLogger _instance;

  IntelliJLogger._() : super(intelliJLoggerName);

  factory IntelliJLogger() {
    if (_instance == null) {
      _instance = IntelliJLogger._();
    }
    return _instance;
  }

  @override
  void start(List<ExperimentLoggerInfo> toLog,
      List<ExperimentLoggerInfo> toTrigger) async {
    if (active || (toLog.isEmpty && toTrigger.isEmpty)) {
      return;
    }

    _logger.info('Starting IntelliJLogger');
    active = true;

    if (Platform.isLinux) {
      linux_helper.enableIntelliJPlugin();
    } else if (Platform.isMacOS) {
      macos_helper.enableIntelliJPlugin();
    }

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
      _logger.info('Stopping IntelliJLogger');
      active = false;

      if (Platform.isLinux) {
        linux_helper.disableIntelliJPlugin();
      } else if (Platform.isMacOS) {
        macos_helper.disableIntelliJPlugin();
      }
    }
  }
}
