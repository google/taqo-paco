#!/bin/bash

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
