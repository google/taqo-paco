#!/bin/bash

BASEDIR=$(dirname "$0")
pushd $BASEDIR/../taqo_common
flutter packages run build_runner build --delete-conflicting-outputs
popd
