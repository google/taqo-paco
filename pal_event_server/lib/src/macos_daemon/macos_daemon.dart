import 'package:logging/logging.dart';

import '../loggers/loggers.dart';

final _logger = Logger('MacOSDaemon');

void handleScheduleAlarm() async {
  // 'schedule' is called when we join, pause, un-pause, and leave experiments,
  // the experiment schedule is edited, or the time zone changes.
  // Configure app loggers appropriately here
  startOrStopLoggers();
}

void start() async {
  _logger.info('Starting macos daemon');

  // Schedule
  handleScheduleAlarm();
}
