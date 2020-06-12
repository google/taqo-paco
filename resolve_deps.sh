#!/bin/bash

pushd taqo_client
flutter pub get
popd

pushd taqo_common
pub get
popd

pushd taqo_event_server_protocol
pub get
popd

pushd taqo_shared_prefs
pub get
popd

pushd sqlite_ffi
pub get
popd

pushd pal_event_server
pub get
popd

