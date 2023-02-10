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

#
# Build taqo and taqo_daemon binaries

if [[ -z "${FLUTTER_SDK}" ]]; then
  FLUTTER_SDK="$(flutter --version --machine | jq -r '.flutterRoot')"
fi

if [[ -z "${DART_SDK}" ]]; then
  DART_SDK="${FLUTTER_SDK}/bin/cache/dart-sdk"
fi

if [[ -z "${JAVA_HOME_11}" ]]; then
  if [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
    export JAVA_HOME_11="/usr/lib/jvm/java-11-openjdk-amd64"
  else
    echo "Please set JAVA_HOME_11 to the path of JDK 11"
  fi
fi

if [[ -z "${JAVA_HOME_17}" ]]; then
  if [[ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]]; then
    export JAVA_HOME_17="/usr/lib/jvm/java-17-openjdk-amd64"
  else
    echo "Please set JAVA_HOME_17 to the path of JDK 17"
  fi
fi

if [[ -z "$1" ]]; then
  TAQO_ROOT="$(pwd)"
else
  TAQO_ROOT="$1"
fi
cd -- "${TAQO_ROOT}" || exit
OUT_DIR="${TAQO_ROOT}/taqo_client/build/linux/x64/release/bundle"

# Build flutter app
pushd taqo_client || exit
"${FLUTTER_SDK}"/bin/flutter clean && "${FLUTTER_SDK}"/bin/flutter build linux

# Workaround to remove rpath from shared libs.
# See https://github.com/flutter/flutter/issues/65400
pushd build/linux/x64/release/bundle/lib || exit
for sofile in lib*_plugin.so
do
  chrpath -d "${sofile}"
done
popd || exit

popd || exit

# Build PAL event server / linux daemon
"${DART_SDK}"/bin/dart2native -p pal_event_server/.packages \
  -o "${OUT_DIR}/taqo_server" \
  pal_event_server/lib/main.dart

# Build IntelliJ Plugin
pushd pal_intellij_plugin || exit
dart --no-sound-null-safety builder/bin/builder.dart
cp build/distributions/pal_intellij_plugin-*.zip "$OUT_DIR/"
popd || exit
