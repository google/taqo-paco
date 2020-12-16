#!/bin/bash
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

# Build IntelliJ Plugin
pushd pal_intellij_plugin || exit
./gradlew copyPlugin
cp "build/distributions/pal_intellij_plugin.zip" "$OUT_DIR/"
popd || exit
