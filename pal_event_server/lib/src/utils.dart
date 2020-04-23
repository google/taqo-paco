import 'dart:convert';
import 'dart:io';

String get taqoDir {
  final env = Platform.environment;
  String home;
  if (Platform.isLinux) {
    home = env['HOME'];
    return '$home/.taqo';
  } else if (Platform.isMacOS) {
    home = env['HOME'];
    return '$home/Library/Containers/com.taqo.survey.taqoClient/Data/Documents';
  } else {
    throw UnsupportedError('Only supports Linux and MacOS');
  }
}

Future<List> readJoinedExperiments() async {
  try {
    final file = await File('$taqoDir/experiments.txt');
    if (await file.exists()) {
      final contents = await file.readAsString();
      return jsonDecode(contents);
    }
    print("joined experiment file does not exist or is corrupted");
    return <Map<String, dynamic>>[];
  } catch (e) {
    print("Error loading joined experiments file: $e");
    return <Map<String, dynamic>>[];
  }
}
