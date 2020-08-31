#!/bin/bash

pushd taqo_client
$FLUTTER_SDK/bin/flutter pub get
popd

pushd taqo_common
$DART_SDK/bin/pub get
popd

pushd taqo_event_server_protocol
$DART_SDK/bin/pub get
popd

pushd taqo_shared_prefs
$DART_SDK/bin/pub get
popd

pushd sqlite_ffi
$DART_SDK/bin/pub get
popd

pushd pal_event_server
$DART_SDK/bin/pub get
popd

