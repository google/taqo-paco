#!/bin/bash

# Fail on any error.
set -u -e

red=$(tput setaf 1)
green=$(tput setaf 2)
none=$(tput sgr0)

FLUTTER_VER=""
while (( "$#" )); do
  if [[ "$1" == "--flutter_version" ]]; then
    FLUTTER_VER="$2"
  else
    echo "Error: unknown flag $1."
    print_usage
    exit 1
  fi
  shift 2
done

# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  cd ..
    printf "\n PWD: "
  pwd
  echo ${FLUTTER_VER}
  git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VER}
  export PATH="$PATH:$PWD/flutter/bin"
  ls
  printf "\n Path: "
  echo "$PATH"
  cd taqo_client || none
fi


# Run test cases
run_tests() {
  if [[ -f "pubspec.yaml" ]]; then
#    flutter test --verbose
    flutter test -r expanded
    result=$?
    check=0
    if [ $result -ne $check ]; then
      exit 1
    fi
  else
    printf "\n${red}Error: Not flutter project${none}\n"
    exit 1
  fi
}

run_tests

