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


if [ -z ${FLUTTER_SDK} ]; then
  echo "Must set FLUTTER_SDK"
  exit 1
fi

if [ -z ${DART_SDK} ]; then
  echo "Must set DART_SDK"
  exit 1
fi

BUILD=taqo_client/build/macos
#DEBUG=${BUILD}/Build/Products/Debug
RELEASE=${BUILD}/Build/Products/Release
OUT=${BUILD}/${DEB}

./resolve_deps.sh

# Build PAL event server / macos daemon
${DART_SDK}/bin/dart2native -p pal_event_server/.packages \
  -o ${RELEASE}/taqo_daemon \
  pal_event_server/lib/main.dart

# cp daemon to Flutter asset
cp ${RELEASE}/taqo_daemon taqo_client/macos/TaqoLauncher/taqo_daemon

# zip/cp intellij to Flutter asset
if [ ! -d pal_intellij_plugin/out ]; then
  echo "Must build IntelliJ Plugin first"
  exit 1
fi

mkdir -p /tmp/pal_intellij_plugin/classes
cp -R pal_intellij_plugin/libs/lib /tmp/pal_intellij_plugin/
cp -R pal_intellij_plugin/out/production/pal_intellij_plugin/com /tmp/pal_intellij_plugin/classes/
cp -R pal_intellij_plugin/out/production/pal_intellij_plugin/META-INF /tmp/pal_intellij_plugin/classes/
cp -R pal_intellij_plugin/out/production/pal_intellij_plugin/META-INF /tmp/pal_intellij_plugin/

ZIPFILE=$(pwd)/taqo_client/assets/pal_intellij_plugin.zip
pushd /tmp
zip -r ${ZIPFILE} pal_intellij_plugin/
popd || exit

# Build flutter app
pushd taqo_client || exit
${FLUTTER_SDK}/bin/flutter build macos
popd || exit

# rm assets after build
rm taqo_client/macos/TaqoLauncher/taqo_daemon
rm taqo_client/assets/pal_intellij_plugin.zip
