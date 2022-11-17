# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Test data for dart_test_json2xml.py"""

sample_file = r'''
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  219M  100  219M    0     0  53.9M      0  0:00:04  0:00:04 --:--:-- 54.0M
╔════════════════════════════════════════════════════════════════════════════╗
║ A new version of Flutter is available!                                     ║
║                                                                            ║
║ To update to the latest version, run "flutter upgrade".                    ║
╚════════════════════════════════════════════════════════════════════════════╝

Downloading Material fonts...                                    1,174ms
Downloading Gradle Wrapper...                                       32ms
Downloading package sky_engine...                                   63ms
Downloading flutter_patched_sdk tools...                           124ms
Downloading flutter_patched_sdk_product tools...                   109ms
Downloading darwin-x64 tools...                                  1,047ms
Downloading libimobiledevice...                                     24ms
Downloading usbmuxd...                                              22ms
Downloading libplist...                                             22ms
Downloading openssl...                                              61ms
Downloading ios-deploy...                                           22ms
Downloading darwin-x64/font-subset tools...                         45ms
{"type":"start","time":0}
{"type":"suite","time":1}
{"type":"fakeEvent","time":2}
'''

expected_stream = [{
    'type': 'start',
    'time': 0
}, {
    'type': 'suite',
    'time': 1
}, {
    'type': 'fakeEvent',
    'time': 2
}]


class EventGenerator:
  _PROTOCOL_VERSION = "0.1.2"
  _PID = 12345

  def __init__(self) -> None:
    self._time = 0
    self._group_suite = {}
    self._parent = {}

  def _is_suite(self, id_) -> bool:
    return self._parent[id_] is None

  def _get_new_time(self) -> int:
    now = self._time
    self._time += 10
    return now

  def _mock_line(self, id_) -> int:
    return id_ + 3

  def _mock_column(self, id_) -> int:
    return (2 * id_ + 1) % 80

  def start(self) -> dict:
    return {
        "protocolVersion": self._PROTOCOL_VERSION,
        "pid": self._PID,
        "type": "start",
        "time": self._get_new_time()
    }

  def suite(self, suite_id) -> dict:
    assert suite_id not in self._parent
    self._parent[suite_id] = None
    return {
        "suite": {
            "id": suite_id,
            "platform": "vm",
            "path": f"path-suite-{suite_id}"
        },
        "type": "suite",
        "time": self._get_new_time()
    }

  def group(self, group_id, parent_id) -> dict:
    assert group_id not in self._parent
    self._parent[group_id] = parent_id
    if self._is_suite(parent_id):
      suite_id = parent_id
      parent_group_id = None
    else:
      suite_id = self._group_suite[parent_id]
      parent_group_id = parent_id
    self._group_suite[group_id] = suite_id

    return {
        "group": {
            "id": group_id,
            "suiteID": suite_id,
            "parentID": parent_group_id,
            "name": f"group-{group_id}",
            "line": self._mock_line(group_id),
            "column": self._mock_column(group_id),
            "url": f"url-{group_id}"
        },
        "type": "group",
        "time": self._get_new_time()
    }

  def test(self, test_id, parent_id) -> dict:
    assert test_id not in self._parent
    self._parent[test_id] = parent_id
    group_ids = []
    if self._is_suite(parent_id):
      suite_id = parent_id
    else:
      suite_id = self._group_suite[parent_id]
      group_id = parent_id
      group_ids.append(group_id)
      while group_id is not None:
        next_id = self._parent[group_id]
        if next_id:
          group_ids.append(group_id)
        group_id = next_id
      group_ids.reverse()
    return {
        "test": {
            "id": test_id,
            "name": f"test-{test_id}",
            "suiteID": suite_id,
            "groupIDs": group_ids,
            "line": self._mock_line(test_id),
            "column": self._mock_column(test_id),
            "url": f"test-url-{test_id}"
        },
        "type": "testStart",
        "time": self._get_new_time()
    }

  def message(self, test_id) -> dict:
    return {
        "testID": test_id,
        "messageType": "someType",
        "message": f"message-of-{test_id}",
        "type": "print",
        "time": self._get_new_time()
    }

  def error(self, test_id, is_failure: bool) -> dict:
    return {
        "testID": test_id,
        "error": f"error-of-{test_id}",
        "stackTrace": "someStackTrace",
        "isFailure": is_failure,
        "type": "error",
        "time": self._get_new_time()
    }

  def test_done(self,
                test_id,
                result="success",
                skipped=False,
                hidden=False) -> dict:
    return {
        "testID": test_id,
        "result": result,
        "skipped": skipped,
        "hidden": hidden,
        "type": "testDone",
        "time": self._get_new_time()
    }

  def done(self, success: bool) -> dict:
    return {"success": success, "type": "done", "time": self._get_new_time()}
