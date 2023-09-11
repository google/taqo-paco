import 'dart:io';

import 'package:taqo_cli/platform_service.dart';
import 'package:taqo_cli/taqo_cli.dart' as taqo_cli;
import 'package:taqo_common/service/logging_service.dart';
import 'package:taqo_common/storage/base_database.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 1) {
    displayUsageAndExit(1);
  }

  // await LoggingService.initialize(
  //     logFilePrefix: 'cli-', outputsToStdout: false);
  DatabaseFactory.initialize(() => databaseImpl);
  final taqoCli = taqo_cli.TaqoCli();

  switch (arguments[0]) {
    case 'join':
      if (arguments.length != 2) {
        displayUsageAndExit(1);
      }
      await taqoCli.joinPublicExperimentWithInvitationCode(arguments[1]);
      break;
    case 'join-directly':
      await taqoCli.joinPublicExperiment(
          int.parse(arguments[1]), int.parse(arguments[2]));
      break;
    case 'pause':
      await taqoCli.setExperimentsPausedStatus(arguments.sublist(1), true);
      break;
    case 'resume':
      await taqoCli.setExperimentsPausedStatus(arguments.sublist(1), false);
      break;
    case 'stop':
      await taqoCli.stopExperiments(arguments.sublist(1));
      break;
    case 'list':
      await taqoCli.listJoinedExperiments();
      break;
    case 'help':
    case '--help':
      displayUsageAndExit(0);
      break;
    default:
      displayUsageAndExit(1);
  }
  exit(0);
}

void displayUsageAndExit(int code) {
  final executable = Platform.script.pathSegments.last;
  stderr.write('''Usage:
$executable join <invitation-code>      Join an experiment with invitation code
$executable pause [<experiment-ids>]    Pause specified or all experiments
$executable resume [<experiment-ids>]   Resume specified or all experiments
$executable stop [<experiment-ids>]     Stop specified or all experiments
$executable list                        List all the joined experiments
$executable --help|help                 Print this message
''');
  exit(code);
}
