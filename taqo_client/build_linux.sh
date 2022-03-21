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

  cd ..
  printf "\n PWD: "
  pwd

  git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VER}
    export PATH="`pwd`/flutter/bin:$PATH"

  ls
  printf "\n****************** Path: *************************\n"
  echo "$PATH"
  cd taqo_client || none

printf "\n****************************\n Flutter version: \**********************n"
flutter --version
which flutter


# Install debhelper if not already installed
sudo apt-get install -y debhelper
sudo apt update
sudo apt install -y dh-autoreconf=12~ubuntu16.04.1 debhelper=10.2.2ubuntu1~ubuntu16.04.1
# Install Jq if not already installed
if ! type jq >/dev/null; then
    sudo apt-get install -y jq
fi

# Install chrpath if not already installed
if ! type chrpath >/dev/null; then
    sudo apt-get install -y chrpath
fi
sudo apt-get install -y rsync
sudo apt-get install -y cmake
sudo apt-get install -y libgtk-3-dev
sudo apt-get install -y  clang
sudo apt-get install -y  ninja-build
sudo apt-get install -y clang
sudo apt-get install -y pkg-config
# Go to root directory.
 cd ..
# Check if correct version of java is installed, if not, install the jdk11
#if type -p java; then
#    _java=java
#elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
#    _java="$JAVA_HOME/bin/java"
#else
#    sudo apt install -y openjdk-11-jdk
#
#fi
#
#if [[ "$_java" ]]; then
#    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
#    printf "Version of java is: ${version}"
#    if [[ "$version" > "11" ]]; then
#       sudo apt install -y openjdk-11-jdk
#    fi
#fi

sudo apt install -y openjdk-11-jdk
printf "\n\n"
sudo update-alternatives --config java

#/usr/libexec/java_home -V
printf "\n\n"
#/usr/libexec/java_home -v11
printf "\n\n"
printf "Old java version: "
#export JAVA_HOME=$(/usr/libexec/java_home -v11)
printf "\n New java version: "
java -version
which java
#  Run the linux build
flutter config --enable-linux-desktop
distribution/create_deb_pkg.sh
result=$?
if [ $result -ne 0 ]; then
    printf "Build failed! Please check the log for the details"
  exit 1
fi
exit 0