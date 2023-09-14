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


FLUTTER_SDK="$(flutter --version --machine | jq -r '.flutterRoot')"
DART_SDK="${FLUTTER_SDK}/bin/cache/dart-sdk"

pushd taqo_client || exit
"$FLUTTER_SDK"/bin/flutter pub get
popd || exit

pushd taqo_common || exit
"$DART_SDK"/bin/pub get
popd || exit

pushd taqo_event_server_protocol || exit
"$DART_SDK"/bin/pub get
popd || exit

pushd taqo_shared_prefs || exit
"$DART_SDK"/bin/pub get
popd || exit

pushd pal_event_server || exit
"$DART_SDK"/bin/pub get
popd || exit

pushd pal_intellij_plugin/builder || exit
"$DART_SDK"/bin/pub get
popd || exit

pushd taqo_log_cmd || exit
"$DART_SDK"/bin/pub get
popd || exit

pushd taqo_cli || exit
"$DART_SDK"/bin/pub get
popd || exit
