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

# Read flutter version from command line arguments
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
printf "\nFlutter Version Passed: $FLUTTER_VER \n"

# Check if correct version of java is installed, if not, install the jdk11
if type -p java; then
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    _java="$JAVA_HOME/bin/java"
else
    brew install java11
    sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
    echo 'export PATH="/usr/local/opt/openjdk@11/bin:$PATH"' >> ~/.zshrc
    export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    printf "Version of java is: ${version}"
    if [[ "$version" > "11" ]]; then
        brew install java11
        sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
        echo 'export PATH="/usr/local/opt/openjdk@11/bin:$PATH"' >> ~/.zshrc
        export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"
    fi
fi

# export JAVA_HOME=$(/usr/libexec/java_home -v11)
printf "\n New java version: "
java --version


# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  cd ../..
  pwd
  git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VER}
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

printf "\n${none} Now running the build process!\n"
flutter clean # Clean existing build
cd ..         # Come out of the client directory
flutter config --enable-macos-desktop
#chmod +x .distribution/create_macos_app.sh
./distribution/create_macos_app.sh # Run the mac os build script located in the distribution directory
result=$?
if [ $result -ne 0 ]; then
  exit 1
fi
exit 0
