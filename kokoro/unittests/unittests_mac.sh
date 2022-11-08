#!/bin/bash
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

# Exit on error for setting up
set -e

REPO_ROOT="${KOKORO_ARTIFACTS_DIR}/github/taqo-paco-kokoro/"
cd "${REPO_ROOT}"

JSON2XML_PY="${REPO_ROOT}/kokoro/unittests/dart_test_json2xml.py"

# Download the correct version of flutter
source deps.cfg
echo "Using Flutter ${flutter_version}."
git clone -b "${flutter_version}" --single-branch https://github.com/flutter/flutter.git
export PATH="$PWD/flutter/bin:$PATH"

# Install lxml
pip install lxml

exit_code=0

# Run Flutter or Dart tests
run_tests() {
  "$1" test -r json | python3 "${JSON2XML_PY}" >sponge_log.xml

  if ((PIPESTATUS[0] != 0)); then
    exit_code=1
  fi
}

# Continue on error when running test
set +e

pushd taqo_client
run_tests flutter
popd

pushd data_binding_builder
run_tests dart
popd

pushd pal_event_server
run_tests dart
popd

pushd taqo_common
run_tests dart
popd

pushd taqo_event_server_protocol
run_tests dart
popd

exit $exit_code
