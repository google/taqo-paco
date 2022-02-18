#!/usr/bin/env bash

# Setting colors
red=$(tput setaf 1)
green=$(tput setaf 2)
none=$(tput sgr0)

# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  cd ../..
#   pwd
  git clone https://github.com/flutter/flutter.git -b stable
  export PATH="$PATH:/tmpfs/src/github/flutter/bin"
#   ls
#   echo "$PATH"
#   flutter doctor
  cd taqo-paco/taqo_client || none
fi

# Run test cases
run_tests() {
  if [[ -f "pubspec.yaml" ]]; then
    rm -f coverage/lcov.info
    rm -f coverage/lcov-final.info
    flutter test
    result=$?
    printf "Result of the test: ${result}"
    if (( result != 0 )); then
         printf "\n${red}Error: Some test cases failed${none}\n"
        exit 1
    else
        printf "\n${green} All test cases passed!${none}\n"
    fi
  else
    printf "\n${red}Error: Not flutter project${none}\n"
    exit 1
  fi
}

run_tests


