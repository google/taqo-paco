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
