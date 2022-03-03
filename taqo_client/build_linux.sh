#!/bin/bash

# Read flutter version from command line arguments
FLUTTER_VER=""
while (( "$#" )); do
  if [[ "$1" == "--flutter_version" ]]; then
    FLUTTER_VER="$2"
  else
    echo "Error: unknown flag $1."
    print_usage
    exit 1
  fi
  shift 2
done
printf "\nFlutter Version Passed: $FLUTTER_VER \n"

# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  cd ..
  printf "\n PWD: "
  pwd
  git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VER}
  export PATH="$PATH:$PWD/flutter/bin"
  ls
  printf "\n Path: "
  echo "$PATH"
  cd taqo_client || none
fi

flutter clean

# Install debhelper if not already installed
sudo apt-get install -y debhelper

# Install Jq if not already installed
if ! type jq >/dev/null; then
    sudo apt-get install -y jq
fi

# Install chrpath if not already installed
if ! type chrpath >/dev/null; then
    sudo apt-get install -y chrpath
fi

# Go to root directory.
 cd ..

#  Run the linux build
distribution/create_deb_pkg.sh
result=$?
if [ $result -ne 0 ]; then
    printf "Build failed! Please check the log for the details"
  exit 1
fi
exit 0