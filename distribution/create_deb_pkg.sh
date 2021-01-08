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


SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
DISTRIBUTION_DIR="$(dirname -- "${SCRIPT_PATH}")"
TAQO_ROOT="$(dirname -- "${DISTRIBUTION_DIR}")"

LINUX_DIR="${DISTRIBUTION_DIR}/linux"
BUILD_DIR="${DISTRIBUTION_DIR}/build/linux"
mkdir -p "${BUILD_DIR}"
rsync -a --delete --exclude=/distribution --exclude=.git --exclude=.idea --exclude=.gitignore "${TAQO_ROOT}/" "${BUILD_DIR}"
rsync -a --delete "${DISTRIBUTION_DIR}/linux/debian" "${BUILD_DIR}"
DATE=$(date -R) envsubst < "${LINUX_DIR}/debian-changelog.tpl" > "${BUILD_DIR}/debian/changelog"
cp "${LINUX_DIR}/build.sh" "${BUILD_DIR}/"
cp "${LINUX_DIR}"/{taqo,taqo_daemon}{,.desktop} "${BUILD_DIR}/"

cd "${BUILD_DIR}" || exit
dpkg-buildpackage -B -us -uc
