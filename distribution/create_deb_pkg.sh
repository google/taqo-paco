#!/bin/bash

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
cp "${LINUX_DIR}"/{taqo,taqo_daemon}.desktop "${BUILD_DIR}/"

cd "${BUILD_DIR}" || exit
dpkg-buildpackage -B -us -uc
