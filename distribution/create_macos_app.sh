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

if [[ -z "${FLUTTER_SDK}" ]]; then
  FLUTTER_SDK="$(flutter --version --machine | jq -r '.flutterRoot')"
fi

if [[ -z "${DART_SDK}" ]]; then
  DART_SDK="${FLUTTER_SDK}/bin/cache/dart-sdk"
fi

DISTRIBUTION_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TAQO_ROOT="$(dirname -- "${DISTRIBUTION_DIR}")"

BUILD="${TAQO_ROOT}/taqo_client/build/macos"
#DEBUG="${BUILD}/Build/Products/Debug"
RELEASE="${BUILD}/Build/Products/Release"

"${TAQO_ROOT}/resolve_deps.sh"

mkdir -p "${RELEASE}"

cd -- "${TAQO_ROOT}" || exit

# Build PAL event server / macos daemon
"${DART_SDK}"/bin/dart2native -p pal_event_server/.packages \
  -o "${RELEASE}"/taqo_daemon \
  pal_event_server/lib/main.dart

# cp daemon to Flutter asset
cp "${RELEASE}"/taqo_daemon taqo_client/macos/TaqoLauncher/taqo_daemon

# Build IntelliJ Plugin
pushd pal_intellij_plugin || exit
dart --no-sound-null-safety builder/bin/builder.dart
cp build/distributions/pal_intellij_plugin-*.zip "../taqo_client/assets/"
popd || exit

# Build flutter app
pushd taqo_client || exit
"${FLUTTER_SDK}"/bin/flutter build macos
popd || exit

