#!/usr/bin/env bash

red=$(tput setaf 1)
green=$(tput setaf 2)
none=$(tput sgr0)


# Check if correct version of java is installed, if not, install the jdk11
if type -p java; then
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    _java="$JAVA_HOME/bin/java"
else
    brew install java11
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    printf "Version of java is: ${version}"
    if [[ "$version" > "11" ]]; then
        brew install java11
    fi
fi

export "JAVA_HOME=\$(/usr/local/Cellar/openjdk@11/11.0.12 -v11)"


# /Library/Java/JavaVirtualMachines/jdk-11.0.13.jdk
ls /Library/Java/JavaVirtualMachines/
echo $JAVA_HOME

exit 1

# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  cd ../..
  pwd
  git clone https://github.com/flutter/flutter.git -b stable
  export PATH="$PATH:/tmpfs/src/github/flutter/bin"
  ls
  echo "$PATH"
  cd taqo-paco/taqo_client || none
fi



# Check if jq is installed, if not, install the jq
if ! type jq >/dev/null; then
  brew install jq
fi
pwd

# Run test cases
run_tests() {
  if [[ -f "pubspec.yaml" ]]; then
    rm -f coverage/lcov.info
    rm -f coverage/lcov-final.info
    flutter test --coverage
  else
    printf "\n${red}Error: Not flutter project${none}"
    exit 1
  fi
}

run_tests

# Code coverage export
generate_report() {
  if [[ -f "coverage/lcov.info" ]]; then
    lcov -r coverage/lcov.info lib/resources/l10n/\* lib/\*/fake_\*.dart \
      -o coverage/lcov-final.info
    genhtml -o coverage coverage/lcov-final.info
    open coverage/index-sort-l.html
  else
    printf "\n${red}Error: Failed to generate code coverage${none}"
    exit 1
  fi
}

# generate_report

# Once the testing is successful, run the build
printf "\n${green} All test cases passed!\n"
printf "\n${none} Now running the build process!\n"
flutter clean # Clean existing build
cd ..         # Come out of the client directory

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
