import '../../pal_event_helper.dart';

const command = 'osascript';

const _xpropNameFields = [appNameField, windowNameField, urlNameField];

final _fieldSplitRegExp = RegExp(r'❣');

Map<String, dynamic> buildResultMap(dynamic result) {
  if (result is! String) return null;
  final resultMap = <String, dynamic>{};
  final fields = result.split(_fieldSplitRegExp);
  int i = 0;
  for (var name in _xpropNameFields) {
    if (i >= fields.length) break;
    resultMap[name] = fields[i].trim().replaceAll('"', '');
    i += 1;
  }
  return resultMap;
}

const scriptArgs = [
  "-e", r'global frontApp, frontAppName, windowTitle', //
  "-e", r'set windowTitle to ""',
  "-e", r'tell application "System Events"',
  "-e", r'set frontApp to first application process whose frontmost is true',
  "-e", r'set frontAppName to name of frontApp',
  "-e", r'set firstWindowExists to (front window of frontApp) exists',
  "-e", r'if firstWindowExists is equal to true then',
  "-e", r'set windowTitle to name of (front window of frontApp)',
  "-e", r'if frontAppName is "Google Chrome" then',
  "-e", r'tell application "Google Chrome"',
  "-e", r'set urlText to URL of active tab of front window',
  "-e", r'end tell',
  "-e", r'else if frontAppName is "Safari" then',
  "-e", r'tell application "Safari"',
  "-e", r'set urlText to URL of front document',
  "-e", r'end tell',
  "-e", r'else',
  "-e", r'set urlText to ""',
  "-e", r'end if',
  "-e", r'else',
  "-e", r'set windowTitle to "__"',
  "-e", r'end if',
  "-e", r'end tell',
  "-e", r'--tell process frontAppName',
  "-e", r'--tell (1st window whose value of attribute "AXMain" is true)',
  "-e", r'--set windowTitle to value of attribute "AXTitle"',
  "-e", r'--end tell',
  "-e", r'--end tell',
  "-e", r'--end tell',
  "-e",
  r'set result to frontAppName & "❣" & windowTitle & "❣" & urlText & return',
  "-e", r'return result',
];
