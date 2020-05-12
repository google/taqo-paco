#!/bin/bash

pushd ../taqo_common
flutter packages run build_runner build --delete-conflicting-outputs
popd
