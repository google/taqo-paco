#!/bin/bash

# Check if flutter is installed, if not, install the flutter
if ! type flutter >/dev/null; then
  cd ../..
  pwd
  git clone https://github.com/flutter/flutter.git -b 2.5.0-6.0.pre
  export PATH="$PATH:/tmpfs/src/github/flutter/bin"
  ls
  echo "$PATH"
  cd taqo-paco/taqo_client || none
fi

flutter clean

# Install debhelper if not already installed
if ! type debhelper >/dev/null; then
    sudo apt-get install -y debhelper
fi

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