#!/bin/bash

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

pushd sqlite_ffi || exit
"$DART_SDK"/bin/pub get
popd || exit

pushd pal_event_server || exit
"$DART_SDK"/bin/pub get
popd || exit

