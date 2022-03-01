#!/usr/bin/env bash

red=$(tput setaf 1)
green=$(tput setaf 2)
none=$(tput sgr0)


# Check if correct version of java is installed, if not, install the jdk11
if type -p java; then
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    _java="$JAVA_HOME/bin/java"
else
    brew install java11
    sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
    echo 'export PATH="/usr/local/opt/openjdk@11/bin:$PATH"' >> ~/.zshrc
    export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    printf "Version of java is: ${version}"
    if [[ "$version" > "11" ]]; then
        brew install java11
        sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
        echo 'export PATH="/usr/local/opt/openjdk@11/bin:$PATH"' >> ~/.zshrc
        export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"
    fi
fi

export JAVA_HOME=$(/usr/libexec/java_home -v11)
printf "\n New java version: "
java --version


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



# Check if jq is installed, if not, install the jq
if ! type jq >/dev/null; then
  brew install jq
fi
pwd

printf "\n${none} Now running the build process!\n"
flutter clean # Clean existing build
cd ..         # Come out of the client directory

#chmod +x .distribution/create_macos_app.sh
./distribution/create_macos_app.sh # Run the mac os build script located in the distribution directory
result=$?
if [ $result -ne 0 ]; then
  exit 1
fi
exit 0
