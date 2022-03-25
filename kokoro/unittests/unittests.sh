#!/bin/bash
# Copyright 2021 Google LLC
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

# Fail on any error.
set -e

# Code under repo is checked out to ${KOKORO_ARTIFACTS_DIR}/github.
# The final directory name in this path is determined by the scm name specified
# in the job configuration.

cd "${KOKORO_ARTIFACTS_DIR}/github/taqo-paco-kokoro/"

# Read dependencies file to resolve versions
source deps.cfg

printf "\nFlutter version read from config file: %s \n" "${flutter_version}"
# Check if flutter is installed, if yes, remove old local flutter
if [[ -d flutter ]]; then
  rm -rf flutter
fi
# Install the flutter with the specified version if it is not already installed
git clone -b "${flutter_version}" --single-branch https://github.com/flutter/flutter.git
export PATH="$PWD/flutter/bin:$PATH"

# Run test cases
run_flutter_tests() {
  if [[ -f "pubspec.yaml" ]]; then
    flutter test -r expanded
    result=$?
    if [[ $result -ne 0 ]]; then
      exit 1
    fi
  else
    printf "\nError: This directory is not a flutter project.\n";
    exit 1
  fi
}


# Run dart test cases
run_dart_tests() {

  if [[ -f "pubspec.yaml" ]]; then
    dart test
    result=$?

    if [[ $result -ne 0 ]]; then
      exit 1
    fi
  else
    printf "\nError: This directory is not a dart project.\n";
    exit 1
  fi
}

# Run test cases which are in taqo_client directory.
cd taqo_client
run_flutter_tests
cd ..

# Run test cases which are in data_binding_builder directory.
cd data_binding_builder
run_dart_tests
cd ..

# Run test cases which are in pal_event_server directory.
cd pal_event_server
run_dart_tests
cd ..

# Run test cases which are in taqo_common directory.
cd taqo_common
run_dart_tests
cd ..

# Run test cases which are in taqo_event_server_protocol directory.
cd taqo_event_server_protocol
run_dart_tests
cd ..