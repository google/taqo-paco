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

DISTRIBUTION_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TAQO_ROOT="$(dirname -- "${DISTRIBUTION_DIR}")"

if [[ -z "${FLUTTER_SDK}" ]]; then
  FLUTTER_SDK="$(flutter --version --machine | jq -r '.flutterRoot')"
fi

# TODO - revert to this version of DART_SDK once the Dart PR (https://dart-review.googlesource.com/c/sdk/+/228080/1) is in the SDK
# if [[ -z "${DART_SDK}" ]]; then
#   DART_SDK="${FLUTTER_SDK}/bin/cache/dart-sdk"
# fi

#if [[ -z "${DART_SDK}" ]]; then
    echo "Download the dart-sdk-modified.zip from Drive and put it in distribution/"
    echo "DART_SDK getting set to distribution/dart-sdk-modified in order to properly create a signable taqo_daemon binary"
    DART_SDK="${TAQO_ROOT}/distribution/dart-sdk-modified"
    echo "DART_SDK: ${DART_SDK}"
#fi


PASSWORD=
BUILD="${TAQO_ROOT}/taqo_client/build/macos"
#DEBUG="${BUILD}/Build/Products/Debug"
RELEASE="${BUILD}/Build/Products/Release"

"${TAQO_ROOT}/resolve_deps.sh"

mkdir -p "${RELEASE}"

cd -- "${TAQO_ROOT}" || exit

# Build PAL event server / macos daemon as aot snapshot
# NOTE reduce this to just 'dart compile exe' once Dart supports signable macOS native binaries. (https://dart-review.googlesource.com/c/sdk/+/228080/1)
"${DART_SDK}"/bin/dart compile aot-snapshot -p pal_event_server/.packages \
  -o "${RELEASE}"/taqo_daemon.aot pal_event_server/lib/main.dart

# copy the modified dartaotruntime which knows how to look for the embedded machO section at a particular offset.
cp "${DART_SDK}"/bin/dartaotruntime "${RELEASE}"/dartaotruntime

# make the taqo_daemon binary by inserting the taqo_daemon.aot into a copy of the dartaotruntime at a known offset.
python3 "${TAQO_ROOT}"/distribution/append_section.py "${RELEASE}"/dartaotruntime "${RELEASE}"/taqo_daemon __CUSTOM --custom "${RELEASE}"/taqo_daemon.aot

# cp daemon to Flutter asset
cp "${RELEASE}"/taqo_daemon taqo_client/macos/TaqoLauncher/taqo_daemon

# sign daemon in place. Note: cp commands will invalidate the signature due to macos kernel caching of binary signatures.
# Use mv if you must move it after it is signed.
# TODO  replace the "Paco Developers" cert with your own cert.
codesign --force --timestamp --options runtime --entitlements taqo_client/macos/TaqoLauncher/TaqoLauncher.entitlements -s "Paco Developers" taqo_client/macos/TaqoLauncher/taqo_daemon

# verify the signature
codesign -v --verbose=4 taqo_client/macos/TaqoLauncher/taqo_daemon

# Build IntelliJ Plugin
# note we have previously signed the nested dylibs for the jnr-unixsocket library with the "Paco Developers" cert to comply with signing.
pushd pal_intellij_plugin || exit
dart --no-sound-null-safety builder/bin/builder.dart
cp build/distributions/pal_intellij_plugin-*.zip "../taqo_client/assets/"
popd || exit

# Build flutter app
pushd taqo_client || exit
"${FLUTTER_SDK}"/bin/flutter build macos
popd || exit

echo "Read this file, distribution/create_macos_app.sh for next steps"

# XCode build
#    Menu/Product/Build
#      Note: ensure that all targets, Runner, TaqoLauncher, and alerter have the Team name set to the distribution cert for your developer ID and 'Signing Certificate' set to 'Development'.
#      Note: Hardened Runtime also needs to be enabled on all targets with the entitlements listed in TaqoLauncher.entitlements. This should already be set.
#      Note: if this is a new release candidate, be sure to upgrade the app version for each target under "General/Version"

xcodebuild -scheme Runner -workspace taqo_client/macos/Runner.xcworkspace build


codesign --force --timestamp --options runtime --entitlements taqo_client/macos/TaqoLauncher/TaqoLauncher.entitlements -s "Paco Developers" taqo_client/macos/TaqoLauncher/taqo_daemon


zip -r taqo_client/build/macos/Build/Products/Release/Taqo.app.zip taqo_client/build/macos/Build/Products/Release/Taqo.app

# Xcode Archive
#   Menu/Product/Archive

# XCode Notarization -> Export
#   Organizer/Distribute App, Choose 'Developer ID', Choose 'Upload' (Be sure to be logged in with the proper developer account), Choose 'Automatic Signing', It will generate a zip file for review. If all looks right, Choose 'Upload'
xcrun altool -t osx -f taqo_client/build/macos/Build/Products/Release/Taqo.app.zip \
  --primary-bundle-id com.taqo.survey.taqoClient --notarize-app \
  --username iosapp@pacoapp.com \
  --password $PASSWORD

# Wait for a response from the notarization service. Usually a few minutes.

xcrun altool --notarization-info 395f4889-aca1-4057-8507-34a26a672f3d \
  --username iosapp@pacoapp.com \
  --password $PASSWORD

# staple the notarization to the app

xcrun stapler staple taqo_client/build/macos/Build/Products/Release/Taqo.app

# verify that it worked. It should report something like, "com.taqo.survey.taqoClient accepted\nsource=Notarized Developer"

spctl --assess --verbose taqo_client/build/macos/Build/Products/Release/Taqo.app

# XCode Export
#   Export the Taqo.app bundle to somewhere useful.

# create-dmg
#   run create-dmg on the exported Taqo.app bundle.

# upload to github release
# If this is a new release, create a new release entry on github.com/google/taqo-paco.

