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

#cd "${KOKORO_ARTIFACTS_DIR}/github/taqo-paco-kokoro/"

source deps.cfg

printf "\nFlutter version read from config file: %s \n" "${flutter_version}"
# Check if flutter is installed, if yes, remove old local flutter
if [[ -d flutter ]]; then
  rm -rf flutter
fi
# Install the flutter with the specified version if it is not already installed
git clone -b "${flutter_version}" --single-branch https://github.com/flutter/flutter.git
export PATH="$PWD/flutter/bin:$PATH"
cd taqo_client

# Run test cases
run_tests() {
  if [[ -f "pubspec.yaml" ]]; then
    flutter test -r expanded
    result=$?
    if [ $result -ne 0 ]; then
      exit 1
    fi
  else
    printf "\nError: This directory is not a flutter project.\n";
    exit 1
  fi
}

run_tests


