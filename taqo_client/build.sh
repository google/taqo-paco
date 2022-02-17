#!/usr/bin/env bash

red=$(tput setaf 1)
green=$(tput setaf 2)
none=$(tput sgr0)

show_help() {
  printf "usage: $0 [--help] [--report] [--test] [<path to package>]

Script for running all unit and widget tests with code coverage.
(run from root of repo)

where:
    <path to package>
        runs all tests with coverage and reports
    -t, --test
        runs all tests with coverage, but no report
    -r, --report
        generate a coverage report
        (requires lcov, install with Homebrew)
    -h, --help
        print this message
"
}
  cd ../..
  pwd
 git clone https://github.com/flutter/flutter.git -b stable
 export PATH="$PATH:/tmpfs/src/github/flutter/bin"
 ls
 echo $PATH
cd taqo-paco/taqo_client
pwd
run_tests() {
  if [[ -f "pubspec.yaml" ]]; then
    rm -f coverage/lcov.info
    rm -f coverage/lcov-final.info
    flutter test --coverage
  else
    printf "\n${red}Error: this is not a Flutter project${none}"
    exit 1
  fi
}

run_report() {
  if [[ -f "coverage/lcov.info" ]]; then
    lcov -r coverage/lcov.info lib/resources/l10n/\* lib/\*/fake_\*.dart \
      -o coverage/lcov-final.info
    genhtml -o coverage coverage/lcov-final.info
    open coverage/index-sort-l.html
  else
    printf "\n${red}Error: no coverage info was generated${none}"
    exit 1
  fi
}
brew install jq
run_tests
# run_report

# Once the testing is successful, run the build
printf "\n${green} All test cases passed!\n"
printf "\n${none} Now running the build process!\n"
flutter clean  # Clean existing build
cd .. # Come out of the client directory

#chmod +x .distribution/create_macos_app.sh
./distribution/create_macos_app.sh # Run the mac os build script located in the distribution directory

#case $1 in
#-h | --help)
#  show_help
#  ;;
#-t | --test)
#  run_tests
#  ;;
#-r | --report)
#  run_report
#  ;;
#*)
#  run_tests
#  run_report
#  ;;
#esac
