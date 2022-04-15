#!/bin/bash
# Copyright 2022 Google LLC
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

#Install java with specified version in the deps.cfg file
printf "\nJava version read from deps.cfg file is: %s \n" "${java_version}"
brew install java"${java_version}"
sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-'${java_version}'.jdk
echo "export PATH=/usr/local/opt/openjdk@${java_version}/bin:$PATH" >> ~/.zshrc
export CPPFLAGS="-I/usr/local/opt/openjdk@${java_version}/include"
export JAVA_HOME=$(/usr/libexec/java_home -v"${java_version}")

printf "\nFlutter version read from deps.cfg file is: %s \n" "${flutter_version}"
# Check if flutter is installed, if yes, remove old local flutter
if [[ -d flutter ]]; then
  rm -rf flutter
fi
# Install the flutter with the specified version if it is not already installed
git clone -b "${flutter_version}" --single-branch https://github.com/flutter/flutter.git
export PATH="${PWD}/flutter/bin:${PATH}"

printf "\n New java version is: "
java -version

printf "\n New Flutter version is: "
flutter --version

# Check if jq is installed, if not, install the jq
brew install jq

# Clean any of the previous builds
cd taqo_client

flutter clean # Clean existing build
cd ..
# Enable macos desktop flutter config
flutter config --enable-macos-desktop
#chmod +x .distribution/create_macos_app.sh

# Run the mac os build script located in the distribution directory
./distribution/create_macos_app.sh
result=$?
if [ $result -ne 0 ]; then
  exit 1
fi
xcodebuild -scheme Runner -workspace taqo_client/macos/Runner.xcworkspace build
zip -r taqo_client/build/macos/Build/Products/Release/Taqo.app.zip taqo_client/build/macos/Build/Products/Release/Taqo.app

ls  taqo_client/build/macos/Build/Products/Release/Taqo.app.zip taqo_client/build/macos/Build/Products/Release/
