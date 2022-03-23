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

cd "${KOKORO_ARTIFACTS_DIR}/github/taqo-paco-kokoro/" || none

source read_config.sh
get_value flutter_version
FLUTTER_VER=${value}

printf "\nFlutter version read from config file: %s \n" "${FLUTTER_VER}"
# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  git clone https://github.com/flutter/flutter.git -b "${FLUTTER_VER}"
  export PATH="$PATH:$PWD/flutter/bin"
fi
cd taqo_client || none

# Run test cases
run_tests() {
  if [[ -f "pubspec.yaml" ]]; then
    flutter test -r expanded
    result=$?
    check=0
    if [ $result -ne $check ]; then
      exit 1
    fi
  else
    printf "\nError: This directory is not a flutter project\n";
    exit 1
  fi
}

run_tests



