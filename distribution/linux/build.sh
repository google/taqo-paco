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

FLUTTER_SDK="$(flutter --version --machine | jq -r '.flutterRoot')"
DART_SDK="${FLUTTER_SDK}/bin/cache/dart-sdk"

if [[ -z "$1" ]]; then
  TAQO_ROOT="$(pwd)"
else
  TAQO_ROOT="$1"
fi
cd -- "${TAQO_ROOT}" || exit
OUT_DIR="${TAQO_ROOT}/taqo_client/build/linux/release/bundle"

# Build flutter app
pushd taqo_client || exit
"${FLUTTER_SDK}"/bin/flutter clean && "${FLUTTER_SDK}"/bin/flutter build linux

# Workaround to remove rpath from shared libs.
# See https://github.com/flutter/flutter/issues/65400
pushd build/linux/release/bundle/lib || exit
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

# Copy IntelliJ plugins
mkdir -p /tmp/pal_intellij_plugin/classes
cp -R pal_intellij_plugin/libs/lib /tmp/pal_intellij_plugin/
cp -R pal_intellij_plugin/out/production/pal_intellij_plugin/com /tmp/pal_intellij_plugin/classes/
cp -R pal_intellij_plugin/out/production/pal_intellij_plugin/META-INF /tmp/pal_intellij_plugin/classes/
cp -R pal_intellij_plugin/out/production/pal_intellij_plugin/META-INF /tmp/pal_intellij_plugin/

ZIPFILE=${OUT_DIR}/pal_intellij_plugin.zip
pushd /tmp || exit
zip -r "${ZIPFILE}" pal_intellij_plugin/
popd || exit
