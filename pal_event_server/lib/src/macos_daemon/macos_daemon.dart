import 'package:logging/logging.dart';

import '../loggers/loggers.dart';
import '../loggers/app_usage/app_logger.dart';
import '../loggers/cmd_line/cmdline_logger.dart';

final _logger = Logger('MacOSDaemon');

void handleScheduleAlarm() async {
  // 'schedule' is called when we join, pause, un-pause, and leave experiments,
  // the experiment schedule is edited, or the time zone changes.
  // Configure app loggers appropriately here
  final experimentsToLog = await getExperimentsToLog();
  if (experimentsToLog.isNotEmpty) {
    // Found a non-paused experiment
    AppLogger().start(experimentsToLog);
    CmdLineLogger().start(experimentsToLog);
  } else {
    AppLogger().stop(experimentsToLog);
    CmdLineLogger().stop(experimentsToLog);
  }
}

void start() async {
  _logger.info('Starting macos daemon');
}
