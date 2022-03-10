#!/bin/bash

# Fail on any error.
set -e

# Display commands being run.
# WARNING: please only enable 'set -x' if necessary for debugging, and be very
#  careful if you handle credentials (e.g. from Keystore) with 'set -x':
#  statements like "export VAR=$(cat /tmp/keystore/credentials)" will result in
#  the credentials being printed in build logs.
#  Additionally, recursive invocation with credentials as command-line
#  parameters, will print the full command, with credentials, in the build logs.
# set -x

# Code under repo is checked out to ${KOKORO_ARTIFACTS_DIR}/github.
# The final directory name in this path is determined by the scm name specified
# in the job configuration.

cd "${KOKORO_ARTIFACTS_DIR}/github/taqo-paco-kokoro/" || none

source read_config.sh
get_value flutter_version
FLUTTER_VER=${value}

printf "\nFlutter Version read from config file: %s \n" "${FLUTTER_VER}"
# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  printf "\n Current directory is: %s \n" "$PWD"
  git clone https://github.com/flutter/flutter.git -b "${FLUTTER_VER}"
  export PATH="$PATH:$PWD/flutter/bin"
fi
cd taqo_client || none
printf "\n Current directory is: %s \n" "$PWD"

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
    printf "\n Current directory is: %s \n" "$PWD"
    exit 1
  fi
}

run_tests



