import '../../pal_event_helper.dart';

const command = 'xprop';
const getIdArgs = ['-root', '32x', '\t\$0', '_NET_ACTIVE_WINDOW'];

const _xpropNameFields = [appNameField, windowNameField];

final _idSplitRegExp = RegExp(r'\s+');
final _fieldSplitRegExp = RegExp(r'\s+=\s+|\n');
final _appSplitRegExp = RegExp(r',\s*');

const invalidWindowId = -1;

List<String> getAppArgs(int windowId) {
  return ['-id', '$windowId'] + _xpropNameFields;
}

int parseWindowId(dynamic result) {
  if (result is String) {
    final windowId = result.split(_idSplitRegExp);
    if (windowId.length > 1) {
      return int.tryParse(windowId[1]) ?? invalidWindowId;
    }
  }
  return invalidWindowId;
}

Map<String, dynamic> buildResultMap(dynamic result) {
  if (result is! String) return null;
  final resultMap = <String, dynamic>{};
  final fields = result.split(_fieldSplitRegExp);
  int i = 1;
  for (var name in _xpropNameFields) {
    if (i >= fields.length) break;
    if (name == appNameField) {
      final split = fields[i].split(_appSplitRegExp);
      if (split.length > 1) {
        resultMap[name] = split[1].trim().replaceAll('"', '');
      } else {
        resultMap[name] = fields[i].trim().replaceAll('"', '');
      }
    } else {
      resultMap[name] = fields[i].trim().replaceAll('"', '');
    }
    i += 2;
  }
  return resultMap;
}
