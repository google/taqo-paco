# Building distributable packages for Taqo

## Build .deb package for Linux (tested on Ubuntu 20.04)

### Requirements

- debhelper (>=13) (debhelper 12 seems working, but not guaranteed)
- rsync
- cmake
- libgtk-3-dev
- unzip
- ninja-build
- clang
- pkg-config
- jq
- chrpath
- libsqlite3-dev
- openjdk-11-jdk 
- openjdk-17-jdk
- (See deps.cfg for the specific version of Flutter)

### Build steps
To create a deb package under `distribution/build`, run the `create_deb_pkg.sh`
script.

## Build .dmg package for macOS

### Requirements

- (See deps.cfg for the specific version of Flutter)  

- Xcode 11.7
  (Xcode 12+ won't work)

- jq

- [create-dmg](https://github.com/sindresorhus/create-dmg)  by sindresorhu

### Build steps

1. Run the `create_macos_app.sh` script
2. Open the macOS project

   ```bash
   open <taqo-paco-root>/taqo_client/macos/Runner.xcworkspace
   ```

3. Follow steps in [Notarizing macOS Software Before Distribution](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

4. Rename the generated app file to `Taqo.app` and create the dmg file

   ```bash
    create-dmg Taqo.app
   ```