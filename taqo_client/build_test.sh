#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
none=$(tput sgr0)

# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  cd ../..
  pwd
  git clone https://github.com/flutter/flutter.git -b 2.5.0-6.0.pre
  export PATH="$PATH:/tmpfs/src/github/flutter/bin"
  ls
  echo "$PATH"
  cd taqo-paco/taqo_client || none
fi


# Run test cases
run_tests() {
  if [[ -f "pubspec.yaml" ]]; then
#    flutter test --verbose
    flutter test -r expanded
    result=$?
    if [ $result -ne 0 ]; then
      exit 1
    fi
  else
    printf "\n${red}Error: Not flutter project${none}\n"
    exit 1
  fi
}

run_tests

